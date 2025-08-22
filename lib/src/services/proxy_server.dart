import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/proxy_config.dart';
import '../utils/logger.dart';

/// 支持 HTTPDNS 的智能代理服务器
/// - 兼容 Dio（原域名+原端口）
/// - 兼容 Nakama（127.0.0.1/localhost + 固定域名映射）
/// - 支持端口映射
class ProxyServer {
  final ProxyConfig config;
  ServerSocket? _serverSocket;
  bool _isRunning = false;

  static const platform = MethodChannel('flutter_ali_http_dns');

  ProxyServer({required this.config});

  /// 启动代理服务器
  Future<void> start() async {
    if (_isRunning) {
      await stop();
    }

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        config.port,
      );
      
      _isRunning = true;
      
      _serverSocket!.listen(
        (client) {
          _ClientHandler(client, config).handle();
        },
        onError: (error) {
          Logger.error('Proxy server error', error);
        },
      );
      
      Logger.info('HTTPDNS Smart Proxy listening on ${config.port}');
    } catch (e) {
      Logger.error('Failed to start proxy server', e);
      rethrow;
    }
  }

  /// 停止代理服务器
  Future<void> stop() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }
    _isRunning = false;
    Logger.info('Proxy server stopped');
  }

  /// 获取代理地址
  String? getAddress() {
    if (!_isRunning) {
      return null;
    }
    return '${config.host}:${config.port}';
  }

  /// 检查服务器是否正在运行
  bool get isRunning => _isRunning;

  /// 清理资源
  Future<void> dispose() async {
    await stop();
  }
}

/// 客户端连接处理器
class _ClientHandler {
  final Socket client;
  final ProxyConfig config;
  Socket? server;
  String buffer = '';

  _ClientHandler(this.client, this.config);

  Future<void> handle() async {
    client.listen(
      (data) async {
        if (server == null) {
          buffer += utf8.decode(data);
          
          // 检查是否是 CONNECT 请求（HTTPS）
          final connectMatch = RegExp(r'CONNECT ([^ :]+):(\d+)').firstMatch(buffer);
          if (connectMatch != null) {
            await _handleConnectRequest(connectMatch);
            return;
          }
          
          // 检查是否是普通 HTTP 请求
          final httpMatch = RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').firstMatch(buffer);
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
      final ip = await ProxyServer.platform.invokeMethod('resolveDomain', {'domain': mappedHost});
      final targetIp = (ip != null && ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;
      
      Logger.info('Proxy resolution: $host:$port -> $targetIp:$mappedPort');

      // 建立到真实服务器的连接
      Logger.debug('Attempting to connect to $targetIp:$mappedPort');
      server = await Socket.connect(targetIp, mappedPort, timeout: const Duration(seconds: 10));
      
      // 发送成功响应给客户端
      client.add(utf8.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));

      Logger.debug('HTTPS connection established to $targetIp:$mappedPort');

      // 设置双向转发
      _setupBidirectionalForwarding();
    } catch (e) {
      Logger.error('Failed to establish HTTPS connection to $host:$port', e);
      final errorResponse = 'HTTP/1.1 502 Bad Gateway\r\nContent-Length: ${e.toString().length}\r\n\r\n${e.toString()}';
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
      final ip = await ProxyServer.platform.invokeMethod('resolveDomain', {'domain': mappedHost});
      final targetIp = (ip != null && ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;
      
      Logger.info('Proxy resolution: $host:$port -> $targetIp:$mappedPort');

      // 建立到真实服务器的连接
      server = await Socket.connect(targetIp, mappedPort);
      
      // 修改请求中的 Host 头
      final modifiedRequest = _modifyHttpRequest(request, mappedHost, mappedPort);
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
    // 判断是否是本地代理场景（无法直接配置代理的客户端）
    if (host == '127.0.0.1' || host == 'localhost') {
      // 使用固定域名映射
      if (config.fixedDomain.isNotEmpty) {
        // 基于端口选择域名
        String? mappedHost;
        
        // 优先使用端口号作为 key 进行映射
        final portKey = port.toString();
        if (config.fixedDomain.containsKey(portKey)) {
          mappedHost = config.fixedDomain[portKey]!;
        } else {
          // 如果没有找到端口映射，使用第一个域名作为默认
          mappedHost = config.fixedDomain.values.first;
        }
        
        Logger.info('Applied fixed domain mapping: $host:$port -> $mappedHost');
        return mappedHost;
      }
    }
    return host;
  }

  int _applyPortMapping(int port) {
    final originalPort = port;
    final mappedPort = config.portMap[port.toString()] ?? port;
    if (originalPort != mappedPort) {
      Logger.info('Applied port mapping: $originalPort -> $mappedPort');
    }
    return mappedPort;
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
