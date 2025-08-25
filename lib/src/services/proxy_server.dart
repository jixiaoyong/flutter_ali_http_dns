import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/proxy_config.dart';
import '../models/port_mapping.dart';
import '../services/port_mapping_manager.dart';
import '../utils/logger.dart';

/// 端口占用信息
class PortInfo {
  final int port;
  final int? pid;
  final String? processName;
  final String? command;
  final bool isOwnProcess;

  PortInfo({
    required this.port,
    this.pid,
    this.processName,
    this.command,
    required this.isOwnProcess,
  });

  @override
  String toString() {
    if (pid == null) {
      return 'Port $port is not in use';
    }
    return 'Port $port is used by PID $pid ($processName) - ${isOwnProcess ? "Own process" : "Other process"}';
  }
}

/// 支持 HTTPDNS 的代理服务器
/// - 兼容 Dio（原域名+原端口）
/// - 兼容 Nakama（127.0.0.1/localhost + 动态域名映射）
/// - 支持动态端口分配和映射管理
/// - 默认监听单个端口，支持动态添加端口
class ProxyServer {
  ProxyConfig config;
  List<ServerSocket> _serverSockets = [];
  List<int> _allocatedPorts = []; // 动态分配的端口列表
  bool _isRunning = false;
  static int? _currentPid;

  // 端口映射管理器
  final PortMappingManager _mappingManager = PortMappingManager();

  // 单例模式：确保同一个app中只有一个实例
  static ProxyServer? _instance;
  static final Map<int, ProxyServer> _instancesByPort = {};

  static const platform = MethodChannel('flutter_ali_http_dns');

  ProxyServer({required this.config}) {
    // 记录当前进程ID
    _currentPid ??= getCurrentPid();
  }

  /// 获取当前进程ID
  static int getCurrentPid() {
    try {
      // 在 Unix 系统上使用 getpid()
      if (Platform.isMacOS || Platform.isLinux) {
        final result = Process.runSync('sh', ['-c', 'echo \$\$']);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      }
      // 在 Windows 上使用 %PID%
      else if (Platform.isWindows) {
        final result = Process.runSync('cmd', ['/c', 'echo %PID%']);
        return int.tryParse(result.stdout.toString().trim()) ?? 0;
      }
      return 0;
    } catch (e) {
      Logger.warning('Failed to get current PID: $e');
      return 0;
    }
  }

  /// 检查端口是否可用
  static Future<bool> isPortAvailable(int port) async {
    try {
      final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取端口占用详细信息
  static Future<PortInfo> getPortInfo(int port) async {
    try {
      // 首先尝试绑定端口来检查是否可用
      final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await socket.close();
      return PortInfo(port: port, isOwnProcess: false);
    } catch (e) {
      // 端口被占用，尝试获取占用信息
      return await _getPortUsageInfo(port);
    }
  }

  /// 获取端口使用信息
  static Future<PortInfo> _getPortUsageInfo(int port) async {
    try {
      String command;
      List<String> args;

      if (Platform.isMacOS || Platform.isLinux) {
        command = 'lsof';
        args = ['-i', ':$port', '-t'];
      } else if (Platform.isWindows) {
        command = 'netstat';
        args = ['-ano', '|', 'findstr', ':$port'];
      } else {
        return PortInfo(port: port, isOwnProcess: false);
      }

      final result = Process.runSync(command, args);
      if (result.exitCode != 0) {
        return PortInfo(port: port, isOwnProcess: false);
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
        return PortInfo(port: port, isOwnProcess: false);
      }

      // 解析PID
      final lines = output.split('\n');
      if (lines.isEmpty) {
        return PortInfo(port: port, isOwnProcess: false);
      }

      final pidLine = lines.first.trim();
      final pid = int.tryParse(pidLine);
      if (pid == null) {
        return PortInfo(port: port, isOwnProcess: false);
      }

      // 检查是否是自己的进程
      final isOwnProcess = pid == _currentPid;

      // 获取进程信息
      String? processName;
      String? processCommand;

      try {
        if (Platform.isMacOS || Platform.isLinux) {
          final psResult = Process.runSync('ps', ['-p', '$pid', '-o', 'comm=']);
          processName = psResult.stdout.toString().trim();
        } else if (Platform.isWindows) {
          final tasklistResult = Process.runSync('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV']);
          final lines = tasklistResult.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(',');
            if (parts.length > 0) {
              processName = parts[0].replaceAll('"', '');
            }
          }
        }
      } catch (e) {
        Logger.warning('Failed to get process info: $e');
      }

      return PortInfo(
        port: port,
        pid: pid,
        processName: processName,
        command: processCommand,
        isOwnProcess: isOwnProcess,
      );
    } catch (e) {
      Logger.warning('Failed to get port usage info: $e');
      return PortInfo(port: port, isOwnProcess: false);
    }
  }

  /// 检查端口是否被自己的应用占用
  static Future<bool> isPortUsedByOwnApp(int port) async {
    try {
      final portInfo = await getPortInfo(port);
      return portInfo.isOwnProcess;
    } catch (e) {
      return false;
    }
  }

  /// 启动默认代理服务器（监听单个端口）
  ///
  /// [config] 代理配置
  /// 返回启动的代理服务器实例
  static Future<ProxyServer> startDefault(ProxyConfig config) async {
    Logger.info('Starting default proxy server on single port');
    
    // 创建代理服务器实例
    final server = ProxyServer(config: config);
    
    // 启动默认代理（监听一个可用端口）
    await server._startDefault();
    
    // 注册单例实例
    _instance = server;
    
    return server;
  }

  /// 内部启动默认代理方法
  Future<void> _startDefault() async {
    try {
      Logger.info('Starting default proxy server on single port');
      
      // 分配一个默认端口
      final port = await _allocateDefaultPort();
      _allocatedPorts = [port];
      
      // 创建服务器socket并开始监听
      await _createServerSocket(port);
      
      _isRunning = true;
      Logger.info('Default proxy server started on port $port');
    } catch (e) {
      Logger.error('Failed to start default proxy server', e);
      rethrow;
    }
  }

  /// 分配默认端口
  Future<int> _allocateDefaultPort() async {
    // 优先使用配置中的端口池
    if (config.portPool != null && config.portPool!.isNotEmpty) {
      for (final port in config.portPool!) {
        if (await isPortAvailable(port)) {
          return port;
        }
      }
    }
    
    // 如果没有可用端口池，使用配置的端口范围
    final startPort = config.startPort ?? 4041;
    final endPort = config.endPort ?? (startPort + 100);
    
    // 验证端口范围
    if (endPort <= startPort) {
      throw Exception('endPort ($endPort) must be greater than startPort ($startPort)');
    }
    
    // 首先在指定范围内寻找
    for (int port = startPort; port <= endPort; port++) {
      if (await isPortAvailable(port)) {
        return port;
      }
    }
    
    // 如果指定范围内没有可用端口，向上突破范围寻找
    Logger.warning('No available ports in range $startPort-$endPort, expanding search upward');
    for (int port = endPort + 1; port <= endPort + 100; port++) {
      if (await isPortAvailable(port)) {
        Logger.info('Found available port $port outside configured range');
        return port;
      }
    }
    
    // 如果向上突破也没有，向下突破范围寻找
    Logger.warning('No available ports above $endPort, expanding search downward');
    for (int port = startPort - 1; port >= startPort - 100; port--) {
      if (port > 0 && await isPortAvailable(port)) {
        Logger.info('Found available port $port outside configured range');
        return port;
      }
    }
    
    throw Exception('No available ports found in range $startPort-$endPort or nearby ranges');
  }

  /// 启动代理服务器
  Future<void> start() async {
    if (_isRunning) {
      await stop();
    }

    try {
      // 为每个端口创建服务器套接字
      for (final port in _allocatedPorts) {
        await _createServerSocket(port);
      }

      _isRunning = true;
      Logger.info('HTTPDNS Smart Proxy started on ports: $_allocatedPorts');
    } catch (e) {
      Logger.error('Failed to start proxy server', e);
      rethrow;
    }
  }

  /// 创建服务器套接字
  Future<ServerSocket> _createServerSocket(int port) async {
    final serverSocket = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
    );

    _serverSockets.add(serverSocket);

    serverSocket.listen(
      (client) {
        _ClientHandler(client, this).handle();
      },
      onError: (error) {
        Logger.error('Proxy server error on port $port', error);
      },
    );

    Logger.info('HTTPDNS Smart Proxy listening on port $port');
    return serverSocket;
  }

  /// 停止代理服务器
  Future<void> stop() async {
    await _closeAllServerSockets();
    _allocatedPorts.clear();
    _isRunning = false;

    // 从实例映射中移除所有端口
    for (final port in _allocatedPorts) {
      _instancesByPort.remove(port);
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
    for (final server in _instancesByPort.values) {
      await server.stop();
    }
    _instancesByPort.clear();
    _instance = null;
  }

  /// 获取所有运行的端口
  static List<int> getRunningPorts() {
    return _instancesByPort.keys.toList();
  }

  /// 获取当前分配的端口列表
  List<int> get allocatedPorts => List.unmodifiable(_allocatedPorts);

  /// 获取端口映射管理器
  PortMappingManager get mappingManager => _mappingManager;

  /// 注册端口映射
  Future<bool> registerMapping({
    required int localPort,
    int? targetPort,
    required String targetDomain,
    String? name,
    String? description,
  }) async {
    if (!_isRunning) {
      Logger.warning('Proxy server is not running');
      return false;
    }

    if (!_allocatedPorts.contains(localPort)) {
      Logger.warning('Port $localPort is not being listened by proxy server');
      return false;
    }

    final mapping = PortMapping(
      localPort: localPort,
      targetPort: targetPort,
      targetDomain: targetDomain,
      createdAt: DateTime.now(),
      name: name,
      description: description,
    );

    return await _mappingManager.addMapping(mapping);
  }

  /// 移除端口映射
  Future<bool> removeMapping(int localPort) async {
    return await _mappingManager.removeMapping(localPort);
  }

  /// 获取端口映射
  PortMapping? getMapping(int localPort) {
    return _mappingManager.getMapping(localPort);
  }

  /// 获取所有端口映射
  Map<int, PortMapping> getAllMappings() {
    return _mappingManager.getAllMappings();
  }

  /// 注册端口监听（动态添加端口）
  ///
  /// [port] 要监听的端口
  /// 返回注册是否成功
  Future<bool> registerPort(int port) async {
    try {
      Logger.info('Registering port $port for listening');
      
      // 检查端口是否已经在监听
      if (_allocatedPorts.contains(port)) {
        Logger.warning('Port $port is already being listened on');
        return true;
      }
      
      // 检查端口是否可用
      if (!await isPortAvailable(port)) {
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
    return _allocatedPorts.contains(port);
  }
}

/// 客户端连接处理器
class _ClientHandler {
  final Socket client;
  final ProxyServer proxyServer;
  Socket? server;
  String buffer = '';

  _ClientHandler(this.client, this.proxyServer);

  Future<void> handle() async {
    client.listen(
      (data) async {
        if (server == null) {
          buffer += utf8.decode(data);

          // 检查是否是 CONNECT 请求（HTTPS）
          final connectMatch =
              RegExp(r'CONNECT ([^ :]+):(\d+)').firstMatch(buffer);
          if (connectMatch != null) {
            await _handleConnectRequest(connectMatch);
            return;
          }

          // 检查是否是普通 HTTP 请求
          final httpMatch =
              RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').firstMatch(buffer);
          if (httpMatch != null) {
            await _handleHttpRequest(httpMatch, buffer);
            return;
          }
        } else {
          // 数据转发
          try {
            server?.add(data);
          } catch (e) {
            Logger.error('Server socket error', e);
            close();
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

  Future<void> _handleConnectRequest(RegExpMatch match) async {
    String host = match.group(1)!;
    int port = int.parse(match.group(2)!);

    Logger.debug('Received CONNECT request: $host:$port');

    try {
      // 应用域名和端口映射
      final mappedHost = _applyDomainMapping(host, port);
      final mappedPort = _applyPortMapping(port);

      // HTTPDNS 解析
      final ip = await ProxyServer.platform
          .invokeMethod('resolveDomain', {'domain': mappedHost});
      final targetIp =
          (ip != null && ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;

      Logger.info('Proxy resolution: $host:$port -> $targetIp:$mappedPort');

      // 建立到真实服务器的连接
      Logger.debug('Attempting to connect to $targetIp:$mappedPort');
      server = await Socket.connect(targetIp, mappedPort,
          timeout: const Duration(seconds: 10));

      // 发送成功响应给客户端
      client.add(utf8.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));

      Logger.debug('HTTPS connection established to $targetIp:$mappedPort');

      // 设置双向转发
      _setupBidirectionalForwarding();
    } catch (e) {
      Logger.error('Failed to establish HTTPS connection to $host:$port', e);
      final errorResponse =
          'HTTP/1.1 502 Bad Gateway\r\nContent-Length: ${e.toString().length}\r\n\r\n${e.toString()}';
      client.add(utf8.encode(errorResponse));
      close();
    }
  }

  Future<void> _handleHttpRequest(RegExpMatch match, String request) async {
    final method = match.group(1)!;
    final url = match.group(2)!;

    Logger.debug('Received HTTP request: $method $url');

    try {
      // 解析 URL
      final uri = Uri.parse(url.startsWith('http') ? url : 'http://$url');
      String host = uri.host;
      int port = uri.port > 0 ? uri.port : 80;

      // 应用域名和端口映射
      final mappedHost = _applyDomainMapping(host, port);
      final mappedPort = _applyPortMapping(port);

      // HTTPDNS 解析
      final ip = await ProxyServer.platform
          .invokeMethod('resolveDomain', {'domain': mappedHost});
      final targetIp =
          (ip != null && ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;

      Logger.info('Proxy resolution: $host:$port -> $targetIp:$mappedPort');

      // 建立到真实服务器的连接
      server = await Socket.connect(targetIp, mappedPort);

      // 修改请求中的 Host 头
      final modifiedRequest =
          _modifyHttpRequest(request, mappedHost, mappedPort);
      server!.add(utf8.encode(modifiedRequest));

      Logger.debug('HTTP connection established to $targetIp:$mappedPort');

      // 设置双向转发
      _setupBidirectionalForwarding();
    } catch (e) {
      Logger.error('Failed to establish HTTP connection', e);
      client.add(utf8.encode('HTTP/1.1 502 Bad Gateway\r\n\r\n'));
      close();
    }
  }

  String _applyDomainMapping(String host, int port) {
    // 1. 如果请求包含明确域名，直接返回（Dio场景）
    if (host != '127.0.0.1' && host != 'localhost') {
      return host;
    }
    
    // 2. 如果是localhost，查找动态端口映射
    final dynamicMapping = proxyServer.getMapping(port);
    if (dynamicMapping != null) {
      Logger.info('Applied dynamic domain mapping: $host:$port -> ${dynamicMapping.targetDomain}');
      return dynamicMapping.targetDomain;
    }
    
    // 3. 没有映射，返回原始域名
    return host;
  }

  int _applyPortMapping(int port) {
    final originalPort = port;
    
    // 查找动态端口映射
    final dynamicMapping = proxyServer.getMapping(port);
    if (dynamicMapping != null && dynamicMapping.targetPort != null) {
      Logger.info('Applied dynamic port mapping: $originalPort -> ${dynamicMapping.targetPort}');
      return dynamicMapping.targetPort!;
    }
    
    // 没有映射或targetPort为null，返回原始端口
    return port;
  }

  String _modifyHttpRequest(String request, String host, int port) {
    // 修改请求中的 Host 头
    final lines = request.split('\r\n');
    final modifiedLines = <String>[];

    for (final line in lines) {
      if (line.toLowerCase().startsWith('host:')) {
        // 修改 Host 头
        final portSuffix = port != 80 ? ':$port' : '';
        modifiedLines.add('Host: $host$portSuffix');
      } else {
        modifiedLines.add(line);
      }
    }

    return modifiedLines.join('\r\n');
  }

  void _setupBidirectionalForwarding() {
    // 参考代码的方式：分离客户端和服务器数据处理
    // 服务器数据转发到客户端
    server!.listen(
      (data) {
        try {
          client.add(data);
        } catch (e) {
          Logger.error('Client socket error', e);
          close();
        }
      },
      onError: (error) {
        Logger.error('Server socket error: $error');
        close();
      },
      onDone: () {
        Logger.debug('Server connection closed');
        close();
      },
    );

    // 注意：不要在这里再次监听client，因为client已经在handle()方法中被监听了
    // 客户端数据直接通过handle()方法中的逻辑转发到服务器
  }

  void close() {
    try {
      client.destroy();
      server?.destroy();
    } catch (e) {
      Logger.error('Error closing sockets', e);
    }
  }
}
