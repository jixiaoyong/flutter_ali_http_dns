import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../models/proxy_config.dart';
import '../utils/logger.dart';
import '../utils/port_utils.dart';
import '../utils/protocol_utils.dart';
import '../utils/proxy_auth.dart';
import '../utils/http1_handler.dart';
import '../utils/http2_handler.dart';
import '../services/dns_resolver.dart';

/// 代理服务器安全常量。
abstract final class ProxyLimits {
  /// 请求头最大字节数（含请求行与各头，64 KiB）。
  static const int maxHeaderBytes = 64 * 1024;

  /// 未鉴权请求头读取超时（2 秒）。
  static const Duration headerReadTimeout = Duration(seconds: 2);

  /// HTTP/HTTPS/WebSocket 上游连接建立超时（10 秒）。
  static const Duration upstreamConnectTimeout = Duration(seconds: 10);

  /// 上游响应数据缓冲上限（1 MiB）。
  static const int maxUpstreamBufferBytes = 1024 * 1024;
}

/// 代理安全相关常量（供外部/测试引用）。
abstract final class ProxySecurityConstants {
  static const int maxHeaderBytes = ProxyLimits.maxHeaderBytes;
  static const Duration headerReadTimeout = ProxyLimits.headerReadTimeout;
  static const Duration upstreamConnectTimeout =
      ProxyLimits.upstreamConnectTimeout;
  static const int maxUpstreamBufferBytes = ProxyLimits.maxUpstreamBufferBytes;
}

/// 支持 HTTPDNS 的代理服务器
/// - 兼容 Dio（原域名+原端口）
/// - 支持HTTP/2协议（使用http2库）
/// - 仅绑定 loopback，避免成为无认证开放代理
class ProxyServer {
  ProxyConfig config;
  final List<ServerSocket> _serverSockets = [];
  List<int> _allocatedPorts = []; // 动态分配的端口列表
  bool _isRunning = false;

  // DNS解析器
  final DnsResolver _dnsResolver;

  // 当前实例启动周期的代理鉴权凭据（新增端口时保持不变，不落盘）
  ProxyCredentials _credentials = ProxyCredentials.generate();
  ProxyCredentials get credentials => _credentials;

  // 连接槽按实例隔离：未鉴权连接不能占用已鉴权连接容量。
  static const int _maxPendingAuthClients = 16;
  static const int _maxAuthenticatedClients = 128;
  final Set<_ClientHandler> _pendingAuthClients = {};
  final Set<_ClientHandler> _authenticatedClients = {};

  /// 仅用于状态观测/测试的只读计数。
  int get pendingAuthClientCount => _pendingAuthClients.length;
  int get authenticatedClientCount => _authenticatedClients.length;

  static ProxyServer? _instance;
  static final Map<int, ProxyServer> _instancesByPort = {};

  ProxyServer({required this.config, required DnsResolver dnsResolver})
      : _dnsResolver = dnsResolver;

  /// 启动默认代理服务器（监听单个端口）
  ///
  /// [config] 代理配置
  /// [dnsResolver] DNS解析器实例
  /// 返回启动的代理服务器实例
  static Future<ProxyServer?> start(
    ProxyConfig config,
    DnsResolver dnsResolver,
  ) async {
    Logger.info('Starting default proxy server on single port');

    // 创建代理服务器实例
    final server = ProxyServer(config: config, dnsResolver: dnsResolver);

    // 启动默认代理（监听一个可用端口）
    final success = await server._startDefault();
    if (!success) {
      Logger.error('Failed to start default proxy server');
      return null;
    }

    // 注册单例实例
    _instance = server;

    return server;
  }

  /// 内部启动默认代理方法
  Future<bool> _startDefault() async {
    try {
      Logger.info('Starting default proxy server on single port');

      // 分配一个默认端口
      final port = await _allocateDefaultPort();
      if (port == null) {
        Logger.error('Failed to allocate default port');
        return false;
      }
      _allocatedPorts = [port];

      // 每次成功启动都重新生成高熵随机鉴权凭据，不落盘。
      _credentials = ProxyCredentials.generate();

      // 创建服务器socket并开始监听
      await _createServerSocket(port);

      // 注册到实例映射，使 stopAll()/getInstanceByPort() 可见。
      _instancesByPort[port] = this;

      _isRunning = true;
      Logger.info(
        'Default proxy server started on port $port (with HTTP/2 support)',
      );
      return true;
    } catch (e) {
      Logger.error('Failed to start default proxy server', e);
      return false;
    }
  }

  /// 分配默认端口
  Future<int?> _allocateDefaultPort() async {
    // 优先使用配置中的端口池
    if (config.portPool != null && config.portPool!.isNotEmpty) {
      for (final port in config.portPool!) {
        if (await PortUtils.isPortAvailable(port)) {
          return port;
        }
      }
    }

    // 如果没有可用端口池，使用配置的端口范围
    final startPort = config.startPort ?? 4041;
    final endPort = config.endPort ?? (startPort + 100);

    // 使用工具类查找可用端口
    return await PortUtils.findAvailablePort(
      startPort: startPort,
      endPort: endPort,
      maxAttempts: 100,
    );
  }

  /// 创建服务器套接字
  ///
  /// 只允许绑定 loopback，防止代理被当作无认证开放代理使用。
  Future<ServerSocket> _createServerSocket(int port) async {
    final serverSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      port,
    );

    _serverSockets.add(serverSocket);

    serverSocket.listen(
      (client) {
        if (_pendingAuthClients.length >= _maxPendingAuthClients) {
          Logger.warning(
              'Rejecting client: pending authentication limit reached');
          _rejectClient(client);
          return;
        }
        final handler = _ClientHandler(client, this, port);
        _pendingAuthClients.add(handler);
        handler.handle().catchError((Object error) {
          Logger.error('Client handler error on port $port', error);
          handler.close();
        });
      },
      onError: (error) {
        Logger.error('Proxy server error on port $port', error);
      },
    );

    Logger.info('HTTPDNS Smart Proxy listening on port $port');
    return serverSocket;
  }

  /// 立即拒绝并断开一个连接（用于并发数超限）。
  void _rejectClient(Socket client) {
    try {
      client.add(
        utf8.encode(
          'HTTP/1.1 503 Service Unavailable\r\n'
          'Connection: close\r\n'
          '\r\n',
        ),
      );
    } catch (_) {
      // 忽略写入失败，直接关闭
    }
    try {
      client.close();
    } catch (_) {
      // 忽略关闭失败
    }
  }

  /// 停止代理服务器
  ///
  /// 顺序：先关闭/清理全部活动客户端连接，再释放端口映射，
  /// 最后清空 instances 与端口记录，避免残留 socket 悬挂。
  Future<void> stop() async {
    Logger.info('Stopping proxy server '
        '(${_pendingAuthClients.length} pending, '
        '${_authenticatedClients.length} authenticated)');

    // 1. 先清理全部活动连接
    final clients = <_ClientHandler>{
      ..._pendingAuthClients,
      ..._authenticatedClients,
    };
    for (final handler in clients) {
      handler.close();
    }
    _pendingAuthClients.clear();
    _authenticatedClients.clear();

    // 2. 再关闭监听 socket，释放端口
    await _closeAllServerSockets();

    // 3. 最后清空端口与实例记录
    final ports = List<int>.from(_allocatedPorts);
    _allocatedPorts.clear();
    _isRunning = false;
    for (final port in ports) {
      _instancesByPort.remove(port);
    }
    if (identical(_instance, this)) {
      _instance = null;
    }

    Logger.info('Proxy server stopped');
  }

  /// 关闭所有服务器套接字
  Future<void> _closeAllServerSockets() async {
    for (final socket in _serverSockets) {
      try {
        await socket.close();
      } catch (e) {
        Logger.error('Error closing server socket', e);
      }
    }
    _serverSockets.clear();
  }

  /// 获取代理地址
  String? getAddress() {
    if (!_isRunning || _allocatedPorts.isEmpty) {
      return null;
    }
    // 返回第一个端口的地址作为主要地址
    return '${config.host}:${_allocatedPorts.first}';
  }

  /// 获取HTTP/2代理地址（现在与主代理地址相同）
  String? getHttp2Address() {
    if (!_isRunning) {
      return null;
    }
    return getAddress();
  }

  /// 获取所有代理地址
  List<String> getAllAddresses() {
    if (!_isRunning) {
      return [];
    }
    return _allocatedPorts.map((port) => '${config.host}:$port').toList();
  }

  /// 检查服务器是否正在运行
  bool get isRunning => _isRunning;

  /// 清理资源
  Future<void> dispose() async {
    await stop();
  }

  /// 获取当前实例
  static ProxyServer? get instance => _instance;

  /// 获取指定端口的实例
  static ProxyServer? getInstanceByPort(int port) {
    return _instancesByPort[port];
  }

  /// 停止所有实例
  static Future<void> stopAll() async {
    // stop 会删除端口映射；快照去重后再遍历，避免并发修改及重复停止。
    for (final server in _instancesByPort.values.toSet()) {
      await server.stop();
    }
    _instancesByPort.clear();
    _instance = null;
  }

  /// 获取所有运行的端口
  static List<int> getRunningPorts() {
    return _instancesByPort.keys.toList();
  }

  /// 第一个监听 socket 的绑定地址。
  ///
  /// 安全约束要求仅绑定 loopbackIPv4，供测试与宿主 App 校验。
  InternetAddress? get bindAddress {
    if (_serverSockets.isEmpty) {
      return null;
    }
    try {
      return _serverSockets.first.address;
    } catch (_) {
      return null;
    }
  }

  /// 获取当前分配的端口列表
  List<int> get allocatedPorts => List.unmodifiable(_allocatedPorts);

  /// 注册端口监听（动态添加端口）
  ///
  /// [port] 要监听的端口
  /// 返回注册是否成功
  Future<bool> registerPort(int port) async {
    try {
      Logger.info('Registering port $port for listening');

      // 验证端口号是否有效
      if (!PortUtils.isValidPort(port)) {
        Logger.error('Port $port is not valid (must be between 1 and 65535)');
        return false;
      }

      // 检查端口是否已经在监听
      if (_allocatedPorts.contains(port)) {
        Logger.warning('Port $port is already being listened on');
        return true;
      }

      // 检查端口是否可用
      if (!await PortUtils.isPortAvailable(port)) {
        Logger.error('Port $port is not available');
        return false;
      }

      // 创建服务器socket并开始监听
      await _createServerSocket(port);
      _allocatedPorts.add(port);

      // 注册到实例映射
      _instancesByPort[port] = this;

      Logger.info('Successfully registered port $port for listening');
      return true;
    } catch (e) {
      Logger.error('Failed to register port $port', e);
      return false;
    }
  }

  /// 取消注册端口监听（动态移除端口）
  ///
  /// [port] 要取消监听的端口
  /// 返回取消注册是否成功
  Future<bool> deregisterPort(int port) async {
    try {
      Logger.info('Deregistering port $port from listening');

      // 验证端口号是否有效
      if (!PortUtils.isValidPort(port)) {
        Logger.error('Port $port is not valid (must be between 1 and 65535)');
        return false;
      }

      // 检查端口是否在监听列表中
      if (!_allocatedPorts.contains(port)) {
        Logger.warning('Port $port is not being listened on');
        return true;
      }

      // 找到对应的服务器socket并关闭
      final socketToRemove = _serverSockets.where((socket) {
        try {
          return socket.port == port;
        } catch (e) {
          return false;
        }
      }).toList();

      for (final socket in socketToRemove) {
        try {
          await socket.close();
          _serverSockets.remove(socket);
        } catch (e) {
          Logger.error('Error closing socket for port $port', e);
        }
      }

      // 从端口列表中移除
      _allocatedPorts.remove(port);

      // 从实例映射中移除
      _instancesByPort.remove(port);

      // 等待端口完全释放
      await PortUtils.waitForPortRelease(port);

      Logger.info('Successfully deregistered port $port from listening');
      return true;
    } catch (e) {
      Logger.error('Failed to deregister port $port', e);
      return false;
    }
  }

  /// 获取当前监听的端口列表
  ///
  /// 返回当前正在监听的端口列表
  List<int> getListeningPorts() {
    return List.from(_allocatedPorts);
  }

  /// 检查端口是否正在被监听
  ///
  /// [port] 要检查的端口
  /// 返回端口是否正在被监听
  bool isPortListening(int port) {
    // 验证端口号是否有效
    if (!PortUtils.isValidPort(port)) {
      Logger.warning('Port $port is not valid (must be between 1 and 65535)');
      return false;
    }
    return _allocatedPorts.contains(port);
  }
}

/// 首个请求的 framing 状态；只保留最多 8 KiB chunk 元数据，不缓存 body。
class _RequestBodyFraming {
  int remaining;
  final bool chunked;
  String _line = '';
  String _state;
  int _metadataBytes = 0;
  bool done;

  _RequestBodyFraming(this.remaining, this.chunked)
      : _state = chunked ? 'size' : 'data',
        done = !chunked && remaining == 0;

  factory _RequestBodyFraming.fromHeaders(String request) {
    final lengths = <String>[];
    final encodings = <String>[];
    for (final line in request.split('\r\n').skip(1)) {
      if (line.isEmpty) continue;
      final colon = line.indexOf(':');
      if (colon <= 0 ||
          line.startsWith(' ') ||
          line.startsWith('\t') ||
          line.substring(0, colon).trim() != line.substring(0, colon)) {
        throw const FormatException('Invalid header');
      }
      final name = line.substring(0, colon).toLowerCase();
      if (name == 'content-length') {
        lengths.add(line.substring(colon + 1).trim());
      }
      if (name == 'transfer-encoding') {
        encodings.add(line.substring(colon + 1).trim().toLowerCase());
      }
    }
    // 拒绝重复、逗号列表、TE+CL 和不支持的编码，避免请求走私。
    if (lengths.length > 1 ||
        encodings.length > 1 ||
        (lengths.isNotEmpty && encodings.isNotEmpty) ||
        (encodings.isNotEmpty && encodings.single != 'chunked')) {
      throw const FormatException('Ambiguous framing');
    }
    if (encodings.isNotEmpty) return _RequestBodyFraming(0, true);
    final value = lengths.isEmpty ? '0' : lengths.single;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      throw const FormatException('Invalid length');
    }
    final length = int.tryParse(value);
    if (length == null) throw const FormatException('Invalid length');
    return _RequestBodyFraming(length, false);
  }

  int consume(List<int> data) {
    var offset = 0;
    while (offset < data.length && !done) {
      if (_state == 'data') {
        final count =
            remaining < data.length - offset ? remaining : data.length - offset;
        offset += count;
        remaining -= count;
        if (remaining == 0) {
          if (!chunked) {
            done = true;
          } else {
            _state = 'dataEnd';
          }
        }
        continue;
      }
      final byte = data[offset++];
      if (byte > 127 || ++_metadataBytes > 8192) {
        throw const FormatException('Chunk metadata too large');
      }
      _line += String.fromCharCode(byte);
      if (!_line.endsWith('\r\n')) continue;
      final line = _line.substring(0, _line.length - 2);
      _line = '';
      if (_state == 'dataEnd') {
        if (line.isNotEmpty) {
          throw const FormatException('Invalid chunk terminator');
        }
        _state = 'size';
        _metadataBytes = 0;
      } else if (_state == 'size') {
        if (!RegExp(r'^[0-9a-fA-F]+(?:;[\x20-\x7e]*)?$').hasMatch(line)) {
          throw const FormatException('Invalid chunk size');
        }
        final size = int.tryParse(line.split(';').first, radix: 16);
        if (size == null || size < 0) {
          throw const FormatException('Invalid chunk size');
        }
        remaining = size;
        _state = size == 0 ? 'trailer' : 'data';
        _metadataBytes = 0;
      } else {
        if (line.isEmpty) {
          done = true;
        } else {
          final colon = line.indexOf(':');
          if (colon <= 0 ||
              line.startsWith(' ') ||
              line.startsWith('\t') ||
              [
                'content-length',
                'transfer-encoding',
                'host',
                'connection',
                'proxy-authorization'
              ].contains(line.substring(0, colon).toLowerCase())) {
            throw const FormatException('Invalid trailer');
          }
        }
      }
    }
    return offset;
  }
}

/// 客户端连接处理器
class _ClientHandler {
  final Socket client;
  final ProxyServer proxyServer;
  final int serverPort; // 添加服务器端口信息
  Socket? server;
  List<int> buffer = []; // 改为List<int>来处理二进制数据
  bool _isHttps = false; // 标记是否为HTTPS连接
  bool _isHttp2 = false; // 标记是否为HTTP/2连接
  bool _isWebSocket = false; // 标记是否为WebSocket连接
  bool _isAuthenticated = false; // 标记是否已通过代理鉴权
  bool _isClosed = false; // 标记连接是否已关闭
  StreamSubscription? clientSubscription;
  StreamSubscription? serverSubscription;
  Timer? _headerTimeout;
  int _clientSentBytes = 0;
  _RequestBodyFraming? _httpBody;
  Timer? _bodyTimeout;

  _ClientHandler(this.client, this.proxyServer, this.serverPort);

  Future<void> handle() async {
    // 未鉴权请求头读取超时（2 秒），防止静默连接耗尽 pending 槽。
    _startHeaderTimeout();

    // 直接使用client.listen，避免asBroadcastStream的问题
    clientSubscription = client.listen(
      (data) async {
        // listen 不会等待 async 回调；显式暂停以串行建连和限制待写积压。
        clientSubscription?.pause();
        try {
          if (server == null) {
            buffer.addAll(data);
            final headerEnd = _findHttpRequestEnd();
            // 只统计头部边界，不能把同一 socket 事件中的 body 算入请求头。
            _clientSentBytes = headerEnd < 0 ? buffer.length : headerEnd;
            if (_clientSentBytes > ProxyLimits.maxHeaderBytes) {
              _headerTimeout?.cancel();
              _headerTimeout = null;
              _sendAndClose(
                'HTTP/1.1 431 Request Header Fields Too Large\r\n'
                'Connection: close\r\n'
                'Content-Length: 0\r\n'
                '\r\n',
              );
              return;
            }

            // 尝试解析请求头
            final requestString = _tryDecodeBuffer();
            if (requestString != null) {
              // 请求头已完整接收，取消读取超时。
              _headerTimeout?.cancel();
              _headerTimeout = null;

              // 智能协议检测 - 按优先级顺序检测
              final protocolType = ProtocolUtils.detectProtocol(requestString);

              // 记录协议检测结果
              Logger.info('=== Protocol Detection ===');
              Logger.info(
                'Request preview: ${requestString.split('\n').first}',
              );
              Logger.info('Detected protocol: $protocolType');
              Logger.info(
                'Client connection: ${client.remoteAddress}:${client.remotePort}',
              );
              Logger.info('Server port: $serverPort');
              Logger.info('=== End Protocol Detection ===');

              switch (protocolType) {
                case ProtocolType.http2:
                case ProtocolType.grpc: // gRPC也使用HTTP/2处理
                  if (!_isHttp2) {
                    // HTTP/2 前置数据不包含常规 Proxy-Authorization 头，
                    // 无法按 HTTP/1 方式校验。为保证「鉴权后转发」，
                    // 要求客户端先以 HTTP/1 请求通过鉴权（_isAuthenticated）。
                    if (!_isAuthenticated) {
                      _rejectUnauthorized();
                      return;
                    }
                    // 避免重复处理
                    _isHttp2 = true;
                    await clientSubscription?.cancel();
                    // 传递client作为数据源
                    await _handleHttp2InternalForward(
                      requestString,
                      [],
                      client,
                    );
                    return;
                  }
                  break;

                case ProtocolType.websocket:
                  if (!_isWebSocket) {
                    if (!_authorizeRequest(requestString)) {
                      _rejectUnauthorized();
                      return;
                    }
                    // 避免重复处理
                    _isWebSocket = true;
                    final serverSocket =
                        await Http1Handler.handleWebSocketRequest(
                      client,
                      requestString,
                      proxyServer._dnsResolver,
                      proxyServer,
                    );
                    if (serverSocket == null) {
                      throw Exception('Failed to handle WebSocket request');
                    }

                    // 设置服务器连接，并转发解析请求头期间缓存的剩余数据。
                    server = serverSocket;
                    _flushPendingClientData();

                    // 设置服务器端数据监听（用于WebSocket双向转发）
                    if (server != null) {
                      serverSubscription = server!.listen(
                        (data) {
                          try {
                            serverSubscription?.pause();
                            Logger.debug(
                              'Server -> Client (WebSocket): ${data.length} bytes',
                            );
                            client.add(data);
                            _drainClient();
                            _logDataForwarding(
                              'Server -> Client',
                              data.length,
                              data.length,
                            );
                          } catch (e) {
                            Logger.error(
                              'Client socket error during server->client forwarding',
                              e,
                            );
                            close();
                          }
                        },
                        onError: (error) {
                          Logger.error('Server socket error', error);
                          close();
                        },
                        onDone: () {
                          Logger.debug('Server connection closed');
                          _finishResponse();
                        },
                      );
                    }
                    return;
                  }
                  break;

                case ProtocolType.https:
                  if (!_isHttps) {
                    if (!_authorizeRequest(requestString)) {
                      _rejectUnauthorized();
                      return;
                    }
                    // 避免重复处理
                    _isHttps = true;
                    final connectMatch = RegExp(
                      r'CONNECT ([^ :]+):(\d+)',
                    ).firstMatch(requestString);
                    if (connectMatch != null) {
                      final serverSocket =
                          await Http1Handler.handleConnectRequest(
                        client,
                        connectMatch,
                        proxyServer._dnsResolver,
                        proxyServer,
                      );
                      if (serverSocket == null) {
                        throw Exception(
                            'Failed to handle HTTPS CONNECT request');
                      }

                      // 设置服务器连接，并转发 CONNECT 建连期间缓存的数据。
                      server = serverSocket;
                      _flushPendingClientData();

                      // 设置服务器端数据监听（用于HTTPS双向转发）
                      if (server != null) {
                        serverSubscription = server!.listen(
                          (data) {
                            try {
                              serverSubscription?.pause();
                              Logger.debug(
                                'Server -> Client (HTTPS): ${data.length} bytes',
                              );
                              client.add(data);
                              _drainClient();
                              _logDataForwarding(
                                'Server -> Client',
                                data.length,
                                data.length,
                              );
                            } catch (e) {
                              Logger.error(
                                'Client socket error during server->client forwarding',
                                e,
                              );
                              close();
                            }
                          },
                          onError: (error) {
                            Logger.error('Server socket error', error);
                            close();
                          },
                          onDone: () {
                            Logger.debug('Server connection closed');
                            _finishResponse();
                          },
                        );
                      }
                      return;
                    }
                  }
                  break;

                case ProtocolType.http:
                  if (!_isHttps && !_isHttp2 && !_isWebSocket) {
                    if (!_authorizeRequest(requestString)) {
                      _rejectUnauthorized();
                      return;
                    }
                    try {
                      _httpBody =
                          _RequestBodyFraming.fromHeaders(requestString);
                    } on FormatException {
                      _sendAndClose('HTTP/1.1 400 Bad Request\r\n'
                          'Connection: close\r\nContent-Length: 0\r\n\r\n');
                      return;
                    }
                    await _forwardHttpRequest(requestString);
                    if (!_isClosed) {
                      final initial = buffer;
                      buffer = [];
                      await _forwardBody(initial);
                    }
                    return;
                  }
                  break;

                case ProtocolType.unknown:
                  // 只有在没有其他协议标记时才报告未知协议
                  if (!_isHttps && !_isHttp2 && !_isWebSocket) {
                    if (!_isAuthenticated &&
                        !_looksLikeAuthRequest(requestString)) {
                      _rejectUnauthorized();
                      return;
                    }
                    Logger.warning(
                      'Unrecognized protocol: ${requestString.split('\n').first}',
                    );
                    close();
                    return;
                  }
                  break;
              }
            }
          } else if (_httpBody != null) {
            await _forwardBody(data);
          } else {
            // 数据转发
            try {
              if (_isHttp2) {
                // HTTP/2数据：直接转发，不修改
                Logger.debug('Client -> Server (HTTP/2): ${data.length} bytes');
                server?.add(data);

                // 添加数据转发监控
                _logDataForwarding(
                    'Client -> Server', data.length, data.length);
              } else {
                // 其他协议直接转发
                Logger.debug('Client -> Server (other): ${data.length} bytes');
                server?.add(data);

                // 添加数据转发监控
                _logDataForwarding(
                    'Client -> Server', data.length, data.length);
              }
            } catch (e) {
              Logger.error('Server socket error', e);
              close();
            }
          }
        } catch (e) {
          Logger.error('Client request handling error', e);
          close();
        } finally {
          if (!_isClosed) {
            try {
              await server?.flush();
              clientSubscription?.resume();
            } catch (_) {
              close();
            }
          }
        }
      },
      onError: (error) {
        Logger.error('Client socket error', error);
        close();
      },
      onDone: close,
    );
  }

  /// 普通 HTTP 在校验 framing 后立即转发请求头，body 按事件有界转发。
  Future<void> _forwardHttpRequest(String requestString) async {
    final httpMatch =
        RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').firstMatch(requestString);
    if (httpMatch == null) {
      close();
      return;
    }
    final serverSocket = await Http1Handler.handleHttpRequest(
      client,
      httpMatch,
      requestString,
      proxyServer._dnsResolver,
      proxyServer,
    );
    if (serverSocket == null) {
      close();
      return;
    }
    server = serverSocket;
    serverSubscription = server!.listen(
      (data) {
        serverSubscription?.pause();
        client.add(data);
        _drainClient();
      },
      onError: (_) => close(),
      onDone: _finishResponse,
    );
  }

  Future<void> _forwardBody(List<int> data) async {
    try {
      final count = _httpBody!.consume(data);
      if (count > 0) server!.add(data.sublist(0, count));
      await server!.flush();
      _bodyTimeout?.cancel();
      if (_httpBody!.done) {
        // 只允许一个请求，精确截断同包和随后到达的流水线字节。
        await clientSubscription?.cancel();
      } else {
        _bodyTimeout = Timer(const Duration(seconds: 10), () {
          _sendAndClose('HTTP/1.1 408 Request Timeout\r\n'
              'Connection: close\r\nContent-Length: 0\r\n\r\n');
        });
      }
    } on FormatException {
      _sendAndClose('HTTP/1.1 400 Bad Request\r\n'
          'Connection: close\r\nContent-Length: 0\r\n\r\n');
    }
  }

  /// 将目标连接建立前累计的数据按原顺序转发，避免遗漏与请求头同包到达的 body。
  void _flushPendingClientData() {
    if (server == null || buffer.isEmpty) {
      return;
    }
    final pendingData = List<int>.from(buffer);
    buffer.clear();
    server!.add(pendingData);
    _logDataForwarding(
      'Client -> Server (pending)',
      pendingData.length,
      pendingData.length,
    );
  }

  /// 校验请求头中携带的 Proxy-Authorization 是否为当前凭据的 Basic Auth。
  ///
  /// 校验通过后将 _isAuthenticated 置为 true，使同一连接后续请求
  /// （如 HTTP/2 升级或 CONNECT 隧道）无需重复认证。
  bool _authorizeRequest(String requestString) {
    final credentials = proxyServer.credentials;

    final authValue = _extractHeaderValue(requestString, 'Proxy-Authorization');
    if (credentials.validate(authValue)) {
      if (_isAuthenticated) return true;
      if (proxyServer._authenticatedClients.length >=
          ProxyServer._maxAuthenticatedClients) {
        _sendAndClose(
          'HTTP/1.1 503 Service Unavailable\r\n'
          'Connection: close\r\n'
          'Content-Length: 0\r\n\r\n',
        );
        return false;
      }
      if (!proxyServer._pendingAuthClients.remove(this)) return false;
      proxyServer._authenticatedClients.add(this);
      _isAuthenticated = true;
      return true;
    }
    return false;
  }

  /// 从未知协议判断是否为合法的认证请求（普通 HTTP/WebSocket/CONNECT 首行）。
  bool _looksLikeAuthRequest(String requestString) {
    final firstLine = requestString.split('\n').first.trim();
    return RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').hasMatch(firstLine) ||
        firstLine.startsWith('CONNECT ');
  }

  /// 未认证请求返回 407，并携带 Proxy-Authenticate 挑战头，随后断开。
  void _rejectUnauthorized() {
    _headerTimeout?.cancel();
    _headerTimeout = null;
    final realm = proxyServer.credentials.authenticateHeaderValue();
    _sendAndClose(
      'HTTP/1.1 407 Proxy Authentication Required\r\n'
      '${ProxyCredentials.authenticateHeaderName}: $realm\r\n'
      'Connection: close\r\n'
      'Content-Length: 0\r\n'
      '\r\n',
    );
  }

  /// 写入响应并立即关闭连接。
  void _sendAndClose(String response) {
    if (_isClosed) return;
    _headerTimeout?.cancel();
    _bodyTimeout?.cancel();
    clientSubscription?.pause();
    serverSubscription?.pause();
    try {
      client.add(utf8.encode(response));
      _finishResponse();
    } catch (e) {
      Logger.error('Failed to send response to client', e);
      close();
    }
  }

  /// 从请求字符串中提取指定头（大小写不敏感）的值。
  String? _extractHeaderValue(String requestString, String headerName) {
    final lines = requestString.split('\r\n');
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex <= 0) {
        continue;
      }
      final name = line.substring(0, colonIndex).trim().toLowerCase();
      if (name == headerName.toLowerCase()) {
        return line.substring(colonIndex + 1).trim();
      }
    }
    return null;
  }

  /// 启动请求头读取超时定时器，超时返回 408 并关闭连接。
  void _startHeaderTimeout() {
    _headerTimeout?.cancel();
    _headerTimeout = Timer(ProxyLimits.headerReadTimeout, () {
      if (_isClosed || server != null) {
        return;
      }
      Logger.warning('Header read timeout on client connection');
      _sendAndClose(
        'HTTP/1.1 408 Request Timeout\r\n'
        'Connection: close\r\n'
        'Content-Length: 0\r\n'
        '\r\n',
      );
    });
  }

  /// 尝试安全地解码缓冲区数据
  String? _tryDecodeBuffer() {
    try {
      // 查找HTTP请求的结束位置（\r\n\r\n）
      final endIndex = _findHttpRequestEnd();
      if (endIndex == -1) {
        return null; // 数据不完整，等待更多数据
      }

      // 只解码HTTP头部部分
      final headerBytes = buffer.sublist(0, endIndex);
      final headerString = utf8.decode(headerBytes, allowMalformed: true);

      // 移除已处理的头部数据
      buffer.removeRange(0, endIndex);

      return headerString;
    } catch (e) {
      Logger.error('Failed to decode buffer', e);
      return null;
    }
  }

  /// 查找HTTP请求的结束位置
  int _findHttpRequestEnd() {
    for (int i = 0; i < buffer.length - 3; i++) {
      if (buffer[i] == 13 &&
          buffer[i + 1] == 10 &&
          buffer[i + 2] == 13 &&
          buffer[i + 3] == 10) {
        return i + 4; // 返回\r\n\r\n后的位置
      }
    }
    return -1; // 未找到结束位置
  }

  /// 处理HTTP/2请求 - 使用Http2Handler工具类
  Future<void> _handleHttp2InternalForward(
    String requestString,
    List<int> initialData,
    Socket clientSocket,
  ) async {
    Logger.debug('HTTP/2 internal forward: ${requestString.split('\n').first}');

    // 记录HTTP/2请求开始时的详细信息
    _logHttp2RequestStart(requestString);

    const maxRetries = 2;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        // 使用Http2Handler处理HTTP/2连接，添加超时
        final success = await Http2Handler.handleHttp2Connection(
          clientSocket,
          serverPort,
          proxyServer._dnsResolver,
          initialData: initialData,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException(
              'HTTP/2 connection timeout after 30 seconds',
            );
          },
        );

        if (!success) {
          throw Exception('Failed to handle HTTP/2 connection');
        }

        Logger.debug('HTTP/2 connection handled successfully');

        // 验证连接是否真正建立
        await _verifyHttp2Connection();

        // 启动连接保持机制
        _startConnectionKeepAlive();

        return; // 成功，退出重试循环
      } catch (e) {
        retryCount++;
        Logger.error('HTTP/2 connection attempt $retryCount failed', e);

        // 检查是否应该重试
        if (retryCount <= maxRetries && _shouldRetryHttp2Error(e)) {
          Logger.info(
            'Retrying HTTP/2 connection (attempt $retryCount/$maxRetries)',
          );
          await Future.delayed(Duration(seconds: retryCount)); // 递增延迟
          continue;
        }

        // 不再重试，处理最终错误
        await _handleHttp2Error(e);
        return;
      }
    }
  }

  /// 记录HTTP/2请求开始时的详细信息
  void _logHttp2RequestStart(String requestString) {
    try {
      Logger.info('=== HTTP/2 Request Start ===');
      Logger.info(
        'Request string: ${requestString.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}',
      );

      // 解析请求头信息
      final lines = requestString.split('\r\n');
      Logger.info('Request headers:');
      for (final line in lines) {
        if (line.isNotEmpty) {
          Logger.info('  $line');
        }
      }

      // 客户端连接信息
      Logger.info('Client connection:');
      Logger.info('  - Local address: ${client.address}');
      Logger.info('  - Local port: ${client.port}');
      Logger.info('  - Remote address: ${client.remoteAddress}');
      Logger.info('  - Remote port: ${client.remotePort}');

      // 代理服务器信息
      Logger.info('Proxy server info:');
      Logger.info('  - Server port: $serverPort');
      Logger.info('  - Allocated ports: ${proxyServer._allocatedPorts}');
      Logger.info('  - Is running: ${proxyServer._isRunning}');

      Logger.info('=== End HTTP/2 Request Start ===');
    } catch (e) {
      Logger.error('Failed to log HTTP/2 request start details: $e');
    }
  }

  /// 验证HTTP/2连接是否真正建立
  Future<void> _verifyHttp2Connection() async {
    try {
      Logger.info('=== HTTP/2 Connection Verification ===');

      // 检查客户端连接状态
      Logger.info('Client connection status:');
      Logger.info('  - Remote address: ${client.remoteAddress}');
      Logger.info('  - Remote port: ${client.remotePort}');

      // 对于HTTP/2连接，我们不需要验证server变量
      // 因为HTTP/2连接是通过Http2Handler处理的，不依赖server变量
      if (_isHttp2) {
        Logger.info(
          'HTTP/2 connection verification: PASSED - HTTP/2 connection established via Http2Handler',
        );
        Logger.info('  - HTTP/2 connection is managed by Http2Handler');
        Logger.info('  - No direct server socket verification needed');
      } else if (server != null) {
        Logger.info('Server connection status:');
        Logger.info('  - Remote address: ${server!.remoteAddress}');
        Logger.info('  - Remote port: ${server!.remotePort}');

        // 验证连接是否真正可用 - 通过尝试发送ping数据
        try {
          // 尝试发送一个小的ping数据来验证连接
          final pingData = [
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
          ];
          server!.add(pingData);
          Logger.info(
            'HTTP/1 connection verification: PASSED - Ping sent successfully',
          );
        } catch (e) {
          Logger.error(
            'HTTP/1 connection verification: FAILED - Cannot send data: $e',
          );
          throw Exception(
            'HTTP/1 connection verification failed - cannot send data: $e',
          );
        }
      } else {
        Logger.error('Connection verification: FAILED - No server connection');
        throw Exception(
          'Connection verification failed - no server connection',
        );
      }

      Logger.info('=== End HTTP/2 Connection Verification ===');
    } catch (e) {
      Logger.error('HTTP/2 connection verification error: $e');
      rethrow;
    }
  }

  /// 启动连接保持机制
  void _startConnectionKeepAlive() {
    try {
      Logger.info('Starting connection keep-alive mechanism');

      // 设置定时器，每30秒检查一次连接状态
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isHttp2) {
          // 对于HTTP/2连接，检查客户端连接状态
          if (!_isConnectionClosed()) {
            Logger.debug('HTTP/2 connection keep-alive check: OK');
          } else {
            Logger.warning(
              'HTTP/2 connection keep-alive check: Connection lost',
            );
            timer.cancel();
            close();
          }
        } else if (server != null && !_isConnectionClosed()) {
          // 对于HTTP/1连接，检查服务器连接状态
          Logger.debug('HTTP/1 connection keep-alive check: OK');
        } else {
          Logger.warning('Connection keep-alive check: Connection lost');
          timer.cancel();
          close();
        }
      });

      Logger.info('Connection keep-alive mechanism started');
    } catch (e) {
      Logger.error('Failed to start connection keep-alive: $e');
    }
  }

  /// 检查连接是否已关闭
  bool _isConnectionClosed() {
    try {
      if (_isHttp2) {
        // 对于HTTP/2连接，检查客户端连接状态
        // 尝试访问客户端socket属性来检查连接状态
        return false;
      } else if (server != null) {
        // 对于HTTP/1连接，检查服务器连接状态
        // 如果socket为null或无法访问，说明连接已关闭
        return false; // 假设连接仍然活跃
      }
      return true;
    } catch (e) {
      Logger.debug('Connection check error: $e');
      return true; // 出错时假设连接已关闭
    }
  }

  /// 判断是否应该重试HTTP/2错误
  bool _shouldRetryHttp2Error(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 可重试的错误类型
    final retryableErrors = [
      'connection error',
      'connection is being forcefully terminated',
      'timeout',
      'network error',
      'connection refused',
      'connection reset',
    ];

    // 不可重试的错误类型
    final nonRetryableErrors = [
      'authentication failed',
      'unauthorized',
      'forbidden',
      'not found',
      'bad request',
      'invalid request',
    ];

    // 检查是否是不可重试的错误
    for (final nonRetryable in nonRetryableErrors) {
      if (errorString.contains(nonRetryable)) {
        return false;
      }
    }

    // 检查是否是可重试的错误
    for (final retryable in retryableErrors) {
      if (errorString.contains(retryable)) {
        return true;
      }
    }

    // 默认不重试未知错误
    return false;
  }

  /// 处理HTTP/2错误
  Future<void> _handleHttp2Error(dynamic error) async {
    try {
      // 记录详细的错误信息
      Logger.error('HTTP/2 connection error details:', error);

      // 记录请求的详细信息
      _logHttp2RequestDetails();

      // 检查是否是连接被强制终止的错误
      if (error.toString().contains('forcefully terminated') ||
          error.toString().contains('errorCode: 10')) {
        Logger.warning(
          'HTTP/2 connection was forcefully terminated - this may be due to proxy configuration issues',
        );

        // 尝试发送HTTP/2 GOAWAY帧
        await _sendHttp2GoAwayFrame();
      }

      // 发送HTTP/1.1错误响应作为fallback
      final errorResponse = _buildHttp11ErrorResponse(error);
      client.add(utf8.encode(errorResponse));
    } catch (sendError) {
      Logger.error('Failed to send error response', sendError);
      // 如果连错误响应都发送失败，直接关闭连接
      close();
    }
  }

  /// 记录HTTP/2请求的详细信息
  void _logHttp2RequestDetails() {
    try {
      Logger.error('=== HTTP/2 Request Details ===');

      // 客户端连接信息
      Logger.error('Client connection:');
      Logger.error('  - Local address: ${client.address}');
      Logger.error('  - Local port: ${client.port}');
      Logger.error('  - Remote address: ${client.remoteAddress}');
      Logger.error('  - Remote port: ${client.remotePort}');

      // 服务器连接信息
      if (server != null) {
        Logger.error('Server connection:');
        Logger.error('  - Local address: ${server!.address}');
        Logger.error('  - Local port: ${server!.port}');
        Logger.error('  - Remote address: ${server!.remoteAddress}');
        Logger.error('  - Remote port: ${server!.remotePort}');
      } else {
        Logger.error('Server connection: Not established');
      }

      // 代理服务器信息
      Logger.error('Proxy server info:');
      Logger.error('  - Server port: $serverPort');
      Logger.error('  - Allocated ports: ${proxyServer._allocatedPorts}');
      Logger.error('  - Is running: ${proxyServer._isRunning}');

      // 缓冲区信息
      Logger.error('Buffer info:');
      Logger.error('  - Buffer size: ${buffer.length} bytes');
      if (buffer.isNotEmpty) {
        Logger.error('  - Buffer preview: ${buffer.take(100).toList()}');
        try {
          final bufferString = utf8.decode(
            buffer.take(200).toList(),
            allowMalformed: true,
          );
          Logger.error(
            '  - Buffer as string: ${bufferString.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}',
          );
        } catch (e) {
          Logger.error('  - Buffer decode error: $e');
        }
      }

      // HTTP/2状态信息
      Logger.error('HTTP/2 state:');
      Logger.error('  - Is HTTP/2: $_isHttp2');
      Logger.error('  - Is HTTPS: $_isHttps');
      Logger.error('  - Is WebSocket: $_isWebSocket');

      Logger.error('=== End HTTP/2 Request Details ===');
    } catch (e) {
      Logger.error('Failed to log HTTP/2 request details: $e');
    }
  }

  /// 发送HTTP/2 GOAWAY帧
  Future<void> _sendHttp2GoAwayFrame() async {
    try {
      // HTTP/2 GOAWAY帧格式
      // 9字节帧头 + 8字节payload
      final goAwayFrame = <int>[
        // 帧长度 (8字节payload)
        0x00, 0x00, 0x08,
        // 帧类型 (7 = GOAWAY)
        0x07,
        // 标志位 (0)
        0x00,
        // 流标识符 (0)
        0x00, 0x00, 0x00, 0x00,
        // Payload: 最后处理的流ID (4字节) + 错误码 (4字节)
        0x00, 0x00, 0x00, 0x00, // 最后处理的流ID
        0x00, 0x00, 0x00, 0x0A, // 错误码 10 (INTERNAL_ERROR)
      ];

      client.add(goAwayFrame);
      Logger.debug('Sent HTTP/2 GOAWAY frame');
    } catch (e) {
      Logger.error('Failed to send HTTP/2 GOAWAY frame', e);
    }
  }

  /// 构建HTTP/1.1错误响应
  String _buildHttp11ErrorResponse(dynamic error) {
    final errorMessage = error.toString();
    final timestamp = DateTime.now().toIso8601String();

    // 获取请求信息
    final requestInfo = _getRequestInfo();

    final errorDetails = '''
HTTP/2 Connection Error
Error: $errorMessage
Time: $timestamp
Proxy: HTTPDNS Smart Proxy

Request Information:
$requestInfo

Connection Details:
- Client: ${client.address}:${client.port} -> ${client.remoteAddress}:${client.remotePort}
- Server Port: $serverPort
- Protocol: HTTP/2
- Buffer Size: ${buffer.length} bytes
''';

    return 'HTTP/1.1 502 Bad Gateway\r\n'
        'Content-Type: text/plain; charset=utf-8\r\n'
        'Content-Length: ${errorDetails.length}\r\n'
        'Connection: close\r\n'
        '\r\n'
        '$errorDetails';
  }

  /// 获取请求信息
  String _getRequestInfo() {
    try {
      return '''
- Server Port: $serverPort
- Protocol: HTTP/2''';
    } catch (e) {
      return '- Error getting request info: $e';
    }
  }

  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    try {
      Logger.debug('Closing connection');

      // 取消订阅与超时定时器，防止悬空回调
      _headerTimeout?.cancel();
      _headerTimeout = null;
      _bodyTimeout?.cancel();
      clientSubscription?.cancel();
      serverSubscription?.cancel();

      // 关闭连接
      client.destroy();
      server?.destroy();
      server = null;
      buffer.clear();

      proxyServer._pendingAuthClients.remove(this);
      proxyServer._authenticatedClients.remove(this);
      Logger.debug('Connection closed successfully');
    } catch (e) {
      Logger.error('Error closing connection', e);
    }
  }

  // 每个上游事件写完后才恢复读取，不以连接累计流量代替积压大小。
  Future<void> _drainClient() async {
    try {
      await client.flush();
      if (!_isClosed) serverSubscription?.resume();
    } catch (_) {
      close();
    }
  }

  Future<void> _finishResponse() async {
    try {
      await client.flush();
      await client.close();
    } catch (_) {
      // 对端已关闭。
    } finally {
      close();
    }
  }

  /// 添加数据转发监控日志
  void _logDataForwarding(
    String direction,
    int originalSize,
    int modifiedSize,
  ) {
    Logger.debug(
      'Data Forwarding: $direction - Original: $originalSize bytes, Modified: $modifiedSize bytes',
    );
  }
}
