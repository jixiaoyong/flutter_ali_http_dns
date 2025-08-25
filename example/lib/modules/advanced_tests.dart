import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns_example/credentials.dart';

/// 高级功能测试模块 - 负责高级功能、配置选项和性能测试
class AdvancedTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final bool isInitialized;
  final bool isProxyRunning;

  AdvancedTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
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

      // 4. 批量映射操作
      onLogMessage('4. Testing batch mapping operations...');
      
      if (isProxyRunning) {
        // 直接注册多个服务映射
        final services = [
          {'name': 'API', 'targetPort': 7350, 'domain': 'api.game-service.com'},
          {'name': 'Chat', 'targetPort': 7349, 'domain': 'chat.game-service.com'},
          {'name': 'Auth', 'targetPort': null, 'domain': 'auth.game-service.com'},
        ];
        
        final successfulMappings = <String, int>{};
        
        for (final service in services) {
          final serviceName = service['name'] as String;
          final targetPort = service['targetPort'] as int?;
          final domain = service['domain'] as String;
          
          final localPort = await _dnsService.registerMapping(
            targetPort: targetPort,
            targetDomain: domain,
            name: serviceName,
            description: '$serviceName mapping',
          );
          
          if (localPort != null) {
            successfulMappings[serviceName] = localPort;
            onLogMessage('   Register $serviceName on port $localPort: Success');
          } else {
            onLogMessage('   Register $serviceName: Failed');
          }
        }

        // 获取所有映射的详细信息
        final allMappings = await _dnsService.getAllMappings();
        onLogMessage('   Total mappings: ${allMappings.length}');
        for (final entry in allMappings.entries) {
          final mapping = entry.value;
          onLogMessage('     Port ${entry.key}: ${mapping['targetDomain']}:${mapping['targetPort'] ?? 'original'}');
        }

        // 批量移除映射
        for (final entry in successfulMappings.entries) {
          final serviceName = entry.key;
          final localPort = entry.value;
          final success = await _dnsService.removeMapping(localPort);
          onLogMessage('   Remove $serviceName (port $localPort): ${success ? 'Success' : 'Failed'}');
        }
      } else {
        onLogMessage('   Proxy server is not running, skipping batch mapping test');
      }

      // 5. 错误处理演示
      onLogMessage('5. Testing error handling...');
      
      // 尝试在代理未运行时注册映射
      if (!isProxyRunning) {
        try {
          // 使用一个常见的端口号进行错误测试
          await _dnsService.registerMapping(
            targetPort: 7350,
            targetDomain: 'test.com',
          );
        } catch (e) {
          onLogMessage('   Expected error when proxy not running: $e');
        }
      } else {
        // 如果代理正在运行，测试使用无效端口
        try {
          await _dnsService.registerMapping(
            targetPort: 7350,
            targetDomain: 'test.com',
          );
        } catch (e) {
          onLogMessage('   Expected error for invalid mapping: $e');
        }
      }

      // 尝试解析无效域名
      try {
        await _dnsService.resolveDomain('invalid.domain.test');
      } catch (e) {
        onLogMessage('   Expected error for invalid domain: $e');
      }

      // 6. 性能测试
      onLogMessage('6. Testing performance...');
      
      if (isInitialized) {
        final stopwatch = Stopwatch()..start();
        
        // 并发解析多个域名
        final domains = [
          'www.taobao.com',
          'www.douyin.com', 
          'www.baidu.com',
          'www.qq.com',
          'www.weibo.com',
        ];
        
        final futures = domains.map((domain) => _dnsService.resolveDomain(domain));
        final results = await Future.wait(futures);
        
        stopwatch.stop();
        onLogMessage('   Concurrent resolution of ${domains.length} domains: ${stopwatch.elapsedMilliseconds}ms');
        for (int i = 0; i < domains.length; i++) {
          onLogMessage('     ${domains[i]} -> ${results[i]}');
        }
      }

      onResultUpdate('高级功能测试完成，请查看日志了解详细信息');
      onLogMessage('Advanced features test completed successfully!');

    } catch (e) {
      onResultUpdate('高级功能测试错误: $e');
      onLogMessage('Advanced features test error: $e');
    }
  }

  /// 测试配置选项
  Future<void> testConfigurationOptions() async {
    onLogMessage('Testing different configuration options...');

    try {
      // 1. 测试不同的DNS配置
      onLogMessage('1. Testing different DNS configurations...');

      final dnsConfigs = [
        DnsConfig(
          accountId: AliHttpDnsCredentials.accountId,
          accessKeyId: AliHttpDnsCredentials.accessKeyId,
          accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
          enableCache: true,
          maxCacheSize: 500,
          enableSpeedTest: true,
          timeout: 3,
        ),
        DnsConfig(
          accountId: AliHttpDnsCredentials.accountId,
          accessKeyId: AliHttpDnsCredentials.accessKeyId,
          accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
          enableCache: false,
          enableSpeedTest: false,
          timeout: 10,
          preloadDomains: ['www.taobao.com', 'www.douyin.com'],
        ),
      ];

      for (int i = 0; i < dnsConfigs.length; i++) {
        final config = dnsConfigs[i];
        onLogMessage('   Testing DNS config ${i + 1}:');
        onLogMessage('     Cache: ${config.enableCache}, Size: ${config.maxCacheSize}');
        onLogMessage('     Speed test: ${config.enableSpeedTest}, Timeout: ${config.timeout}s');
        onLogMessage('     Preload domains: ${config.preloadDomains.length}');
      }

      // 2. 测试不同的代理配置
      onLogMessage('2. Testing different proxy configurations...');

      final proxyConfigs = [
        ProxyConfig(
          portPool: [4041],
          startPort: 4042,
          endPort: 4045,
        ),
        ProxyConfig(
          portPool: [4041, 4042, 4043],
          startPort: 4044,
          endPort: 4050,
        ),
        ProxyConfig(
          startPort: 5000,
          endPort: 5010,
        ),
      ];

      for (int i = 0; i < proxyConfigs.length; i++) {
        final config = proxyConfigs[i];
        onLogMessage('   Testing proxy config ${i + 1}:');
        onLogMessage('     Port pool: ${config.portPool?.length ?? 0} ports');
        onLogMessage('     Port range: ${config.startPort}-${config.endPort}');
        onLogMessage('     Host: ${config.host}');
      }

      onLogMessage('Configuration options test completed!');

    } catch (e) {
      onLogMessage('Configuration options test error: $e');
    }
  }
}
