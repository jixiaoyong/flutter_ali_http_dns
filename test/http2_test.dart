import 'dart:io';
import 'dart:convert';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';
import '../lib/src/utils/http2_handler.dart';
import '../lib/src/models/port_mapping.dart';
import '../lib/src/models/dns_config.dart';
import '../lib/src/services/dns_resolver.dart';
import '../lib/src/utils/logger.dart';

/// HTTP/2测试脚本
/// 用于测试HTTP/2连接处理和域名信息传递
class Http2Test {
  static const int _testPort = 8080;
  static const String _testDomain = 'api.example.com';
  static const String _testIp = '198.1.1.1';
  static const int _testTargetPort = 7349;

  /// 运行HTTP/2测试
  static Future<void> runTest() async {
    Logger.info('开始HTTP/2测试...');
    
    try {
      // 1. 启动测试服务器
      final server = await _startTestServer();
      Logger.info('测试服务器启动在端口 $_testPort');
      
      // 2. 创建DNS解析器
      final dnsResolver = _createMockDnsResolver();
      
      // 3. 创建端口映射
      final mapping = PortMapping(
        localPort: _testPort,
        targetPort: _testTargetPort,
        targetDomain: _testDomain,
        createdAt: DateTime.now(),
      );
      
      // 4. 模拟HTTP/2客户端连接
      await _simulateHttp2Client(server, mapping, dnsResolver);
      
      // 5. 清理
      await server.close();
      Logger.info('HTTP/2测试完成');
      
    } catch (e) {
      Logger.error('HTTP/2测试失败', e);
    }
  }

  /// 启动测试服务器
  static Future<ServerSocket> _startTestServer() async {
    return await ServerSocket.bind('localhost', _testPort);
  }

  /// 创建模拟DNS解析器
  static DnsResolver _createMockDnsResolver() {
    return MockDnsResolver();
  }

  /// 模拟HTTP/2客户端连接
  static Future<void> _simulateHttp2Client(
    ServerSocket server,
    PortMapping mapping,
    DnsResolver dnsResolver,
  ) async {
    // 等待客户端连接
    server.listen((Socket clientSocket) async {
      Logger.info('收到客户端连接: ${clientSocket.remoteAddress}:${clientSocket.remotePort}');
      
      try {
        // 处理HTTP/2连接
        final success = await Http2Handler.handleHttp2Connection(
          clientSocket,
          mapping,
          dnsResolver,
        );
        
        if (success) {
          Logger.info('HTTP/2连接处理成功');
        } else {
          Logger.error('HTTP/2连接处理失败');
        }
        
      } catch (e) {
        Logger.error('处理客户端连接时出错', e);
      }
    });
    
    // 等待一段时间让服务器启动
    await Future.delayed(Duration(milliseconds: 100));
    
    // 创建客户端连接
    final clientSocket = await Socket.connect('localhost', _testPort);
    Logger.info('客户端连接到测试服务器');
    
    // 发送HTTP/2前言
    final preface = Http2Handler.getHttp2PrefaceBytes();
    clientSocket.add(preface);
    Logger.info('发送HTTP/2前言');
    
    // 等待连接建立
    await Future.delayed(Duration(milliseconds: 500));
    
    // 关闭客户端连接
    await clientSocket.close();
    Logger.info('客户端连接已关闭');
  }
}

/// 模拟DNS解析器
class MockDnsResolver implements DnsResolver {
  @override
  Future<String> resolve(String domain) async {
    if (domain == 'api.example.com') {
      Logger.info('Mock DNS解析: $domain -> 198.1.1.1');
      return '198.1.1.1';
    }
    return domain;
  }
  
  @override
  Future<String> resolveFromCache(String domain) async {
    return await resolve(domain);
  }
  
  @override
  void clearCache() {
    Logger.info('清除DNS缓存');
  }
  
  @override
  Future<void> initialize(DnsConfig config) async {
    Logger.info('Mock DNS解析器初始化');
  }
  
  @override
  Map<String, dynamic> getCacheStats() {
    return {
      'size': 0,
      'maxSize': 100,
      'domains': [],
    };
  }
}

/// 简单的HTTP/2客户端测试
class SimpleHttp2Client {
  static Future<void> testHttp2Request() async {
    Logger.info('开始简单HTTP/2客户端测试...');
    
    try {
      // 连接到目标服务器
      final socket = await Socket.connect('198.1.1.1', 7349);
      Logger.info('连接到目标服务器: 198.1.1.1:7349');
      
      // 创建HTTP/2客户端传输连接
      final transport = ClientTransportConnection.viaSocket(socket);
      
      // 创建请求头部
      final headers = [
        Header.ascii(':method', 'GET'),
        Header.ascii(':path', '/'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', 'api.example.com'), // 原始域名
        Header.ascii('user-agent', 'Http2Test/1.0'),
      ];
      
      // 发送请求
      final stream = transport.makeRequest(headers, endStream: true);
      Logger.info('发送HTTP/2请求，包含原始域名: api.example.com');
      
      // 监听响应
      stream.incomingMessages.listen(
        (message) {
          if (message is HeadersStreamMessage) {
            Logger.info('收到响应头部: ${message.headers.length} 个头部');
            for (final header in message.headers) {
              final name = utf8.decode(header.name);
              final value = utf8.decode(header.value);
              Logger.info('  $name: $value');
            }
          } else if (message is DataStreamMessage) {
            final data = utf8.decode(message.bytes, allowMalformed: true);
            Logger.info('收到响应数据: ${data.length} 字符');
            Logger.info('数据内容: $data');
          }
        },
        onError: (error) {
          Logger.error('接收响应时出错', error);
        },
        onDone: () {
          Logger.info('响应接收完成');
        },
      );
      
      // 等待响应
      await Future.delayed(Duration(seconds: 5));
      
      // 关闭连接
      await transport.finish();
      await socket.close();
      Logger.info('HTTP/2客户端测试完成');
      
    } catch (e) {
      Logger.error('HTTP/2客户端测试失败', e);
    }
  }
}

/// 主函数
void main() async {
  Logger.info('=== HTTP/2测试脚本启动 ===');
  
  // 运行HTTP/2处理测试
  await Http2Test.runTest();
  
  // 运行简单客户端测试
  await SimpleHttp2Client.testHttp2Request();
  
  Logger.info('=== HTTP/2测试脚本完成 ===');
}
