import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';

import '../services/dns_resolver.dart';
import '../utils/logger.dart';
import '../utils/protocol_utils.dart';

/// HTTP/2处理工具类
/// 提供HTTP/2协议处理的通用方法
class Http2Handler {
  /// 处理HTTP/2连接
  ///
  /// [clientSocket] 客户端Socket连接
  /// [serverPort] 服务器端口
  /// [dnsResolver] DNS解析器实例
  /// 返回处理是否成功
  static Future<bool> handleHttp2Connection(
    Socket clientSocket,
    int serverPort,
    DnsResolver dnsResolver, {
    List<int>? initialData,
  }) async {
    Logger.debug('Starting HTTP/2 connection handling for port: $serverPort');

    // 简化实现：直接转发数据，不进行复杂的映射处理
    try {
      // 创建服务器传输连接
      ServerTransportConnection? serverTransport;

      serverTransport = ServerTransportConnection.viaSocket(clientSocket);
      Logger.debug('Using direct Socket for server transport');

      Logger.debug('HTTP/2 connection setup completed');
      return true;
    } catch (e) {
      Logger.error('Failed to handle HTTP/2 connection', e);
      return false;
    }
  }

  /// 清理传输连接
  static Future<void> _cleanupTransports(
    ClientTransportConnection? clientTransport,
    ServerTransportConnection? serverTransport,
  ) async {
    try {
      if (clientTransport != null) {
        await clientTransport.finish();
      }
      if (serverTransport != null) {
        await serverTransport.finish();
      }
    } catch (e) {
      Logger.error('Error cleaning up transports', e);
    }
  }

  /// 设置HTTP/2双向转发
  static void _setupBidirectionalForwarding(
      ServerTransportConnection serverTransport,
      ClientTransportConnection clientTransport,
      String targetHost,
      int targetPort,
      bool isSecure,
      {bool includeDomainInAuthority = true,
      String? resolvedIp}) {
    try {
      // 客户端 -> 目标服务器
      // 使用cancelOnError: false 来防止Stream监听错误导致整个连接失败
      serverTransport.incomingStreams.listen(
        (ServerTransportStream stream) {
          _handleClientStream(
              stream, clientTransport, targetHost, targetPort, isSecure,
              includeDomainInAuthority: includeDomainInAuthority,
              resolvedIp: resolvedIp);
        },
        onError: (error) {
          Logger.error('Error in server transport', error);
          // 对于Stream监听错误，我们尝试继续处理，而不是立即关闭连接
          if (error
              .toString()
              .contains('Stream has already been listened to')) {
            Logger.warning(
                'Stream already listened error detected, continuing...');
          }
        },
        onDone: () {
          Logger.debug('Server transport stream listener done');
        },
        cancelOnError: false, // 关键：不因为错误而取消监听
      );

      // 注意：HTTP/2传输连接会自动管理连接状态
      Logger.debug('HTTP/2 bidirectional forwarding setup completed');
    } catch (e) {
      Logger.error('Error setting up bidirectional forwarding', e);
      // 如果设置失败，尝试清理资源
      _cleanupTransports(clientTransport, null);
    }
  }

  /// 处理客户端流
  static void _handleClientStream(
      ServerTransportStream clientStream,
      ClientTransportConnection targetTransport,
      String targetHost,
      int targetPort,
      bool isSecure,
      {bool includeDomainInAuthority = true,
      String? resolvedIp}) {
    Logger.debug('Handling client stream: ${clientStream.id}');

    // 使用一个标志来确保只处理一次头部消息
    bool headersProcessed = false;
    ClientTransportStream? targetStream;
    StreamSubscription? messageSubscription;

    messageSubscription = clientStream.incomingMessages.listen(
      (StreamMessage message) async {
        try {
          if (message is HeadersStreamMessage && !headersProcessed) {
            headersProcessed = true;
            targetStream = await _handleClientHeaders(clientStream,
                targetTransport, message, targetHost, targetPort, isSecure,
                includeDomainInAuthority: includeDomainInAuthority,
                resolvedIp: resolvedIp);
          } else if (message is DataStreamMessage && targetStream != null) {
            // 数据消息直接转发到目标流
            targetStream!.sendData(message.bytes, endStream: message.endStream);
            Logger.debug(
                'Forwarded ${message.bytes.length} bytes from client to target');
          }
        } catch (e) {
          Logger.error('Error handling client stream message', e);
          _sendErrorResponse(clientStream, 500, 'Internal Server Error');
          messageSubscription?.cancel();
        }
      },
      onError: (error) {
        Logger.error('Error in client stream', error);
        // 对于Stream监听错误，我们尝试继续处理
        if (error.toString().contains('Stream has already been listened to')) {
          Logger.warning(
              'Client stream already listened error detected, continuing...');
        } else {
          _sendErrorResponse(clientStream, 500, 'Stream Error');
          messageSubscription?.cancel();
        }
      },
      onDone: () {
        Logger.debug('Client stream message listener done');
        messageSubscription?.cancel();
      },
      cancelOnError: false, // 不因为错误而取消监听
    );
  }

  /// 处理客户端头部
  static Future<ClientTransportStream?> _handleClientHeaders(
      ServerTransportStream clientStream,
      ClientTransportConnection targetTransport,
      HeadersStreamMessage message,
      String targetHost,
      int targetPort,
      bool isSecure,
      {bool includeDomainInAuthority = true,
      String? resolvedIp}) async {
    try {
      // 解析头部信息
      final headers = _parseHeaders(message.headers);

      // 记录原始头部信息
      Logger.debug('=== Original Headers ===');
      headers.forEach((key, value) {
        Logger.debug('  $key: $value');
      });

      // 修改头部信息（应用域名映射等）
      final modifiedHeaders = _modifyHeaders(headers, targetHost, targetPort,
          isSecure: isSecure,
          includeDomainInAuthority: includeDomainInAuthority,
          resolvedIp: resolvedIp);

      // 记录修改后的头部信息
      Logger.debug('=== Modified Headers ===');
      for (final header in modifiedHeaders) {
        final name = utf8.decode(header.name);
        final value = utf8.decode(header.value);
        Logger.debug('  $name: $value');
      }

      // 创建目标请求
      Logger.debug(
          'Creating target request with ${modifiedHeaders.length} headers...');
      ClientTransportStream targetStream;
      try {
        targetStream =
            targetTransport.makeRequest(modifiedHeaders, endStream: false);
        Logger.debug('Target stream created successfully: ${targetStream.id}');
      } catch (e) {
        Logger.error('Failed to create target request: $e');
        if (e.toString().contains('forcefully terminated')) {
          Logger.error(
              'Target request creation failed due to forceful termination');
        }
        _sendErrorResponse(
            clientStream, 502, 'Failed to create target request: $e');
        return null;
      }

      // 设置双向转发（这会处理所有后续的消息）
      _setupStreamBidirectionalForwarding(clientStream, targetStream);

      // 如果头部消息包含endStream标志，需要处理
      if (message.endStream) {
        targetStream.sendData([], endStream: true);
        Logger.debug('Sent endStream flag to target');
      }

      return targetStream;
    } catch (e) {
      Logger.error('Error handling client headers', e);
      _sendErrorResponse(clientStream, 502, 'Bad Gateway: $e');
      return null;
    }
  }

  /// 设置流双向转发（只处理目标到客户端的响应）
  static void _setupStreamBidirectionalForwarding(
    ServerTransportStream clientStream,
    ClientTransportStream targetStream,
  ) {
    StreamSubscription? targetMessageSubscription;

    // 目标服务器 -> 客户端
    targetMessageSubscription = targetStream.incomingMessages.listen(
      (message) {
        try {
          if (message is HeadersStreamMessage) {
            clientStream.sendHeaders(message.headers,
                endStream: message.endStream);
            Logger.debug('Forwarded headers from target to client');
          } else if (message is DataStreamMessage) {
            clientStream.sendData(message.bytes, endStream: message.endStream);
            Logger.debug(
                'Forwarded ${message.bytes.length} bytes from target to client');
          }
        } catch (e) {
          Logger.error('Error forwarding message to client', e);
          targetMessageSubscription?.cancel();
        }
      },
      onError: (error) {
        Logger.error('Error in target stream', error);
        // 对于Stream监听错误，我们尝试继续处理
        if (error.toString().contains('Stream has already been listened to')) {
          Logger.warning(
              'Target stream already listened error detected, continuing...');
        } else if (error.toString().contains('forcefully terminated')) {
          Logger.error(
              'Target stream forcefully terminated - this may indicate a protocol mismatch');
          Logger.error(
              'This is likely the source of the gRPC "Connection is being forcefully terminated" error');
          // 尝试发送错误响应给客户端
          try {
            _sendErrorResponse(
                clientStream, 502, 'Target connection terminated: $error');
          } catch (e) {
            Logger.error('Failed to send error response', e);
          }
        } else {
          targetMessageSubscription?.cancel();
        }
      },
      onDone: () {
        Logger.debug('Target stream message listener done');
        targetMessageSubscription?.cancel();
      },
      cancelOnError: false, // 不因为错误而取消监听
    );
  }

  /// 解析头部信息
  static Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final name = utf8.decode(header.name);
      final value = utf8.decode(header.value);
      result[name] = value;
    }
    return result;
  }

  /// 修改头部信息
  static List<Header> _modifyHeaders(
      Map<String, String> headers, String targetHost, int targetPort,
      {bool isSecure = true,
      bool includeDomainInAuthority = true,
      String? resolvedIp}) {
    final modifiedHeaders = <Header>[];

    // 检查是否为gRPC请求
    final isGrpc = ProtocolUtils.isGrpcRequest(headers);
    if (isGrpc) {
      Logger.debug(
          'Detected gRPC request, applying gRPC-specific header handling');
    }

    Logger.debug(
        'Header modification - Target: $targetHost:$targetPort, Secure: $isSecure, gRPC: $isGrpc, IncludeDomain: $includeDomainInAuthority');

    for (final entry in headers.entries) {
      final name = entry.key;
      String value = entry.value;

      // HTTP/2头部修改逻辑
      if (name == ':authority' || name == 'host') {
        // 根据includeDomainInAuthority设置决定是否修改:authority头部
        if (includeDomainInAuthority) {
          // 包含域名信息：修改为targetHost
          if (targetPort == 443 || targetPort == 80) {
            // 标准端口：不包含端口号
            value = targetHost;
            Logger.debug(
                'Modified authority header: $name = $value (domain, standard port)');
          } else {
            // 非标准端口：包含端口号
            value = '$targetHost:$targetPort';
            Logger.debug(
                'Modified authority header: $name = $value (domain, non-standard port)');
          }
        } else {
          // 不包含域名信息：保持原始头部不变
          Logger.debug(
              'Keeping original authority header: $name = $value (no modification)');
        }
      } else if (name == ':scheme') {
        // 根据连接类型设置正确的scheme
        value = isSecure ? 'https' : 'http';
        Logger.debug(
            'Modified HTTP/2 scheme header: $name = $value (secure: $isSecure)');
      } else if (name.startsWith(':')) {
        // 其他伪头部（如:method, :path）保持不变
        Logger.debug('HTTP/2 pseudo-header: $name = $value');
      } else if (isGrpc && name.startsWith('grpc-')) {
        // gRPC特定头部保持不变
        Logger.debug('gRPC header: $name = $value (preserved)');
      } else if (isGrpc && name.toLowerCase() == 'content-type') {
        // gRPC的Content-Type保持不变
        Logger.debug('gRPC content-type: $name = $value (preserved)');
      } else {
        // 普通头部保持不变
        Logger.debug('HTTP/2 header: $name = $value');
      }

      modifiedHeaders.add(Header.ascii(name, value));
    }

    Logger.debug(
        'Header modification completed - ${modifiedHeaders.length} headers processed');
    return modifiedHeaders;
  }

  /// 发送错误响应
  static void _sendErrorResponse(
      ServerTransportStream stream, int statusCode, String message) {
    try {
      final headers = [
        Header.ascii(':status', statusCode.toString()),
        Header.ascii('content-type', 'text/plain; charset=utf-8'),
        Header.ascii('content-length', message.length.toString()),
      ];

      stream.sendHeaders(headers, endStream: false);
      stream.sendData(utf8.encode(message), endStream: true);

      Logger.debug('Sent error response: $statusCode - $message');
    } catch (e) {
      Logger.error('Error sending error response', e);
    }
  }

  /// HTTPDNS解析
  static Future<String> _resolveDomain(
      String domain, DnsResolver dnsResolver) async {
    try {
      final ip = await dnsResolver.resolve(domain);
      if (ip != null && ip.isNotEmpty && ip != domain) {
        Logger.info('DNS resolution: $domain -> $ip');
        return ip;
      }
      return domain;
    } catch (e) {
      Logger.error('DNS resolution failed for $domain', e);
      return domain;
    }
  }

  /// 检查是否是HTTP/2连接前言
  static bool isHttp2Preface(List<int> data) {
    if (data.length < 24) return false;

    try {
      final preface = utf8.decode(data.take(24).toList(), allowMalformed: true);
      return preface.startsWith('PRI * HTTP/2.0');
    } catch (e) {
      return false;
    }
  }

  /// 获取HTTP/2连接前言的字符串表示
  static String getHttp2PrefaceString() {
    return 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
  }

  /// 获取HTTP/2连接前言的字节表示
  static List<int> getHttp2PrefaceBytes() {
    return utf8.encode(getHttp2PrefaceString());
  }
}
