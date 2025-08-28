import 'dart:io';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 高级功能测试模块 - 负责高级功能、配置选项和性能测试
class AdvancedTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final Function(String) onSnackBarMessage;
  final bool isInitialized;
  final bool isProxyRunning;

  AdvancedTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.onSnackBarMessage,
    required this.isInitialized,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试高级功能
  Future<void> testAdvancedFeatures() async {
    onResultUpdate('正在测试高级功能...');
    onLogMessage('Testing advanced features...');

    try {
      final results = <String>[];
      int successCount = 0;
      int totalTests = 0;

      // 1. 日志控制测试
      onLogMessage('1. Testing log control...');
      totalTests++;

      try {
        // 设置日志级别
        FlutterAliHttpDns.setLogLevel(LogLevel.info);
        FlutterAliHttpDns.setLogEnabled(true);
        onLogMessage('   Log level set to INFO, logging enabled');

        final result = '✅ 日志控制测试\n'
            '   日志级别: INFO\n'
            '   日志启用: 是\n'
            '   状态: 配置成功';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 日志控制测试\n'
            '   错误: $e\n'
            '   状态: 配置失败';
        results.add(result);
      }

      // 2. 端口可用性检查
      onLogMessage('2. Testing port availability...');
      totalTests++;

      try {
        final port4041Available = await _dnsService.isPortAvailable(4041);
        final port9999Available = await _dnsService.isPortAvailable(9999);
        onLogMessage('   Port 4041 available: $port4041Available');
        onLogMessage('   Port 9999 available: $port9999Available');

        final result = '✅ 端口可用性检查\n'
            '   端口 4041: ${port4041Available ? '可用' : '被占用'}\n'
            '   端口 9999: ${port9999Available ? '可用' : '被占用'}\n'
            '   状态: 检查完成';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 端口可用性检查\n'
            '   错误: $e\n'
            '   状态: 检查失败';
        results.add(result);
      }

      // 3. 代理配置字符串
      onLogMessage('3. Testing proxy config string...');
      totalTests++;

      try {
        final proxyConfigString = await _dnsService.getProxyConfigString();
        onLogMessage('   Proxy config string: $proxyConfigString');

        final result = '✅ 代理配置字符串\n'
            '   配置: $proxyConfigString\n'
            '   状态: 获取成功';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 代理配置字符串\n'
            '   错误: $e\n'
            '   状态: 获取失败';
        results.add(result);
      }

      // 4. 代理配置测试
      onLogMessage('4. Testing proxy configuration...');
      totalTests++;

      if (isProxyRunning) {
        try {
          // 获取代理配置
          final proxyAddress = await _dnsService.getProxyAddress();
          final http2Address = await _dnsService.getHttp2ProxyAddress();
          final allAddresses = await _dnsService.getAllProxyAddresses();
          final dioConfig = await _dnsService.getDioProxyConfig();

          onLogMessage('   Proxy address: $proxyAddress');
          onLogMessage('   HTTP/2 address: $http2Address');
          onLogMessage('   All addresses: ${allAddresses.join(', ')}');
          onLogMessage('   Dio config: $dioConfig');

          final result = '✅ 代理配置测试\n'
              '   代理地址: $proxyAddress\n'
              '   HTTP/2地址: $http2Address\n'
              '   所有地址: ${allAddresses.join(', ')}\n'
              '   Dio配置: $dioConfig\n'
              '   状态: 配置正常';
          results.add(result);
          successCount++;
        } catch (e) {
          final result = '❌ 代理配置测试\n'
              '   错误: $e\n'
              '   状态: 配置异常';
          results.add(result);
        }
      } else {
        final result = '⚠️ 代理配置测试\n'
            '   代理服务器未运行\n'
            '   状态: 跳过测试';
        results.add(result);
      }

      // 5. 端口管理测试
      onLogMessage('5. Testing port management...');
      totalTests++;

      if (isProxyRunning) {
        try {
          final actualPorts = await _dnsService.getActualPorts();
          final mainPort = await _dnsService.getMainPort();

          onLogMessage('   Actual ports: ${actualPorts.join(', ')}');
          onLogMessage('   Main port: $mainPort');

          final result = '✅ 端口管理测试\n'
              '   实际端口: ${actualPorts.join(', ')}\n'
              '   主端口: $mainPort\n'
              '   状态: 管理正常';
          results.add(result);
          successCount++;
        } catch (e) {
          final result = '❌ 端口管理测试\n'
              '   错误: $e\n'
              '   状态: 管理异常';
          results.add(result);
        }
      } else {
        final result = '⚠️ 端口管理测试\n'
            '   代理服务器未运行\n'
            '   状态: 跳过测试';
        results.add(result);
      }

      // 7. 代理状态检查测试
      onLogMessage('7. Testing proxy status check...');
      totalTests++;

      try {
        final proxyStatus = await _dnsService.checkProxyStatus();
        onLogMessage('   Proxy status: $proxyStatus');

        final result = '✅ 代理状态检查测试\n'
            '   代理状态: $proxyStatus\n'
            '   状态: 检查完成';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 代理状态检查测试\n'
            '   错误: $e\n'
            '   状态: 检查失败';
        results.add(result);
      }

      final successRate = (successCount / totalTests * 100).toStringAsFixed(1);
      final summary =
          '高级功能测试统计: $successCount/$totalTests 成功 (${successRate}%)';

      final detailedResult = '$summary\n\n${results.join('\n\n')}';

      onResultUpdate(detailedResult);
      onLogMessage('Advanced features test completed successfully');
      onSnackBarMessage('高级功能测试完成: $successCount/$totalTests 成功');
    } catch (e) {
      onLogMessage('Advanced features test failed: $e');
      onResultUpdate('高级功能测试失败: $e');
      onSnackBarMessage('高级功能测试失败: ${e.toString().split(':').first}');
    }
  }

  /// 测试性能
  Future<void> testPerformance() async {
    onResultUpdate('正在测试性能...');
    onLogMessage('Testing performance...');

    try {
      final results = <String>[];
      int successCount = 0;
      int totalTests = 0;

      // 1. DNS解析性能测试
      onLogMessage('1. Testing DNS resolution performance...');
      totalTests++;

      try {
        final testDomains = [
          'www.google.com',
          'www.github.com',
          'www.baidu.com',
          'www.qq.com',
          'www.taobao.com',
        ];

        final stopwatch = Stopwatch()..start();
        final domainResults = <String>[];
        int domainSuccessCount = 0;

        for (final domain in testDomains) {
          try {
            final domainStopwatch = Stopwatch()..start();
            final resolvedIp = await _dnsService.resolveDomain(domain);
            domainStopwatch.stop();

            if (resolvedIp != domain) {
              domainSuccessCount++;
              final result =
                  '   ✅ $domain -> $resolvedIp (${domainStopwatch.elapsedMilliseconds}ms)';
              onLogMessage(result);
              domainResults.add(result);
            } else {
              final result =
                  '   ❌ $domain -> 解析失败 (${domainStopwatch.elapsedMilliseconds}ms)';
              onLogMessage(result);
              domainResults.add(result);
            }
          } catch (e) {
            final result = '   ❌ $domain -> 错误: $e';
            onLogMessage(result);
            domainResults.add(result);
          }
        }

        stopwatch.stop();
        final totalDuration = stopwatch.elapsedMilliseconds;
        final domainSuccessRate =
            (domainSuccessCount / testDomains.length * 100).toStringAsFixed(1);
        final averageTime =
            (totalDuration / testDomains.length).toStringAsFixed(1);

        onLogMessage('   DNS resolution performance:');
        onLogMessage('     Total domains: ${testDomains.length}');
        onLogMessage('     Success count: $domainSuccessCount');
        onLogMessage('     Success rate: ${domainSuccessRate}%');
        onLogMessage('     Total time: ${totalDuration}ms');
        onLogMessage('     Average time: ${averageTime}ms');

        final result = '✅ DNS解析性能测试\n'
            '   测试域名数量: ${testDomains.length}\n'
            '   成功解析: $domainSuccessCount\n'
            '   成功率: ${domainSuccessRate}%\n'
            '   总耗时: ${totalDuration}ms\n'
            '   平均耗时: ${averageTime}ms\n'
            '   详细结果:\n${domainResults.join('\n')}';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ DNS解析性能测试\n'
            '   错误: $e\n'
            '   状态: 测试失败';
        results.add(result);
      }

      // 2. 代理连接性能测试
      onLogMessage('2. Testing proxy connection performance...');
      totalTests++;

      if (isProxyRunning) {
        try {
          final proxyAddress = await _dnsService.getProxyAddress();
          if (proxyAddress != null) {
            final parts = proxyAddress.split(':');
            if (parts.length == 2) {
              final host = parts[0];
              final port = int.tryParse(parts[1]);

              if (port != null) {
                final connectionStopwatch = Stopwatch()..start();
                int connectionSuccessCount = 0;
                final connectionCount = 5;
                final connectionResults = <String>[];

                for (int i = 0; i < connectionCount; i++) {
                  try {
                    final singleConnectionStopwatch = Stopwatch()..start();
                    final socket = await Socket.connect(host, port);
                    singleConnectionStopwatch.stop();
                    socket.destroy();
                    connectionSuccessCount++;
                    final result =
                        '   ✅ 连接 $i: 成功 (${singleConnectionStopwatch.elapsedMilliseconds}ms)';
                    onLogMessage(result);
                    connectionResults.add(result);
                  } catch (e) {
                    final result = '   ❌ 连接 $i: 失败 - $e';
                    onLogMessage(result);
                    connectionResults.add(result);
                  }
                }

                connectionStopwatch.stop();
                final connectionDuration =
                    connectionStopwatch.elapsedMilliseconds;
                final connectionSuccessRate =
                    (connectionSuccessCount / connectionCount * 100)
                        .toStringAsFixed(1);
                final connectionAverageTime =
                    (connectionDuration / connectionCount).toStringAsFixed(1);

                onLogMessage('   Proxy connection performance:');
                onLogMessage('     Total connections: $connectionCount');
                onLogMessage('     Success count: $connectionSuccessCount');
                onLogMessage('     Success rate: ${connectionSuccessRate}%');
                onLogMessage('     Total time: ${connectionDuration}ms');
                onLogMessage('     Average time: ${connectionAverageTime}ms');

                final result = '✅ 代理连接性能测试\n'
                    '   代理地址: $proxyAddress\n'
                    '   连接次数: $connectionCount\n'
                    '   成功连接: $connectionSuccessCount\n'
                    '   成功率: ${connectionSuccessRate}%\n'
                    '   总耗时: ${connectionDuration}ms\n'
                    '   平均耗时: ${connectionAverageTime}ms\n'
                    '   详细结果:\n${connectionResults.join('\n')}';
                results.add(result);
                successCount++;
              } else {
                final result = '❌ 代理连接性能测试\n'
                    '   端口解析失败: $parts[1]\n'
                    '   状态: 测试失败';
                results.add(result);
              }
            } else {
              final result = '❌ 代理连接性能测试\n'
                  '   代理地址格式错误: $proxyAddress\n'
                  '   状态: 测试失败';
              results.add(result);
            }
          } else {
            final result = '❌ 代理连接性能测试\n'
                '   无法获取代理地址\n'
                '   状态: 测试失败';
            results.add(result);
          }
        } catch (e) {
          final result = '❌ 代理连接性能测试\n'
              '   错误: $e\n'
              '   状态: 测试失败';
          results.add(result);
        }
      } else {
        final result = '⚠️ 代理连接性能测试\n'
            '   代理服务器未运行\n'
            '   状态: 跳过测试';
        results.add(result);
      }

      final successRate = (successCount / totalTests * 100).toStringAsFixed(1);
      final summary = '性能测试统计: $successCount/$totalTests 成功 (${successRate}%)';

      final detailedResult = '$summary\n\n${results.join('\n\n')}';

      onResultUpdate(detailedResult);
      onLogMessage('Performance test completed successfully');
      onSnackBarMessage('性能测试完成: $successCount/$totalTests 成功');
    } catch (e) {
      onLogMessage('Performance test failed: $e');
      onResultUpdate('性能测试失败: $e');
      onSnackBarMessage('性能测试失败: ${e.toString().split(':').first}');
    }
  }

  /// 测试错误处理
  Future<void> testErrorHandling() async {
    onResultUpdate('正在测试错误处理...');
    onLogMessage('Testing error handling...');

    try {
      final results = <String>[];
      int successCount = 0;
      int totalTests = 0;

      // 1. 无效域名测试
      onLogMessage('1. Testing invalid domain resolution...');
      totalTests++;

      try {
        final invalidDomains = [
          'invalid.domain.test',
          'nonexistent.domain.local',
          'test.invalid',
        ];

        final domainResults = <String>[];
        int domainSuccessCount = 0;

        for (final domain in invalidDomains) {
          try {
            final resolvedIp = await _dnsService.resolveDomain(domain);
            if (resolvedIp == domain) {
              // 返回原域名是正确的错误处理行为
              domainSuccessCount++;
              final result = '   ✅ $domain -> $resolvedIp (正确返回原域名)';
              onLogMessage(result);
              domainResults.add(result);
            } else {
              final result = '   ⚠️ $domain -> $resolvedIp (意外解析成功)';
              onLogMessage(result);
              domainResults.add(result);
            }
          } catch (e) {
            final result = '   ❌ $domain -> 异常: $e';
            onLogMessage(result);
            domainResults.add(result);
          }
        }

        final domainSuccessRate =
            (domainSuccessCount / invalidDomains.length * 100)
                .toStringAsFixed(1);
        final result = '✅ 无效域名测试\n'
            '   测试域名数量: ${invalidDomains.length}\n'
            '   正确处理: $domainSuccessCount\n'
            '   处理率: ${domainSuccessRate}%\n'
            '   详细结果:\n${domainResults.join('\n')}';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 无效域名测试\n'
            '   错误: $e\n'
            '   状态: 测试失败';
        results.add(result);
      }

      // 2. 代理状态检查
      onLogMessage('2. Testing proxy status check...');
      totalTests++;

      try {
        final proxyStatus = await _dnsService.checkProxyStatus();
        onLogMessage('   Proxy status: $proxyStatus');

        final result = '✅ 代理状态检查\n'
            '   代理状态: $proxyStatus\n'
            '   状态: 检查成功';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 代理状态检查\n'
            '   错误: $e\n'
            '   状态: 检查失败';
        results.add(result);
      }

      // 3. 端口检查
      onLogMessage('3. Testing port checks...');
      totalTests++;

      try {
        final invalidPorts = [-1, 0, 65536, 99999];
        final portResults = <String>[];
        int portSuccessCount = 0;

        for (final port in invalidPorts) {
          try {
            final isAvailable = await _dnsService.isPortAvailable(port);
            if (!isAvailable) {
              // 无效端口应该返回false
              portSuccessCount++;
              final result = '   ✅ 端口 $port: 不可用 (正确)';
              onLogMessage(result);
              portResults.add(result);
            } else {
              final result = '   ⚠️ 端口 $port: 可用 (意外结果)';
              onLogMessage(result);
              portResults.add(result);
            }
          } catch (e) {
            // 异常也是可以接受的错误处理
            portSuccessCount++;
            final result = '   ✅ 端口 $port: 异常处理 (正确) - $e';
            onLogMessage(result);
            portResults.add(result);
          }
        }

        final portSuccessRate =
            (portSuccessCount / invalidPorts.length * 100).toStringAsFixed(1);
        final result = '✅ 端口检查测试\n'
            '   测试端口数量: ${invalidPorts.length}\n'
            '   正确处理: $portSuccessCount\n'
            '   处理率: ${portSuccessRate}%\n'
            '   详细结果:\n${portResults.join('\n')}';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 端口检查测试\n'
            '   错误: $e\n'
            '   状态: 测试失败';
        results.add(result);
      }

      // 4. 边界值测试
      onLogMessage('4. Testing boundary values...');
      totalTests++;

      try {
        final boundaryResults = <String>[];
        int boundarySuccessCount = 0;

        // 测试空字符串
        try {
          final emptyResult = await _dnsService.resolveDomain('');
          if (emptyResult == '') {
            boundarySuccessCount++;
            final result = '   ✅ 空域名: 正确返回空字符串';
            onLogMessage(result);
            boundaryResults.add(result);
          } else {
            final result = '   ⚠️ 空域名: 返回 $emptyResult';
            onLogMessage(result);
            boundaryResults.add(result);
          }
        } catch (e) {
          boundarySuccessCount++;
          final result = '   ✅ 空域名: 异常处理 (正确) - $e';
          onLogMessage(result);
          boundaryResults.add(result);
        }

        // 测试特殊字符
        try {
          final specialResult =
              await _dnsService.resolveDomain('test@#\$%^&*()');
          if (specialResult == 'test@#\$%^&*()') {
            boundarySuccessCount++;
            final result = '   ✅ 特殊字符域名: 正确返回原域名';
            onLogMessage(result);
            boundaryResults.add(result);
          } else {
            final result = '   ⚠️ 特殊字符域名: 返回 $specialResult';
            onLogMessage(result);
            boundaryResults.add(result);
          }
        } catch (e) {
          boundarySuccessCount++;
          final result = '   ✅ 特殊字符域名: 异常处理 (正确) - $e';
          onLogMessage(result);
          boundaryResults.add(result);
        }

        final boundarySuccessRate =
            (boundarySuccessCount / 2 * 100).toStringAsFixed(1);
        final result = '✅ 边界值测试\n'
            '   测试项目: 2\n'
            '   正确处理: $boundarySuccessCount\n'
            '   处理率: ${boundarySuccessRate}%\n'
            '   详细结果:\n${boundaryResults.join('\n')}';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 边界值测试\n'
            '   错误: $e\n'
            '   状态: 测试失败';
        results.add(result);
      }

      // 5. 网络异常模拟测试
      onLogMessage('5. Testing network exception simulation...');
      totalTests++;

      try {
        final networkResults = <String>[];
        int networkSuccessCount = 0;

        // 测试超长域名
        try {
          final longDomain = 'a' * 1000 + '.com';
          final longResult = await _dnsService.resolveDomain(longDomain);
          if (longResult == longDomain) {
            networkSuccessCount++;
            final result = '   ✅ 超长域名: 正确返回原域名';
            onLogMessage(result);
            networkResults.add(result);
          } else {
            final result = '   ⚠️ 超长域名: 返回 $longResult';
            onLogMessage(result);
            networkResults.add(result);
          }
        } catch (e) {
          networkSuccessCount++;
          final result = '   ✅ 超长域名: 异常处理 (正确) - $e';
          onLogMessage(result);
          networkResults.add(result);
        }

        // 测试数字域名
        try {
          final numericResult = await _dnsService.resolveDomain('123.456.789');
          if (numericResult == '123.456.789') {
            networkSuccessCount++;
            final result = '   ✅ 数字域名: 正确返回原域名';
            onLogMessage(result);
            networkResults.add(result);
          } else {
            final result = '   ⚠️ 数字域名: 返回 $numericResult';
            onLogMessage(result);
            networkResults.add(result);
          }
        } catch (e) {
          networkSuccessCount++;
          final result = '   ✅ 数字域名: 异常处理 (正确) - $e';
          onLogMessage(result);
          networkResults.add(result);
        }

        final networkSuccessRate =
            (networkSuccessCount / 2 * 100).toStringAsFixed(1);
        final result = '✅ 网络异常模拟测试\n'
            '   测试项目: 2\n'
            '   正确处理: $networkSuccessCount\n'
            '   处理率: ${networkSuccessRate}%\n'
            '   详细结果:\n${networkResults.join('\n')}';
        results.add(result);
        successCount++;
      } catch (e) {
        final result = '❌ 网络异常模拟测试\n'
            '   错误: $e\n'
            '   状态: 测试失败';
        results.add(result);
      }

      final successRate = (successCount / totalTests * 100).toStringAsFixed(1);
      final summary =
          '错误处理测试统计: $successCount/$totalTests 成功 (${successRate}%)';

      final detailedResult = '$summary\n\n${results.join('\n\n')}';

      onResultUpdate(detailedResult);
      onLogMessage('Error handling test completed successfully');
      onSnackBarMessage('错误处理测试完成: $successCount/$totalTests 成功');
    } catch (e) {
      final errorMessage = '❌ 错误处理测试失败\n'
          '   错误: $e\n'
          '   状态: 测试已终止';
      onResultUpdate(errorMessage);
      onLogMessage('Error handling test failed: $e');
      onSnackBarMessage('错误处理测试失败: ${e.toString().split(':').first}');
    }
  }
}
