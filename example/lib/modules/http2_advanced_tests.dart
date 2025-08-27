import 'dart:io';
import 'dart:convert';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import '../nakama_config.dart';

/// HTTP/2高级测试模块 - 使用http2库进行测试
/// 验证新的HTTP/2代理服务器功能
class Http2AdvancedTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final bool isProxyRunning;

  Http2AdvancedTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试HTTP/2代理服务器功能
  Future<void> testHttp2ProxyServer() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    // 验证Nakama配置
    if (!NakamaConfig.isValid()) {
      onLogMessage('错误: Nakama配置无效，请检查nakama_config.dart文件');
      onResultUpdate('配置错误: 请设置正确的Nakama服务器域名');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 代理服务器...');
      onLogMessage('使用Nakama服务器: ${NakamaConfig.nakamaBaseUrl}');

      // 获取HTTP/2代理地址
      final http2Address = await _dnsService.getHttp2ProxyAddress();
      if (http2Address == null) {
        onLogMessage('HTTP/2代理服务器未启动');
        onResultUpdate('HTTP/2代理服务器未启动');
        return;
      }

      onLogMessage('HTTP/2代理地址: $http2Address');

      // 注册gRPC端口映射（HTTP/2）- 使用不安全连接
      final grpcPort = await _dnsService.registerMapping(
        targetPort: NakamaConfig.nakamaPortGrpc,
        targetDomain: NakamaConfig.nakamaBaseUrl,
        name: 'nakama-grpc-http2-advanced',
        description: 'Nakama gRPC HTTP/2 advanced test mapping',
        isSecure: false, // gRPC服务只支持HTTP
      );

      if (grpcPort == null) {
        onLogMessage('gRPC端口映射注册失败');
        onResultUpdate('gRPC端口映射注册失败');
        return;
      }

      onLogMessage('gRPC端口映射注册成功: localhost:$grpcPort -> ${NakamaConfig.nakamaBaseUrl}:${NakamaConfig.nakamaPortGrpc}');

      // 测试HTTP/2连接
      final testResults = await _testHttp2ConnectionWithLibrary(grpcPort);

      // 获取映射信息
      final allMappings = await _dnsService.getAllMappings();

      onResultUpdate(
        'HTTP/2 代理服务器测试完成\n'
        '服务器: ${NakamaConfig.nakamaBaseUrl}\n'
        'gRPC端口: $grpcPort\n'
        'HTTP/2代理: $http2Address\n'
        '测试结果: $testResults\n'
        '端口映射详情: ${allMappings.length} 个映射'
      );

      // 清理映射
      final success = await _dnsService.removeMapping(grpcPort);
      onLogMessage('Remove gRPC mapping (port $grpcPort): ${success ? 'Success' : 'Failed'}');

    } catch (e) {
      onLogMessage('HTTP/2代理服务器测试失败: $e');
      onResultUpdate('HTTP/2代理服务器测试失败: $e');
    }
  }

  /// 使用http2库测试HTTP/2连接
  Future<String> _testHttp2ConnectionWithLibrary(int localPort) async {
    try {
      onLogMessage('正在使用http2库测试HTTP/2连接 (localhost:$localPort)');

      // 创建Socket连接
      final socket = await Socket.connect('localhost', localPort);
      onLogMessage('Socket连接建立成功');

      // 创建HTTP/2客户端传输连接
      final clientTransport = ClientTransportConnection.viaSocket(socket);
      onLogMessage('HTTP/2客户端传输连接创建成功');

      // 创建HTTP/2请求
      final headers = [
        Header.ascii(':method', 'GET'),
        Header.ascii(':path', '/'),
        Header.ascii(':scheme', 'https'),
        Header.ascii(':authority', 'localhost:$localPort'),
        Header.ascii('user-agent', 'flutter-ali-http-dns-test'),
      ];

      onLogMessage('发送HTTP/2请求头: ${headers.map((h) => '${utf8.decode(h.name)}: ${utf8.decode(h.value)}').join(', ')}');

      // 发送请求
      final stream = clientTransport.makeRequest(headers, endStream: true);
      onLogMessage('HTTP/2请求已发送');

      // 等待响应
      bool receivedResponse = false;
      String responseStatus = '';

      stream.incomingMessages.listen(
        (message) {
          if (message is HeadersStreamMessage) {
            receivedResponse = true;
            final responseHeaders = <String, String>{};
            for (final header in message.headers) {
              final name = utf8.decode(header.name);
              final value = utf8.decode(header.value);
              responseHeaders[name] = value;
              if (name == ':status') {
                responseStatus = value;
              }
            }
            onLogMessage('收到HTTP/2响应头: ${responseHeaders.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
          } else if (message is DataStreamMessage) {
            onLogMessage('收到HTTP/2数据: ${message.bytes.length} 字节');
          }
        },
        onError: (error) {
          onLogMessage('HTTP/2流错误: $error');
        },
        onDone: () {
          onLogMessage('HTTP/2流结束');
        },
      );

      // 等待响应或超时
      await Future.delayed(const Duration(seconds: 5));

      // 关闭连接
      await clientTransport.finish();
      socket.destroy();

      if (receivedResponse) {
        onLogMessage('HTTP/2连接测试成功，状态码: $responseStatus');
        return 'HTTP/2连接成功，状态码: $responseStatus';
      } else {
        onLogMessage('HTTP/2连接测试超时');
        return 'HTTP/2连接超时';
      }

    } catch (e) {
      onLogMessage('HTTP/2连接测试失败: $e');
      return 'HTTP/2连接失败: $e';
    }
  }

  /// 测试HTTP/2代理服务器的域名解析功能
  Future<void> testHttp2DomainResolution() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 域名解析功能...');

      // 获取HTTP/2代理地址
      final http2Address = await _dnsService.getHttp2ProxyAddress();
      if (http2Address == null) {
        onLogMessage('HTTP/2代理服务器未启动');
        onResultUpdate('HTTP/2代理服务器未启动');
        return;
      }

      onLogMessage('HTTP/2代理地址: $http2Address');

      // 测试域名解析
      final testDomains = [
        'www.google.com',
        'www.github.com',
        'api.github.com',
      ];

      final results = <String, String>{};

      for (final domain in testDomains) {
        try {
          final resolvedIp = await _dnsService.resolveDomain(domain);
          results[domain] = resolvedIp;
          onLogMessage('域名解析: $domain -> $resolvedIp');
        } catch (e) {
          results[domain] = '解析失败: $e';
          onLogMessage('域名解析失败: $domain -> $e');
        }
      }

      final resultText = results.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');

      onResultUpdate(
        'HTTP/2 域名解析测试完成\n'
        'HTTP/2代理: $http2Address\n'
        '解析结果:\n$resultText'
      );

    } catch (e) {
      onLogMessage('HTTP/2域名解析测试失败: $e');
      onResultUpdate('HTTP/2域名解析测试失败: $e');
    }
  }

  /// 测试HTTP/2代理服务器的端口映射功能
  Future<void> testHttp2PortMapping() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 端口映射功能...');

      // 获取HTTP/2代理地址
      final http2Address = await _dnsService.getHttp2ProxyAddress();
      if (http2Address == null) {
        onLogMessage('HTTP/2代理服务器未启动');
        onResultUpdate('HTTP/2代理服务器未启动');
        return;
      }

      onLogMessage('HTTP/2代理地址: $http2Address');

      // 测试多个端口映射
      final testMappings = [
        {
          'name': 'test-http2-1',
          'targetPort': 443,
          'targetDomain': 'www.google.com',
        },
        {
          'name': 'test-http2-2',
          'targetPort': 80,
          'targetDomain': 'www.github.com',
        },
      ];

      final results = <String, int>{};

      for (final mapping in testMappings) {
        try {
          final localPort = await _dnsService.registerMapping(
            targetPort: mapping['targetPort'] as int,
            targetDomain: mapping['targetDomain'] as String,
            name: mapping['name'] as String,
            description: 'HTTP/2测试映射',
            isSecure: mapping['isSecure'] as bool? ?? true, // 默认使用安全连接
          );

          if (localPort != null) {
            results[mapping['name'] as String] = localPort;
            onLogMessage('端口映射成功: ${mapping['name']} -> localhost:$localPort -> ${mapping['targetDomain']}:${mapping['targetPort']}');
          } else {
            onLogMessage('端口映射失败: ${mapping['name']}');
          }
        } catch (e) {
          onLogMessage('端口映射异常: ${mapping['name']} -> $e');
        }
      }

      // 清理映射
      for (final entry in results.entries) {
        try {
          final success = await _dnsService.removeMapping(entry.value);
          onLogMessage('清理映射 ${entry.key} (port ${entry.value}): ${success ? 'Success' : 'Failed'}');
        } catch (e) {
          onLogMessage('清理映射失败: ${entry.key} -> $e');
        }
      }

      final resultText = results.entries
          .map((e) => '${e.key}: localhost:${e.value}')
          .join('\n');

      onResultUpdate(
        'HTTP/2 端口映射测试完成\n'
        'HTTP/2代理: $http2Address\n'
        '映射结果:\n$resultText'
      );

    } catch (e) {
      onLogMessage('HTTP/2端口映射测试失败: $e');
      onResultUpdate('HTTP/2端口映射测试失败: $e');
    }
  }

  /// 测试HTTP/2代理服务器的性能
  Future<void> testHttp2Performance() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 代理服务器性能...');

      // 获取HTTP/2代理地址
      final http2Address = await _dnsService.getHttp2ProxyAddress();
      if (http2Address == null) {
        onLogMessage('HTTP/2代理服务器未启动');
        onResultUpdate('HTTP/2代理服务器未启动');
        return;
      }

      onLogMessage('HTTP/2代理地址: $http2Address');

      // 注册测试映射
      final testPort = await _dnsService.registerMapping(
        targetPort: 443,
        targetDomain: 'www.google.com',
        name: 'performance-test',
        description: 'HTTP/2性能测试',
        isSecure: true, // Google使用HTTPS
      );

      if (testPort == null) {
        onLogMessage('性能测试端口映射失败');
        onResultUpdate('性能测试端口映射失败');
        return;
      }

      onLogMessage('性能测试端口: localhost:$testPort');

      // 执行性能测试
      final stopwatch = Stopwatch()..start();
      final testCount = 10;
      int successCount = 0;

      for (int i = 0; i < testCount; i++) {
        try {
          final socket = await Socket.connect('localhost', testPort);
          final clientTransport = ClientTransportConnection.viaSocket(socket);
          
          final headers = [
            Header.ascii(':method', 'GET'),
            Header.ascii(':path', '/'),
            Header.ascii(':scheme', 'https'),
            Header.ascii(':authority', 'localhost:$testPort'),
          ];

          final stream = clientTransport.makeRequest(headers, endStream: true);
          
          bool receivedResponse = false;
          stream.incomingMessages.listen(
            (message) {
              if (message is HeadersStreamMessage) {
                receivedResponse = true;
              }
            },
            onDone: () {
              if (receivedResponse) {
                successCount++;
              }
            },
          );

          await Future.delayed(const Duration(milliseconds: 100));
          await clientTransport.finish();
          socket.destroy();
          
        } catch (e) {
          onLogMessage('性能测试请求 $i 失败: $e');
        }
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      final successRate = (successCount / testCount * 100).toStringAsFixed(1);

      // 清理测试映射
      await _dnsService.removeMapping(testPort);

      onResultUpdate(
        'HTTP/2 性能测试完成\n'
        'HTTP/2代理: $http2Address\n'
        '测试请求数: $testCount\n'
        '成功请求数: $successCount\n'
        '成功率: ${successRate}%\n'
        '总耗时: ${duration}ms\n'
        '平均耗时: ${(duration / testCount).toStringAsFixed(1)}ms'
      );

    } catch (e) {
      onLogMessage('HTTP/2性能测试失败: $e');
      onResultUpdate('HTTP/2性能测试失败: $e');
    }
  }
}
