import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 端口管理测试模块 - 负责端口冲突、动态映射和端口管理测试
class PortManagementTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final bool isInitialized;

  PortManagementTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.isInitialized,
  }) : _dnsService = dnsService;

  /// 测试端口冲突
  Future<void> testPortConflict() async {
    onLogMessage('Testing port conflict scenario...');

    // 模拟端口冲突：尝试启动两个代理服务器
    try {
      final proxyConfig1 = ProxyConfig(portPool: [4041]);
      final proxyConfig2 = ProxyConfig(portPool: [4041]); // 相同端口

      // 启动第一个代理
      final success1 = await _dnsService.startProxy(config: proxyConfig1);
      onLogMessage('First proxy start: ${success1 ? 'Success' : 'Failed'}');

      // 尝试启动第二个代理（应该会触发端口冲突处理）
      final success2 = await _dnsService.startProxy(config: proxyConfig2);
      onLogMessage('Second proxy start: ${success2 ? 'Success' : 'Failed'}');

      if (success2) {
        final address = await _dnsService.getProxyAddress();
        onLogMessage('Second proxy started on different port: $address');
      }
    } catch (e) {
      onLogMessage('Port conflict test error: $e');
    }
  }

  /// 测试动态端口映射
  Future<void> testDynamicMapping() async {
    onLogMessage('Testing dynamic port mapping...');

    try {
      // 直接注册多个服务映射
      final services = [
        {'name': 'API Server', 'targetPort': 7350, 'domain': 'api.game-service.com'},
        {'name': 'Chat Server', 'targetPort': null, 'domain': 'chat.game-service.com'},
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
          isSecure: service['isSecure'] as bool? ?? true, // 默认使用安全连接
        );
        
        if (localPort != null) {
          successfulMappings[serviceName] = localPort;
          onLogMessage('Register mapping $localPort->${targetPort ?? localPort}: Success');
        } else {
          onLogMessage('Register mapping for $serviceName: Failed');
        }
      }

      // 获取所有映射的详细信息
      final allMappings = await _dnsService.getAllMappings();
      onLogMessage('All mappings: ${allMappings.length}');
      for (final entry in allMappings.entries) {
        final mapping = entry.value;
        onLogMessage('  Port ${entry.key}: ${mapping['targetDomain']}:${mapping['targetPort']}');
      }

      // 获取特定映射
      if (successfulMappings.isNotEmpty) {
        final firstService = successfulMappings.keys.first;
        final firstPort = successfulMappings[firstService]!;
        final mapping1 = await _dnsService.getMapping(firstPort);
        if (mapping1 != null) {
          onLogMessage('Mapping for $firstPort: ${mapping1['targetDomain']}:${mapping1['targetPort']}');
        }
      }

      // 移除映射
      if (successfulMappings.isNotEmpty) {
        final firstService = successfulMappings.keys.first;
        final firstPort = successfulMappings[firstService]!;
        final removeSuccess = await _dnsService.removeMapping(firstPort);
        onLogMessage('Remove mapping $firstPort: ${removeSuccess ? 'Success' : 'Failed'}');

        // 验证移除
        final mappingAfterRemove = await _dnsService.getMapping(firstPort);
        onLogMessage('Mapping after remove: ${mappingAfterRemove != null ? 'Still exists' : 'Removed'}');
      }

    } catch (e) {
      onLogMessage('Dynamic mapping test error: $e');
    }
  }

  /// 测试端口管理
  Future<void> testPortManagement() async {
    onLogMessage('Testing port management features...');

    try {
      // 获取当前进程ID
      final currentPid = FlutterAliHttpDns.getCurrentProcessId();
      onLogMessage('Current process ID: $currentPid');

      // 获取SDK提供的端口信息
      final availablePorts = await _dnsService.getAvailablePorts();
      onLogMessage('Available ports from SDK: $availablePorts');

      if (availablePorts.isNotEmpty) {
        // 检查第一个可用端口的详细信息
        final firstPort = availablePorts[0];
        final portInfo = await FlutterAliHttpDns.getPortInfo(firstPort);
        onLogMessage('Port $firstPort info: $portInfo');

        // 检查是否被自己的应用占用
        final isOwnApp = await FlutterAliHttpDns.isPortUsedByOwnApp(firstPort);
        onLogMessage('Port $firstPort used by own app: $isOwnApp');
      }

      // 获取所有运行的代理端口
      final runningPorts = FlutterAliHttpDns.getRunningProxyPorts();
      onLogMessage('Currently running proxy ports: $runningPorts');

      // 测试单例模式
      onLogMessage('Testing singleton pattern...');

      // 尝试启动多个代理服务器
      for (int i = 0; i < 3; i++) {
        final config = ProxyConfig(portPool: [4041 + i]);
        final success = await _dnsService.startProxy(config: config);
        onLogMessage('Proxy ${i + 1} start: ${success ? 'Success' : 'Failed'}');

        if (success) {
          final address = await _dnsService.getProxyAddress();
          onLogMessage('Proxy ${i + 1} address: $address');
        }

        // 等待一下再启动下一个
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 显示最终状态
      final finalRunningPorts = FlutterAliHttpDns.getRunningProxyPorts();
      onLogMessage('Final running proxy ports: $finalRunningPorts');
      onLogMessage('Note: Only one proxy should be running due to singleton pattern');
    } catch (e) {
      onLogMessage('Port management test error: $e');
    }
  }

  /// 测试跨应用隔离
  Future<void> testCrossAppIsolation() async {
    onLogMessage('Testing cross-app isolation...');

    try {
      // 模拟不同应用的进程ID
      onLogMessage('Current app process ID: ${FlutterAliHttpDns.getCurrentProcessId()}');

      // 启动代理服务器
      final success = await _dnsService.startProxy(config: ProxyConfig(portPool: [4041]));
      onLogMessage('Proxy start: ${success ? 'Success' : 'Failed'}');

      if (success) {
        final address = await _dnsService.getProxyAddress();
        onLogMessage('Proxy address: $address');

        // 检查端口占用信息
        final portInfo = await FlutterAliHttpDns.getPortInfo(4041);
        onLogMessage('Port 4041 info: $portInfo');

        // 说明跨应用隔离
        onLogMessage('Cross-app isolation explanation:');
        onLogMessage('1. Each app has its own process ID');
        onLogMessage('2. Port conflicts are resolved per process');
        onLogMessage('3. Different apps can use the same port');
        onLogMessage('4. Only conflicts within the same app are handled');
      }
    } catch (e) {
      onLogMessage('Cross-app isolation test error: $e');
    }
  }
}
