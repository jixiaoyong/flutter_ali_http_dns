import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 快速测试模块 - 基本的DNS解析和代理功能测试
class QuickTest {
  static Future<void> testBasicFunctionality() async {
    print('=== 快速测试基本功能 ===');
    
    try {
      // 1. 初始化
      final dnsConfig = DnsConfig(
        accountId: 'test',
        accessKeyId: 'test',
        accessKeySecret: 'test',
        enableCache: true,
        maxCacheSize: 100,
        maxCacheTTL: 300,
        preloadDomains: [],
      );
      
      await FlutterAliHttpDns.instance.initialize(dnsConfig);
      print('✅ DNS服务初始化成功');
      
      // 2. 启动代理
      await FlutterAliHttpDns.instance.startProxy();
      print('✅ 代理服务器启动成功');
      
      // 3. 测试DNS解析
      print('测试DNS解析...');
      final testDomains = ['www.google.com', 'www.github.com', 'www.baidu.com'];
      
      for (final domain in testDomains) {
        try {
          final resolvedIp = await FlutterAliHttpDns.instance.resolveDomain(domain);
          print('   $domain -> $resolvedIp');
        } catch (e) {
          print('   $domain -> error: $e');
        }
      }
      
      // 4. 测试代理地址获取
      print('测试代理地址获取...');
      final proxyAddress = await FlutterAliHttpDns.instance.getProxyAddress();
      final http2Address = await FlutterAliHttpDns.instance.getHttp2ProxyAddress();
      final allAddresses = await FlutterAliHttpDns.instance.getAllProxyAddresses();
      
      print('   代理地址: $proxyAddress');
      print('   HTTP/2地址: $http2Address');
      print('   所有地址: ${allAddresses.join(', ')}');
      
      // 5. 测试代理配置
      print('测试代理配置...');
      final proxyConfig = await FlutterAliHttpDns.instance.getProxyConfigString();
      final dioConfig = await FlutterAliHttpDns.instance.getDioProxyConfig();
      
      print('   代理配置字符串: $proxyConfig');
      print('   Dio配置: $dioConfig');
      
      // 6. 测试端口管理
      print('测试端口管理...');
      final actualPorts = await FlutterAliHttpDns.instance.getActualPorts();
      final mainPort = await FlutterAliHttpDns.instance.getMainPort();
      
      print('   实际端口: ${actualPorts.join(', ')}');
      print('   主要端口: $mainPort');
      
      print('🎉 快速测试完成！');
      
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }
}
