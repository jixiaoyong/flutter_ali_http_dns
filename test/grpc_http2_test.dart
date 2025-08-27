import 'dart:io';
import 'dart:convert';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';

/// gRPC HTTP/2测试脚本
/// 专门用于测试gRPC请求的域名信息传递
class GrpcHttp2Test {
  
  /// 测试gRPC HTTP/2连接
  static Future<void> testGrpcHttp2Connection() async {
    print('=== 开始gRPC HTTP/2连接测试 ===');
    
    try {
      // 连接到目标服务器
      print('正在连接到目标服务器: 198.1.1.1:7349');
      final socket = await Socket.connect('198.1.1.1', 7349);
      print('✅ 连接成功建立');
      
      // 创建HTTP/2客户端传输连接
      final transport = ClientTransportConnection.viaSocket(socket);
      print('✅ HTTP/2传输连接创建成功');
      
      // 创建gRPC请求头部
      final headers = [
        Header.ascii(':method', 'POST'),
        Header.ascii(':path', '/grpc.testing.TestService/UnaryCall'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', 'api.example.com'), // 原始域名
        Header.ascii('content-type', 'application/grpc'),
        Header.ascii('user-agent', 'GrpcHttp2Test/1.0'),
        Header.ascii('grpc-timeout', '10S'),
        Header.ascii('grpc-encoding', 'gzip'),
        Header.ascii('grpc-accept-encoding', 'gzip,deflate'),
      ];
      
      print('📤 发送gRPC HTTP/2请求');
      print('   原始域名: api.example.com');
      print('   目标IP: 198.1.1.1');
      print('   请求路径: /grpc.testing.TestService/UnaryCall');
      print('   请求头部:');
      for (final header in headers) {
        final name = utf8.decode(header.name);
        final value = utf8.decode(header.value);
        print('     $name: $value');
      }
      
      // 发送请求头部
      final stream = transport.makeRequest(headers, endStream: false);
      
      // 发送gRPC数据（简单的测试数据）
      final grpcData = _createGrpcData('{"test": "hello world"}');
      stream.sendData(grpcData, endStream: true);
      print('📤 发送gRPC数据: ${grpcData.length} 字节');
      
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
            if (message.bytes.isNotEmpty) {
              try {
                final grpcResponse = _parseGrpcData(message.bytes);
                print('   gRPC响应内容: $grpcResponse');
              } catch (e) {
                print('   原始数据: ${message.bytes}');
              }
            }
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
      print('❌ gRPC HTTP/2连接测试失败: $e');
    }
    
    print('=== gRPC HTTP/2连接测试完成 ===');
  }
  
  /// 创建gRPC数据格式
  static List<int> _createGrpcData(String jsonData) {
    final data = utf8.encode(jsonData);
    final length = data.length;
    
    // gRPC数据格式: [压缩标志(1字节)] + [长度(4字节)] + [数据]
    final grpcData = <int>[];
    grpcData.add(0); // 不压缩
    grpcData.addAll([
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);
    grpcData.addAll(data);
    
    return grpcData;
  }
  
  /// 解析gRPC数据格式
  static String _parseGrpcData(List<int> data) {
    if (data.length < 5) {
      throw FormatException('gRPC数据格式错误');
    }
    
    final compressed = data[0];
    final length = (data[1] << 24) | (data[2] << 16) | (data[3] << 8) | data[4];
    
    if (data.length < 5 + length) {
      throw FormatException('gRPC数据长度不匹配');
    }
    
    final messageData = data.sublist(5, 5 + length);
    return utf8.decode(messageData, allowMalformed: true);
  }
  
  /// 测试域名信息传递验证
  static void testDomainInfoPreservation() {
    print('=== 测试域名信息传递验证 ===');
    
    final originalDomain = 'api.example.com';
    final targetIp = '198.1.1.1';
    
    print('原始域名: $originalDomain');
    print('目标IP: $targetIp');
    print('验证点:');
    print('  1. 连接层面使用IP地址: $targetIp');
    print('  2. HTTP/2头部保持原始域名: $originalDomain');
    print('  3. 目标服务器能通过:authority头部获取原始域名');
    
    // 模拟头部处理
    final headers = {
      ':authority': originalDomain,
      ':method': 'POST',
      ':path': '/test',
      ':scheme': 'https',
      'content-type': 'application/grpc',
    };
    
    print('模拟头部处理结果:');
    for (final entry in headers.entries) {
      final name = entry.key;
      final value = entry.value;
      
      if (name == ':authority' || name == 'host') {
        print('  ✅ $name: $value (保持原值)');
      } else {
        print('  📝 $name: $value');
      }
    }
    
    print('=== 域名信息传递验证完成 ===');
  }
}

/// 主函数
void main() async {
  print('🚀 gRPC HTTP/2测试脚本启动');
  
  // 测试域名信息传递验证
  GrpcHttp2Test.testDomainInfoPreservation();
  
  // 测试gRPC HTTP/2连接
  await GrpcHttp2Test.testGrpcHttp2Connection();
  
  print('🎉 gRPC HTTP/2测试脚本完成');
}
