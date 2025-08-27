import 'dart:io';
import 'dart:convert';
import '../services/dns_resolver.dart';
import '../utils/logger.dart';
import '../utils/mapping_utils.dart';

/// HTTP/1.1处理工具类
/// 提供HTTP/1.1协议处理的通用方法
class Http1Handler {
  /// 处理HTTP/1.1请求
  /// 
  /// [client] 客户端Socket连接
  /// [server] 服务器Socket连接
  /// [match] 正则匹配结果
  /// [request] 原始请求字符串
  /// [dnsResolver] DNS解析器实例
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// [includeDomainInAuthority] 是否在Host头部中包含域名信息
  /// 返回处理是否成功
  static Future<bool> handleHttpRequest(
    Socket client,
    Socket? server,
    RegExpMatch match,
    String request,
    DnsResolver dnsResolver,
    dynamic proxyServer,
    {bool includeDomainInAuthority = true}
  ) async {
    try {
      final method = match.group(1)!;
      final url = match.group(2)!;

      Logger.info('=== HTTP/1.1 Request Processing ===');
      Logger.info('Original request: $method $url');

      // 解析 URL
      final uri = Uri.parse(url.startsWith('http') ? url : 'http://$url');
      String host = uri.host;
      int port = uri.port > 0 ? uri.port : 80;

      Logger.info('Parsed request:');
      Logger.info('  - Original host: $host');
      Logger.info('  - Original port: $port');
      Logger.info('  - Full URL: $url');

      // 应用域名和端口映射
      final mappingResult = MappingUtils.applyMapping(host, port, proxyServer);
      final mappedHost = mappingResult.mappedHost;
      final mappedPort = mappingResult.mappedPort;

      Logger.info('Domain mapping:');
      Logger.info('  - Original: $host:$port');
      Logger.info('  - Mapped: $mappedHost:$mappedPort');

      // 验证映射后的域名
      if (mappedHost.isEmpty || mappedHost == '*') {
        throw Exception('Invalid mapped host: $mappedHost');
      }

      // DNS 解析
      Logger.info('DNS resolution:');
      Logger.info('  - Domain to resolve: $mappedHost');
      
      final ip = await dnsResolver.resolve(mappedHost);
      final targetIp = (ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;

      Logger.info('  - Resolved IP: $targetIp');
      Logger.info('  - Final target: $targetIp:$mappedPort');

      // 验证目标IP
      if (targetIp.isEmpty || targetIp == '*') {
        throw Exception('Invalid target IP: $targetIp');
      }

      // 建立到真实服务器的连接
      Logger.info('Establishing connection:');
      Logger.info('  - Target: $targetIp:$mappedPort');
      Logger.info('  - Method: $method');
      
      server = await Socket.connect(targetIp, mappedPort);

      // 修改请求中的 Host 头
      final modifiedRequest = _modifyHttpRequest(request, mappedHost, mappedPort, includeDomainInAuthority: includeDomainInAuthority);
      server.add(utf8.encode(modifiedRequest));

      Logger.info('Connection established successfully');
      Logger.info('Modified request sent to target server');
      Logger.info('=== End HTTP/1.1 Request Processing ===');

      // 设置双向转发
      _setupBidirectionalForwarding(client, server);

      return true;
    } catch (e) {
      Logger.error('=== HTTP/1.1 Request Failed ===');
      Logger.error('Error details: $e');
      Logger.error('=== End HTTP/1.1 Request Failed ===');
      client.add(utf8.encode('HTTP/1.1 502 Bad Gateway\r\n\r\n'));
      return false;
    }
  }

  /// 处理HTTPS CONNECT请求
  /// 
  /// [client] 客户端Socket连接
  /// [server] 服务器Socket连接
  /// [match] 正则匹配结果
  /// [dnsResolver] DNS解析器实例
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// 返回处理是否成功
  static Future<bool> handleConnectRequest(
    Socket client,
    Socket? server,
    RegExpMatch match,
    DnsResolver dnsResolver,
    dynamic proxyServer,
  ) async {
    try {
      String host = match.group(1)!;
      int port = int.parse(match.group(2)!);

      Logger.info('=== HTTPS CONNECT Request Processing ===');
      Logger.info('Original CONNECT request: $host:$port');

      // 应用域名和端口映射
      final mappingResult = MappingUtils.applyMapping(host, port, proxyServer);
      final mappedHost = mappingResult.mappedHost;
      final mappedPort = mappingResult.mappedPort;

      Logger.info('Domain mapping:');
      Logger.info('  - Original: $host:$port');
      Logger.info('  - Mapped: $mappedHost:$mappedPort');

      // 验证映射后的域名
      if (mappedHost.isEmpty || mappedHost == '*') {
        throw Exception('Invalid mapped host: $mappedHost');
      }

      // DNS 解析
      Logger.info('DNS resolution:');
      Logger.info('  - Domain to resolve: $mappedHost');
      
      final ip = await dnsResolver.resolve(mappedHost);
      final targetIp = (ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;

      Logger.info('  - Resolved IP: $targetIp');
      Logger.info('  - Final target: $targetIp:$mappedPort');

      // 验证目标IP
      if (targetIp.isEmpty || targetIp == '*') {
        throw Exception('Invalid target IP: $targetIp');
      }

      // 建立到真实服务器的连接
      Logger.info('Establishing HTTPS connection:');
      Logger.info('  - Target: $targetIp:$mappedPort');
      
      server = await Socket.connect(targetIp, mappedPort,
          timeout: const Duration(seconds: 10));

      // 发送成功响应给客户端
      client.add(utf8.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));

      Logger.info('HTTPS connection established successfully');
      Logger.info('CONNECT response sent to client');
      Logger.info('=== End HTTPS CONNECT Request Processing ===');

      // 设置双向转发
      _setupBidirectionalForwarding(client, server);

      return true;
    } catch (e) {
      Logger.error('=== HTTPS CONNECT Request Failed ===');
      Logger.error('Error details: $e');
      Logger.error('=== End HTTPS CONNECT Request Failed ===');
      final errorResponse =
          'HTTP/1.1 502 Bad Gateway\r\nContent-Length: ${e.toString().length}\r\n\r\n${e.toString()}';
      client.add(utf8.encode(errorResponse));
      return false;
    }
  }

  /// 处理WebSocket请求
  /// 
  /// [client] 客户端Socket连接
  /// [server] 服务器Socket连接
  /// [requestString] 原始请求字符串
  /// [dnsResolver] DNS解析器实例
  /// [proxyServer] 代理服务器实例（用于获取映射）
  /// 返回处理是否成功
  static Future<bool> handleWebSocketRequest(
    Socket client,
    Socket? server,
    String requestString,
    DnsResolver dnsResolver,
    dynamic proxyServer,
  ) async {
    try {
      // 解析WebSocket请求
      final lines = requestString.split('\r\n');
      String? host;
      int port = 80;

      for (final line in lines) {
        if (line.toLowerCase().startsWith('host:')) {
          final hostLine = line.substring(5).trim();
          final colonIndex = hostLine.lastIndexOf(':');
          if (colonIndex > 0) {
            host = hostLine.substring(0, colonIndex);
            port = int.parse(hostLine.substring(colonIndex + 1));
          } else {
            host = hostLine;
          }
          break;
        }
      }

      if (host == null) {
        throw Exception('Host header not found in WebSocket request');
      }

      Logger.debug('WebSocket request: $host:$port');

      // 应用域名和端口映射
      final mappingResult = MappingUtils.applyMapping(host, port, proxyServer);
      final mappedHost = mappingResult.mappedHost;
      final mappedPort = mappingResult.mappedPort;

      // 验证映射后的域名
      if (mappedHost.isEmpty || mappedHost == '*') {
        throw Exception('Invalid mapped host: $mappedHost');
      }

      Logger.debug(
          'WebSocket domain mapping: $host:$port -> $mappedHost:$mappedPort');

      // DNS 解析
      final ip = await dnsResolver.resolve(mappedHost);
      final targetIp = (ip.isNotEmpty && ip != mappedHost) ? ip : mappedHost;

      Logger.info(
          'WebSocket proxy resolution: $host:$port -> $targetIp:$mappedPort');

      // 验证目标IP
      if (targetIp.isEmpty || targetIp == '*') {
        throw Exception('Invalid target IP: $targetIp');
      }

      // 建立到真实服务器的连接
      Logger.debug(
          'Attempting to establish WebSocket connection to $targetIp:$mappedPort');
      server = await Socket.connect(targetIp, mappedPort,
          timeout: const Duration(seconds: 10));

      // 转发WebSocket握手请求到服务器
      server.add(utf8.encode(requestString));

      Logger.debug('WebSocket connection established to $targetIp:$mappedPort');

      // 设置双向转发
      _setupBidirectionalForwarding(client, server);

      return true;
    } catch (e) {
      Logger.error('Failed to establish WebSocket connection', e);
      final errorResponse =
          'HTTP/1.1 502 Bad Gateway\r\nContent-Length: ${e.toString().length}\r\n\r\n${e.toString()}';
      client.add(utf8.encode(errorResponse));
      return false;
    }
  }



  /// 修改HTTP请求中的Host头
  static String _modifyHttpRequest(String request, String host, int port, {bool includeDomainInAuthority = true}) {
    // 修改请求中的 Host 头
    final lines = request.split('\r\n');
    final modifiedLines = <String>[];

    for (final line in lines) {
      if (line.toLowerCase().startsWith('host:')) {
        // 根据includeDomainInAuthority设置决定是否修改Host头
        if (includeDomainInAuthority) {
          // 修改 Host 头
          final portSuffix = port != 80 ? ':$port' : '';
          modifiedLines.add('Host: $host$portSuffix');
          Logger.debug('Modified Host header: $host$portSuffix');
        } else {
          // 保持原始Host头不变
          modifiedLines.add(line);
          Logger.debug('Keeping original Host header: ${line.substring(6)}');
        }
      } else {
        modifiedLines.add(line);
      }
    }

    return modifiedLines.join('\r\n');
  }

  /// 设置双向转发
  static void _setupBidirectionalForwarding(Socket client, Socket server) {
    bool clientClosed = false;
    bool serverClosed = false;
    int clientToServerBytes = 0;
    int serverToClientBytes = 0;

    Logger.info('=== Bidirectional Forwarding Setup ===');
    Logger.info('Starting data forwarding between client and server');

    // 客户端到服务器
    client.listen(
      (data) {
        if (!serverClosed) {
          try {
            clientToServerBytes += data.length;
            server.add(data);
            Logger.debug('Client -> Server: ${data.length} bytes (Total: $clientToServerBytes)');
          } catch (e) {
            Logger.error('Error forwarding data from client to server', e);
            _closeConnections(client, server);
          }
        }
      },
      onError: (error) {
        Logger.error('Client to server forwarding error', error);
        _closeConnections(client, server);
      },
      onDone: () {
        Logger.info('Client connection closed (Total bytes sent: $clientToServerBytes)');
        clientClosed = true;
        _closeConnections(client, server);
      },
    );

    // 服务器到客户端
    server.listen(
      (data) {
        if (!clientClosed) {
          try {
            serverToClientBytes += data.length;
            client.add(data);
            Logger.debug('Server -> Client: ${data.length} bytes (Total: $serverToClientBytes)');
          } catch (e) {
            Logger.error('Error forwarding data from server to client', e);
            _closeConnections(client, server);
          }
        }
      },
      onError: (error) {
        Logger.error('Server to client forwarding error', error);
        _closeConnections(client, server);
      },
      onDone: () {
        Logger.info('Server connection closed (Total bytes sent: $serverToClientBytes)');
        serverClosed = true;
        _closeConnections(client, server);
      },
    );
  }

  /// 关闭连接
  static void _closeConnections(Socket client, Socket server) {
    try {
      client.close();
    } catch (e) {
      Logger.debug('Error closing client connection: $e');
    }
    
    try {
      server.close();
    } catch (e) {
      Logger.debug('Error closing server connection: $e');
    }
  }
}
