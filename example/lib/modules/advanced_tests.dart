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
      // 1. 日志控制测试
      onLogMessage('1. Testing log control...');
      
      // 设置日志级别
      FlutterAliHttpDns.setLogLevel(LogLevel.info);
      FlutterAliHttpDns.setLogEnabled(true);
      onLogMessage('   Log level set to INFO, logging enabled');

      // 2. 端口可用性检查
      onLogMessage('2. Testing port availability...');
      
      final port4041Available = await _dnsService.isPortAvailable(4041);
      final port9999Available = await _dnsService.isPortAvailable(9999);
      onLogMessage('   Port 4041 available: $port4041Available');
      onLogMessage('   Port 9999 available: $port9999Available');

      // 3. 代理配置字符串
      onLogMessage('3. Testing proxy config string...');
      
      final proxyConfigString = await _dnsService.getProxyConfigString();
      onLogMessage('   Proxy config string: $proxyConfigString');

      // 4. 代理配置测试
      onLogMessage('4. Testing proxy configuration...');
      
      if (isProxyRunning) {
        // 获取代理配置
        final proxyAddress = await _dnsService.getProxyAddress();
        final http2Address = await _dnsService.getHttp2ProxyAddress();
        final allAddresses = await _dnsService.getAllProxyAddresses();
        final dioConfig = await _dnsService.getDioProxyConfig();
        
        onLogMessage('   Proxy address: $proxyAddress');
        onLogMessage('   HTTP/2 address: $http2Address');
        onLogMessage('   All addresses: ${allAddresses.join(', ')}');
        onLogMessage('   Dio config: $dioConfig');
      } else {
        onLogMessage('   Proxy server is not running, skipping proxy config test');
      }

      // 5. 端口管理测试
      onLogMessage('5. Testing port management...');
      
      if (isProxyRunning) {
        final actualPorts = await _dnsService.getActualPorts();
        final mainPort = await _dnsService.getMainPort();
        final availablePorts = await _dnsService.getAvailablePorts();
        
        onLogMessage('   Actual ports: ${actualPorts.join(', ')}');
        onLogMessage('   Main port: $mainPort');
        onLogMessage('   Available ports: ${availablePorts.join(', ')}');
      } else {
        onLogMessage('   Proxy server is not running, skipping port management test');
      }

      // 6. 进程信息测试
      onLogMessage('6. Testing process information...');
      
      final currentPid = FlutterAliHttpDns.getCurrentProcessId();
      onLogMessage('   Current process ID: $currentPid');

      // 7. 端口信息测试
      onLogMessage('7. Testing port information...');
      
      final port4041Info = await FlutterAliHttpDns.getPortInfo(4041);
      onLogMessage('   Port 4041 info: ${port4041Info.toString()}');

      final isOwnApp = await FlutterAliHttpDns.isPortUsedByOwnApp(4041);
      onLogMessage('   Port 4041 used by own app: $isOwnApp');

      onResultUpdate('高级功能测试完成');
      onLogMessage('Advanced features test completed successfully');
      onSnackBarMessage('高级功能测试完成');

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
      // 1. DNS解析性能测试
      onLogMessage('1. Testing DNS resolution performance...');
      
      final testDomains = [
        'www.google.com',
        'www.github.com',
        'www.baidu.com',
        'www.qq.com',
        'www.taobao.com',
      ];

      final stopwatch = Stopwatch()..start();
      int successCount = 0;

      for (final domain in testDomains) {
        try {
          final resolvedIp = await _dnsService.resolveDomain(domain);
          if (resolvedIp != domain) {
            successCount++;
            onLogMessage('   $domain -> $resolvedIp');
          } else {
            onLogMessage('   $domain -> (no resolution)');
          }
        } catch (e) {
          onLogMessage('   $domain -> error: $e');
        }
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      final successRate = (successCount / testDomains.length * 100).toStringAsFixed(1);

      onLogMessage('   DNS resolution performance:');
      onLogMessage('     Total domains: ${testDomains.length}');
      onLogMessage('     Success count: $successCount');
      onLogMessage('     Success rate: ${successRate}%');
      onLogMessage('     Total time: ${duration}ms');
      onLogMessage('     Average time: ${(duration / testDomains.length).toStringAsFixed(1)}ms');

      // 2. 代理连接性能测试
      onLogMessage('2. Testing proxy connection performance...');
      
      if (isProxyRunning) {
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

              for (int i = 0; i < connectionCount; i++) {
                try {
                  final socket = await Socket.connect(host, port);
                  socket.destroy();
                  connectionSuccessCount++;
                  onLogMessage('   Connection $i: Success');
                } catch (e) {
                  onLogMessage('   Connection $i: Failed - $e');
                }
              }

              connectionStopwatch.stop();
              final connectionDuration = connectionStopwatch.elapsedMilliseconds;
              final connectionSuccessRate = (connectionSuccessCount / connectionCount * 100).toStringAsFixed(1);

              onLogMessage('   Proxy connection performance:');
              onLogMessage('     Total connections: $connectionCount');
              onLogMessage('     Success count: $connectionSuccessCount');
              onLogMessage('     Success rate: ${connectionSuccessRate}%');
              onLogMessage('     Total time: ${connectionDuration}ms');
              onLogMessage('     Average time: ${(connectionDuration / connectionCount).toStringAsFixed(1)}ms');
            }
          }
        }
      } else {
        onLogMessage('   Proxy server is not running, skipping connection performance test');
      }

      onResultUpdate('性能测试完成');
      onLogMessage('Performance test completed successfully');
      onSnackBarMessage('性能测试完成');

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
      // 1. 无效域名测试
      onLogMessage('1. Testing invalid domain resolution...');
      
      final invalidDomains = [
        'invalid.domain.test',
        'nonexistent.domain.local',
        'test.invalid',
      ];

      for (final domain in invalidDomains) {
        try {
          final resolvedIp = await _dnsService.resolveDomain(domain);
          onLogMessage('   $domain -> $resolvedIp (should be original domain)');
        } catch (e) {
          onLogMessage('   $domain -> error: $e');
        }
      }

      // 2. 代理状态检查
      onLogMessage('2. Testing proxy status check...');
      
      final proxyStatus = await _dnsService.checkProxyStatus();
      onLogMessage('   Proxy status: $proxyStatus');

      // 3. 端口检查
      onLogMessage('3. Testing port checks...');
      
      final invalidPorts = [-1, 0, 65536, 99999];
      for (final port in invalidPorts) {
        try {
          final isAvailable = await _dnsService.isPortAvailable(port);
          onLogMessage('   Port $port available: $isAvailable');
        } catch (e) {
          onLogMessage('   Port $port check error: $e');
        }
      }

      onResultUpdate('错误处理测试完成');
      onLogMessage('Error handling test completed successfully');
      onSnackBarMessage('错误处理测试完成');

    } catch (e) {
      onLogMessage('Error handling test failed: $e');
      onResultUpdate('错误处理测试失败: $e');
      onSnackBarMessage('错误处理测试失败: ${e.toString().split(':').first}');
    }
  }
}
