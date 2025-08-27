#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';

/// 连接协议测试器
/// 测试HTTP/2和原始TCP连接到指定服务器
class ConnectionProtocolTester {
  static const String targetHost = 'api.example.com';
  static const int targetPort = 7349;
  
  /// 测试原始TCP连接
  static Future<void> testRawTcp() async {
    print('\n🔗 测试原始TCP连接');
    print('=' * 50);
    
    try {
      print('📡 尝试TCP连接到 $targetHost:$targetPort');
      
      final socket = await Socket.connect(targetHost, targetPort)
          .timeout(const Duration(seconds: 10));
      
      print('✅ TCP连接建立成功');
      print('   本地地址: ${socket.address}:${socket.port}');
      print('   远程地址: ${socket.remoteAddress}:${socket.remotePort}');
      
      // 发送一些测试数据
      final testData = [
        'GET / HTTP/1.1\r\nHost: $targetHost:$targetPort\r\n\r\n',
        'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n',
        'Hello Server!\n',
      ];
      
      for (final data in testData) {
        try {
          print('\n📤 发送数据: ${data.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
          
          // 为每个测试创建新的连接
          final testSocket = await Socket.connect(targetHost, targetPort)
              .timeout(const Duration(seconds: 10));
          
          testSocket.write(data);
          await Future.delayed(const Duration(milliseconds: 500));
          
          // 尝试读取响应
          final response = await testSocket.timeout(const Duration(seconds: 2)).first;
          final responseString = utf8.decode(response);
          print('✅ 收到响应: ${responseString.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
          
          testSocket.destroy();
          
        } catch (e) {
          print('❌ 数据发送/接收失败: $e');
        }
      }
      
      socket.destroy();
      
    } catch (e) {
      print('❌ TCP连接测试失败');
      print('   错误: $e');
    }
  }
  
  /// 测试HTTP/2连接（参考http2_handler.dart的实现）
  static Future<void> testHttp2() async {
    print('\n🔗 测试 HTTP/2 连接');
    print('=' * 50);
    
    try {
      print('📡 尝试连接到 $targetHost:$targetPort (HTTP/2)');
      
      // 建立到目标服务器的连接
      final targetSocket = await Socket.connect(targetHost, targetPort,
          timeout: const Duration(seconds: 10));
      
      print('✅ TCP连接建立成功');
      
      // 创建HTTP/2客户端传输连接（h2c - HTTP/2 over cleartext）
      final clientTransport = ClientTransportConnection.viaSocket(targetSocket);
      print('✅ HTTP/2传输连接创建成功');
      
      // 等待连接建立
      await Future.delayed(const Duration(seconds: 1));
      
      // 尝试发送HTTP/2请求
      try {
        print('📤 发送HTTP/2 GET请求');
        
        final stream = clientTransport.makeRequest(
          [
            Header.ascii(':method', 'GET'),
            Header.ascii(':path', '/'),
            Header.ascii(':scheme', 'http'),
            Header.ascii(':authority', '$targetHost:$targetPort'),
            Header.ascii('user-agent', 'ConnectionProtocolTester/1.0'),
            Header.ascii('accept', '*/*'),
          ],
          endStream: true,
        );
        
        // 监听响应
        stream.incomingMessages.listen(
          (message) {
            if (message is HeadersStreamMessage) {
              print('✅ HTTP/2 响应头收到');
              print('   头部: ${message.headers}');
              
              // 解析头部
              final headers = _parseHeaders(message.headers);
              for (final entry in headers.entries) {
                print('     ${entry.key}: ${entry.value}');
              }
            } else if (message is DataStreamMessage) {
              print('✅ HTTP/2 响应数据收到');
              print('   数据长度: ${message.bytes.length} 字节');
              if (message.bytes.isNotEmpty) {
                final dataString = String.fromCharCodes(message.bytes);
                print('   数据预览: ${dataString.length > 200 ? dataString.substring(0, 200) + '...' : dataString}');
              }
            }
          },
          onError: (error) {
            print('❌ HTTP/2 流错误: $error');
          },
          onDone: () {
            print('✅ HTTP/2 流完成');
          },
        );
        
        // 等待响应
        await Future.delayed(const Duration(seconds: 5));
        
      } catch (e) {
        print('❌ HTTP/2 请求失败: $e');
      }
      
      // 清理连接
      await clientTransport.finish();
      targetSocket.destroy();
      
    } catch (e) {
      print('❌ HTTP/2 连接测试失败');
      print('   错误: $e');
    }
  }
  
  /// 测试HTTP/2连接（简化版本）
  static Future<void> testHttp2Simple() async {
    print('\n🔗 测试 HTTP/2 连接（简化版本）');
    print('=' * 50);
    
    try {
      print('📡 尝试连接到 $targetHost:$targetPort (HTTP/2)');
      
      // 建立TCP连接
      final socket = await Socket.connect(targetHost, targetPort)
          .timeout(const Duration(seconds: 10));
      
      print('✅ TCP连接建立成功');
      
      // 发送HTTP/2连接前言
      final connectionPreface = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
      print('📤 发送HTTP/2连接前言: ${connectionPreface.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
      
      socket.write(connectionPreface);
      
      // 等待响应
      await Future.delayed(const Duration(seconds: 2));
      
      // 尝试读取响应
      try {
        final response = await socket.timeout(const Duration(seconds: 5)).first;
        final responseString = utf8.decode(response);
        print('✅ 收到HTTP/2响应: ${responseString.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
      } catch (e) {
        print('❌ 读取HTTP/2响应失败: $e');
      }
      
      socket.destroy();
      
    } catch (e) {
      print('❌ HTTP/2 连接测试失败');
      print('   错误: $e');
    }
  }
  
  /// 测试gRPC风格的连接
  static Future<void> testGrpcStyle() async {
    print('\n🔗 测试 gRPC 风格连接');
    print('=' * 50);
    
    try {
      print('📡 尝试连接到 $targetHost:$targetPort (gRPC风格)');
      
      // 建立到目标服务器的连接
      final targetSocket = await Socket.connect(targetHost, targetPort,
          timeout: const Duration(seconds: 10));
      
      print('✅ TCP连接建立成功');
      
      // 创建HTTP/2客户端传输连接
      final clientTransport = ClientTransportConnection.viaSocket(targetSocket);
      print('✅ HTTP/2传输连接创建成功');
      
      // 等待连接建立
      await Future.delayed(const Duration(seconds: 1));
      
      // 尝试发送gRPC风格的请求
      try {
        print('📤 发送gRPC风格请求');
        
        final stream = clientTransport.makeRequest(
          [
            Header.ascii(':method', 'POST'),
            Header.ascii(':path', '/grpc.health.v1.Health/Check'),
            Header.ascii(':scheme', 'http'),
            Header.ascii(':authority', '$targetHost:$targetPort'),
            Header.ascii('content-type', 'application/grpc'),
            Header.ascii('user-agent', 'ConnectionProtocolTester/1.0'),
            Header.ascii('te', 'trailers'),
          ],
          endStream: false,
        );
        
        // 发送gRPC消息体（空的健康检查请求）
        final grpcMessage = [
          0x00, // 压缩标志
          0x00, 0x00, 0x00, 0x00, // 消息长度（0字节）
        ];
        
        stream.sendData(grpcMessage, endStream: true);
        print('📤 发送gRPC消息体: ${grpcMessage.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
        
        // 监听响应
        stream.incomingMessages.listen(
          (message) {
            if (message is HeadersStreamMessage) {
              print('✅ gRPC 响应头收到');
              print('   头部: ${message.headers}');
              
              // 解析头部
              final headers = _parseHeaders(message.headers);
              for (final entry in headers.entries) {
                print('     ${entry.key}: ${entry.value}');
              }
            } else if (message is DataStreamMessage) {
              print('✅ gRPC 响应数据收到');
              print('   数据长度: ${message.bytes.length} 字节');
              if (message.bytes.isNotEmpty) {
                print('   数据: ${message.bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
              }
            }
          },
          onError: (error) {
            print('❌ gRPC 流错误: $error');
          },
          onDone: () {
            print('✅ gRPC 流完成');
          },
        );
        
        // 等待响应
        await Future.delayed(const Duration(seconds: 5));
        
      } catch (e) {
        print('❌ gRPC 请求失败: $e');
      }
      
      // 清理连接
      await clientTransport.finish();
      targetSocket.destroy();
      
    } catch (e) {
      print('❌ gRPC风格连接测试失败');
      print('   错误: $e');
    }
  }
  
  /// 测试服务器信息
  static Future<void> testServerInfo() async {
    print('\n🔗 测试服务器信息');
    print('=' * 50);
    
    try {
      print('📡 尝试获取 $targetHost:$targetPort 的服务器信息');
      
      // 尝试DNS解析
      try {
        final addresses = await InternetAddress.lookup(targetHost);
        print('✅ DNS解析成功:');
        for (final address in addresses) {
          print('   ${address.address} (${address.type.name})');
        }
      } catch (e) {
        print('❌ DNS解析失败: $e');
      }
      
      // 尝试端口扫描
      final commonPorts = [7349, 7350, 80, 443, 8080, 8443];
      
      for (final port in commonPorts) {
        try {
          final socket = await Socket.connect(targetHost, port)
              .timeout(const Duration(seconds: 3));
          
          print('✅ 端口 $port 开放');
          socket.destroy();
          
        } catch (e) {
          print('❌ 端口 $port 关闭或超时');
        }
      }
      
    } catch (e) {
      print('❌ 服务器信息测试失败');
      print('   错误: $e');
    }
  }
  
  /// 解析头部信息（参考http2_handler.dart）
  static Map<String, String> _parseHeaders(List<Header> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final name = utf8.decode(header.name);
      final value = utf8.decode(header.value);
      result[name] = value;
    }
    return result;
  }
  
  /// 运行所有测试
  static Future<void> runAllTests() async {
    print('🚀 开始连接协议测试');
    print('目标服务器: $targetHost:$targetPort');
    print('=' * 60);
    
    // 测试服务器信息
    await testServerInfo();
    
    // 测试原始TCP连接
    await testRawTcp();
    
    // 测试HTTP/2（简化版本）
    await testHttp2Simple();
    
    // 测试HTTP/2（完整版本）
    await testHttp2();
    
    // 测试gRPC风格连接
    await testGrpcStyle();
    
    print('\n🎉 所有测试完成！');
  }
}

/// 主函数
void main() async {
  try {
    await ConnectionProtocolTester.runAllTests();
  } catch (e) {
    print('❌ 测试过程中发生错误: $e');
    exit(1);
  }
}
