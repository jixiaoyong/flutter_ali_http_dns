import 'dart:io';
import 'dart:convert';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';

/// 简单的HTTP/2测试脚本
/// 专门用于测试域名信息传递
class SimpleHttp2Test {
  
  /// 测试HTTP/2连接和域名信息传递
  static Future<void> testHttp2Connection() async {
    print('=== 开始HTTP/2连接测试 ===');
    
    try {
      // 连接到目标服务器
      print('正在连接到目标服务器: 198.1.1.1:7349');
      final socket = await Socket.connect('198.1.1.1', 7349);
      print('✅ 连接成功建立');
      
      // 创建HTTP/2客户端传输连接
      final transport = ClientTransportConnection.viaSocket(socket);
      print('✅ HTTP/2传输连接创建成功');
      
      // 创建请求头部，包含原始域名信息
      final headers = [
        Header.ascii(':method', 'GET'),
        Header.ascii(':path', '/'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', 'api.example.com'), // 原始域名
        Header.ascii('user-agent', 'Http2Test/1.0'),
        Header.ascii('accept', '*/*'),
      ];
      
      print('📤 发送HTTP/2请求');
      print('   原始域名: api.example.com');
      print('   目标IP: 198.1.1.1');
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
            print('📥 收到响应数据:');
            print('   长度: ${data.length} 字符');
            print('   内容: $data');
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
      await Future.delayed(Duration(seconds: 10));
      
      // 关闭连接
      await transport.finish();
      await socket.close();
      print('✅ 连接已关闭');
      
    } catch (e) {
      print('❌ HTTP/2连接测试失败: $e');
    }
    
    print('=== HTTP/2连接测试完成 ===');
  }
  
  /// 测试HTTP/2前言检测
  static void testHttp2Preface() {
    print('=== 测试HTTP/2前言检测 ===');
    
    final preface = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
    final prefaceBytes = utf8.encode(preface);
    
    print('HTTP/2前言: $preface');
    print('前言字节长度: ${prefaceBytes.length}');
    print('前言检测结果: ${_isHttp2Preface(prefaceBytes)}');
    
    // 测试非HTTP/2数据
    final nonHttp2Data = utf8.encode('GET / HTTP/1.1\r\nHost: example.com\r\n\r\n');
    print('非HTTP/2数据检测结果: ${_isHttp2Preface(nonHttp2Data)}');
    
    print('=== HTTP/2前言检测完成 ===');
  }
  
  /// 检测是否为HTTP/2前言
  static bool _isHttp2Preface(List<int> data) {
    if (data.length < 24) return false;
    
    try {
      final preface = utf8.decode(data.take(24).toList(), allowMalformed: true);
      return preface.startsWith('PRI * HTTP/2.0');
    } catch (e) {
      return false;
    }
  }
}

/// 主函数
void main() async {
  print('🚀 HTTP/2测试脚本启动');
  
  // 测试HTTP/2前言检测
  SimpleHttp2Test.testHttp2Preface();
  
  // 测试HTTP/2连接
  await SimpleHttp2Test.testHttp2Connection();
  
  print('�� HTTP/2测试脚本完成');
}
