import 'dart:io';
import 'dart:convert';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/utils/protocol_utils.dart';
import '../lib/src/utils/logger.dart';

/// HTTP/2 集成测试
/// 测试 HTTP/2 连接、gRPC 请求和域名信息传递
class Http2IntegrationTest {
  static const String _testDomain = 'api.example.com';
  static const String _testIp = '198.1.1.1';
  static const int _testPort = 7349;

  /// 运行所有 HTTP/2 测试
  static Future<void> runAllTests() async {
    print('🚀 HTTP/2 集成测试启动');
    
    // 测试协议检测
    testProtocolDetection();
    
    // 测试 HTTP/2 连接
    await testHttp2Connection();
    
    // 测试 gRPC HTTP/2 连接
    await testGrpcHttp2Connection();
    
    print('🎉 HTTP/2 集成测试完成');
  }

  /// 测试协议检测功能
  static void testProtocolDetection() {
    print('=== 测试协议检测 ===');
    
    // 测试 HTTP/2 前言检测
    final http2Preface = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
    final http2PrefaceBytes = utf8.encode(http2Preface);
    
    print('HTTP/2前言: $http2Preface');
    print('前言字节长度: ${http2PrefaceBytes.length}');
    
    // 测试协议检测
    final protocolType = ProtocolUtils.detectProtocol(http2Preface);
    print('协议检测结果: $protocolType');
    
    // 测试非 HTTP/2 数据
    final nonHttp2Data = 'GET / HTTP/1.1\r\nHost: example.com\r\n\r\n';
    final nonHttp2Protocol = ProtocolUtils.detectProtocol(nonHttp2Data);
    print('非HTTP/2数据检测结果: $nonHttp2Protocol');
    
    print('=== 协议检测完成 ===');
  }

  /// 测试 HTTP/2 连接
  static Future<void> testHttp2Connection() async {
    print('=== 开始 HTTP/2 连接测试 ===');
    
    try {
      // 连接到目标服务器
      print('正在连接到目标服务器: $_testIp:$_testPort');
      final socket = await Socket.connect(_testIp, _testPort);
      print('✅ 连接成功建立');
      
      // 创建 HTTP/2 客户端传输连接
      final transport = ClientTransportConnection.viaSocket(socket);
      print('✅ HTTP/2 传输连接创建成功');
      
      // 创建请求头部，包含原始域名信息
      final headers = [
        Header.ascii(':method', 'GET'),
        Header.ascii(':path', '/'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', _testDomain), // 原始域名
        Header.ascii('user-agent', 'Http2Test/1.0'),
        Header.ascii('accept', '*/*'),
      ];
      
      print('📤 发送 HTTP/2 请求');
      print('   原始域名: $_testDomain');
      print('   目标IP: $_testIp');
      print('   请求头部:');
      for (final header in headers) {
        final name = utf8.decode(header.name);
        final value = utf8.decode(header.value);
        print('     $name: $value');
      }
      
      // 发送请求
      final stream = transport.makeRequest(headers, endStream: true);
      
      // 监听响应
      stream.incomingMessages.listen(
        (message) {
          if (message is HeadersStreamMessage) {
            print('📥 收到响应头部:');
            for (final header in message.headers) {
              final name = utf8.decode(header.name);
              final value = utf8.decode(header.value);
              print('     $name: $value');
            }
          } else if (message is DataStreamMessage) {
            final data = utf8.decode(message.bytes, allowMalformed: true);
            print('📥 收到响应数据: ${data.length} 字符');
          }
        },
        onError: (error) {
          print('❌ 接收响应时出错: $error');
        },
        onDone: () {
          print('✅ 响应接收完成');
        },
      );
      
      // 等待响应
      print('⏳ 等待服务器响应...');
      await Future.delayed(Duration(seconds: 5));
      
      // 关闭连接
      await transport.finish();
      await socket.close();
      print('✅ 连接已关闭');
      
    } catch (e) {
      print('❌ HTTP/2 连接测试失败: $e');
    }
    
    print('=== HTTP/2 连接测试完成 ===');
  }

  /// 测试 gRPC HTTP/2 连接
  static Future<void> testGrpcHttp2Connection() async {
    print('=== 开始 gRPC HTTP/2 连接测试 ===');
    
    try {
      // 连接到目标服务器
      print('正在连接到目标服务器: $_testIp:$_testPort');
      final socket = await Socket.connect(_testIp, _testPort);
      print('✅ 连接成功建立');
      
      // 创建 HTTP/2 客户端传输连接
      final transport = ClientTransportConnection.viaSocket(socket);
      print('✅ HTTP/2 传输连接创建成功');
      
      // 创建 gRPC 请求头部
      final headers = [
        Header.ascii(':method', 'POST'),
        Header.ascii(':path', '/grpc.testing.TestService/UnaryCall'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', _testDomain), // 原始域名
        Header.ascii('content-type', 'application/grpc'),
        Header.ascii('user-agent', 'GrpcHttp2Test/1.0'),
        Header.ascii('grpc-timeout', '10S'),
        Header.ascii('grpc-encoding', 'gzip'),
        Header.ascii('grpc-accept-encoding', 'gzip,deflate'),
      ];
      
      print('📤 发送 gRPC HTTP/2 请求');
      print('   原始域名: $_testDomain');
      print('   目标IP: $_testIp');
      print('   请求路径: /grpc.testing.TestService/UnaryCall');
      print('   请求头部:');
      for (final header in headers) {
        final name = utf8.decode(header.name);
        final value = utf8.decode(header.value);
        print('     $name: $value');
      }
      
      // 发送请求头部
      final stream = transport.makeRequest(headers, endStream: false);
      
      // 发送 gRPC 数据（简单的测试数据）
      final grpcData = _createGrpcData('{"test": "hello world"}');
      stream.sendData(grpcData, endStream: true);
      print('📤 发送 gRPC 数据: ${grpcData.length} 字节');
      
      // 监听响应
      stream.incomingMessages.listen(
        (message) {
          if (message is HeadersStreamMessage) {
            print('📥 收到响应头部:');
            for (final header in message.headers) {
              final name = utf8.decode(header.name);
              final value = utf8.decode(header.value);
              print('     $name: $value');
            }
          } else if (message is DataStreamMessage) {
            print('📥 收到响应数据: ${message.bytes.length} 字节');
          }
        },
        onError: (error) {
          print('❌ 接收响应时出错: $error');
        },
        onDone: () {
          print('✅ 响应接收完成');
        },
      );
      
      // 等待响应
      print('⏳ 等待服务器响应...');
      await Future.delayed(Duration(seconds: 5));
      
      // 关闭连接
      await transport.finish();
      await socket.close();
      print('✅ 连接已关闭');
      
    } catch (e) {
      print('❌ gRPC HTTP/2 连接测试失败: $e');
    }
    
    print('=== gRPC HTTP/2 连接测试完成 ===');
  }

  /// 创建 gRPC 数据帧
  static List<int> _createGrpcData(String jsonData) {
    final data = utf8.encode(jsonData);
    final length = data.length;
    
    // gRPC 数据帧格式: [1 byte flag][4 bytes length][data]
    final frame = <int>[
      0, // flag (0 = data frame)
      (length >> 24) & 0xFF, // length (big-endian)
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
      ...data, // 实际数据
    ];
    
    return frame;
  }

  /// 解析 gRPC 数据帧
  static String _parseGrpcData(List<int> bytes) {
    if (bytes.length < 5) {
      throw FormatException('Invalid gRPC frame: too short');
    }
    
    // 跳过帧头 (1 byte flag + 4 bytes length)
    final data = bytes.sublist(5);
    return utf8.decode(data, allowMalformed: true);
  }
}

/// 测试入口
void main() {
  test('HTTP/2 Integration Tests', () async {
    await Http2IntegrationTest.runAllTests();
  });
}
