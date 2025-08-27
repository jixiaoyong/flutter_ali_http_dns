
import 'dart:convert';
import 'package:http2/transport.dart';

/// 协议类型枚举
enum ProtocolType {
  http,
  https,
  http2,
  grpc,  // 新增gRPC协议类型
  websocket,
  unknown,
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

  /// 检测HTTP/2请求是否为gRPC请求（从原始头部列表）
  static bool isGrpcRequestFromHeaders(List<Header> headers) {
    for (final header in headers) {
      final name = utf8.decode(header.name).toLowerCase();
      if (name == 'content-type') {
        final value = utf8.decode(header.value).toLowerCase();
        return value.startsWith('application/grpc');
      }
    }
    return false;
  }

  /// 获取gRPC特定的头部信息
  static Map<String, String> extractGrpcHeaders(Map<String, String> headers) {
    final grpcHeaders = <String, String>{};
    
    for (final entry in headers.entries) {
      final name = entry.key.toLowerCase();
      if (name.startsWith('grpc-')) {
        grpcHeaders[entry.key] = entry.value;
      }
    }
    
    return grpcHeaders;
  }

  /// 检测是否是WebSocket握手请求
  static bool isWebSocketHandshake(String requestString) {
    final lines = requestString.split('\r\n');
    bool hasUpgrade = false;
    bool hasWebSocket = false;
    
    for (final line in lines) {
      if (line.toLowerCase().startsWith('upgrade:') && line.toLowerCase().contains('websocket')) {
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

  /// 从HTTP请求中提取Host信息
  static Map<String, String> extractHostInfo(String requestString) {
    final lines = requestString.split('\r\n');
    String? host;
    int port = 80; // 默认端口
    
    for (final line in lines) {
      if (line.toLowerCase().startsWith('host:')) {
        final hostValue = line.substring(6).trim();
        final colonIndex = hostValue.indexOf(':');
        if (colonIndex > 0) {
          host = hostValue.substring(0, colonIndex);
          port = int.tryParse(hostValue.substring(colonIndex + 1)) ?? 80;
        } else {
          host = hostValue;
        }
        break;
      }
    }
    
    return {
      'host': host ?? '',
      'port': port.toString(),
    };
  }

  /// 从CONNECT请求中提取目标信息
  static Map<String, String> extractConnectInfo(String requestString) {
    final firstLine = requestString.split('\n').first.trim();
    final connectMatch = RegExp(r'CONNECT ([^ :]+):(\d+)').firstMatch(firstLine);
    
    if (connectMatch != null) {
      return {
        'host': connectMatch.group(1)!,
        'port': connectMatch.group(2)!,
      };
    }
    
    return {
      'host': '',
      'port': '443',
    };
  }

  /// 从HTTP请求中提取URL信息
  static Map<String, String> extractHttpInfo(String requestString) {
    final firstLine = requestString.split('\n').first.trim();
    final httpMatch = RegExp(r'^([A-Z]+) ([^ ]+) HTTP/').firstMatch(firstLine);
    
    if (httpMatch != null) {
      final method = httpMatch.group(1)!;
      final url = httpMatch.group(2)!;
      
      // 解析 URL
      final uri = Uri.parse(url.startsWith('http') ? url : 'http://$url');
      final host = uri.host;
      final port = uri.port > 0 ? uri.port : 80;
      
      return {
        'method': method,
        'url': url,
        'host': host,
        'port': port.toString(),
      };
    }
    
    return {
      'method': '',
      'url': '',
      'host': '',
      'port': '80',
    };
  }

  /// 检查是否是HTTP/2连接前言
  static bool isHttp2Preface(List<int> data) {
    if (data.length < 24) {
      return false;
    }
    
    try {
      final preface = String.fromCharCodes(data.take(24));
      return preface.startsWith('PRI * HTTP/2.0');
    } catch (e) {
      return false;
    }
  }

  /// 获取协议类型的描述
  static String getProtocolDescription(ProtocolType type) {
    switch (type) {
      case ProtocolType.http:
        return 'HTTP/1.x';
      case ProtocolType.https:
        return 'HTTPS (CONNECT)';
      case ProtocolType.http2:
        return 'HTTP/2';
      case ProtocolType.grpc:
        return 'gRPC (HTTP/2)';
      case ProtocolType.websocket:
        return 'WebSocket';
      case ProtocolType.unknown:
        return 'Unknown';
    }
  }
}
