import 'dart:io';
import 'dart:convert';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import '../nakama_config.dart';

/// Nakama场景测试模块 - 负责游戏SDK代理测试
class NakamaTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final bool isProxyRunning;

  NakamaTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试Nakama代理
  Future<void> testNakamaProxy() async {
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
      onResultUpdate('正在测试 Nakama 代理...');
      onLogMessage('使用Nakama服务器: ${NakamaConfig.nakamaBaseUrl}');

      // 注册Nakama服务映射
      final nakamaServices = [
        {'name': 'nakama-http', 'targetPort': NakamaConfig.nakamaPortHttp, 'isSecure': true},
        {'name': 'nakama-grpc', 'targetPort': NakamaConfig.nakamaPortGrpc, 'isSecure': false},
      ];
      
      final successfulMappings = <String, int>{};
      
      for (final service in nakamaServices) {
        final serviceName = service['name'] as String;
        final targetPort = service['targetPort'] as int;
        
        onLogMessage('正在注册 $serviceName 映射到 ${NakamaConfig.nakamaBaseUrl}:$targetPort');
        
        final localPort = await _dnsService.registerMapping(
          targetPort: targetPort,
          targetDomain: NakamaConfig.nakamaBaseUrl,
          name: serviceName,
          description: '$serviceName service mapping',
          isSecure: service['isSecure'] as bool,
        );
        
        if (localPort != null) {
          successfulMappings[serviceName] = localPort;
          onLogMessage('Register $serviceName on port $localPort: Success');
        } else {
          onLogMessage('Register $serviceName: Failed');
        }
      }

      if (successfulMappings.isEmpty) {
        onResultUpdate('没有成功注册任何端口映射');
        return;
      }

      final client = HttpClient();
      await _dnsService.configureHttpClient(client);

      // 测试成功的映射
      final testResults = <String>[];
      
      for (final entry in successfulMappings.entries) {
        final serviceName = entry.key;
        final localPort = entry.value;
        
        try {
          onLogMessage('正在测试 $serviceName 连接 (localhost:$localPort)');
          
          // 测试端口连接
          final request = await client.getUrl(Uri.parse('http://localhost:$localPort'));
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();
          
          testResults.add('$serviceName ($localPort): 状态码 ${response.statusCode}, 响应长度 ${responseBody.length}');
          onLogMessage('$serviceName 测试成功: 状态码 ${response.statusCode}');
        } catch (e) {
          testResults.add('$serviceName ($localPort): 连接失败 - $e');
          onLogMessage('$serviceName 测试失败: $e');
        }
      }

      // 获取映射信息
      final allMappings = await _dnsService.getAllMappings();

      onResultUpdate(
        'Nakama 代理测试完成\n'
        '服务器: ${NakamaConfig.nakamaBaseUrl}\n'
        '成功注册的映射: ${successfulMappings.length}\n'
        '${testResults.join('\n')}\n'
        '端口映射详情: ${allMappings.length} 个映射'
      );
      onLogMessage('Nakama 代理测试成功 - 自动端口分配正常工作');

      // 清理映射
      for (final entry in successfulMappings.entries) {
        final serviceName = entry.key;
        final localPort = entry.value;
        final success = await _dnsService.removeMapping(localPort);
        onLogMessage('Remove $serviceName (port $localPort): ${success ? 'Success' : 'Failed'}');
      }

    } catch (e) {
      onResultUpdate('Nakama 代理测试错误: $e');
      onLogMessage('Nakama 代理测试失败: $e');
    }
  }
}
