/// 协议类型枚举
enum ProtocolType {
  http,
  https,
  http2,
  grpc,
  websocket,
  unknown;

  String get desc => switch (this) {
        ProtocolType.http => 'HTTP/1.x',
        ProtocolType.https => 'HTTPS (CONNECT)',
        ProtocolType.http2 => 'HTTP/2',
        ProtocolType.grpc => 'gRPC (HTTP/2)',
        ProtocolType.websocket => 'WebSocket',
        ProtocolType.unknown => 'Unknown',
      };
}

/// 协议检测相关的工具类
class ProtocolUtils {
  /// 智能协议检测
  static ProtocolType detectProtocol(String requestString) {
    final firstLine = requestString.split('\n').first.trim();

    // 1. 检测HTTP/2连接前言
    if (firstLine.startsWith('PRI * HTTP/2.0')) {
      return ProtocolType.http2;
    }

    // 2. 检测WebSocket握手
    if (_isWebSocketHandshake(requestString)) {
      return ProtocolType.websocket;
    }

    // 3. 检测HTTPS CONNECT
    if (firstLine.startsWith('CONNECT ')) {
      return ProtocolType.https;
    }

    // 4. 检测HTTP/1.x
    if (RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').hasMatch(firstLine)) {
      return ProtocolType.http;
    }

    return ProtocolType.unknown;
  }

  /// 检测HTTP/2请求是否为gRPC请求
  static bool isGrpcRequest(Map<String, String> headers) {
    // 检查Content-Type是否为application/grpc
    final contentType = headers['content-type']?.toLowerCase() ?? '';
    return contentType.startsWith('application/grpc');
  }

  /// 检测是否是WebSocket握手请求
  static bool isWebSocketHandshake(String requestString) {
    final lines = requestString.split('\r\n');
    bool hasUpgrade = false;
    bool hasWebSocket = false;

    for (final line in lines) {
      if (line.toLowerCase().startsWith('upgrade:') &&
          line.toLowerCase().contains('websocket')) {
        hasUpgrade = true;
      }
      if (line.toLowerCase().startsWith('sec-websocket-')) {
        hasWebSocket = true;
      }
    }

    return hasUpgrade && hasWebSocket;
  }

  /// 内部方法：检测WebSocket握手
  static bool _isWebSocketHandshake(String requestString) {
    return isWebSocketHandshake(requestString);
  }
}
