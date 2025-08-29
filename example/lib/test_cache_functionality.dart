import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'credentials.dart';

/// 测试缓存功能的工具类
class CacheFunctionalityTest {
  static final FlutterAliHttpDns _dnsService = FlutterAliHttpDns();
  
  /// 测试缓存功能
  static Future<void> runTest() async {
    print('=== 开始测试缓存功能 ===');
    
    try {
      // 1. 初始化DNS服务（启用缓存）
      print('1. 初始化DNS服务（启用缓存）...');
      final config = DnsConfig(
        accountId: AliHttpDnsCredentials.accountId,
        accessKeyId: AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
        enableCache: true,
        maxCacheSize: 100,
        enableSpeedTest: true,
        timeout: 5,
        preloadDomains: ['www.aliyun.com'],
        keepAliveDomains: ['www.aliyun.com'],
      );
      
      final success = await _dnsService.initialize(config);
      if (!success) {
        print('❌ DNS服务初始化失败');
        return;
      }
      print('✅ DNS服务初始化成功');
      
      // 2. 测试域名解析（应该会缓存结果）
      print('\n2. 测试域名解析（第一次，应该会缓存）...');
      final domain1 = 'www.aliyun.com';
      final ip1 = await _dnsService.resolveDomainNullable(domain1);
      print('域名: $domain1 -> IP: $ip1');
      
      // 2.1. 检查缓存状态
      print('\n2.1. 检查缓存状态...');
      print('缓存是否启用: ${_dnsService.isCacheEnabled}');
      print('当前缓存大小: ${_dnsService.cacheSize}');
      print('最大缓存大小: ${_dnsService.maxCacheSize}');
      
      // 3. 再次解析相同域名（应该从缓存获取）
      print('\n3. 再次解析相同域名（应该从缓存获取）...');
      final ip2 = await _dnsService.resolveDomainNullable(domain1);
      print('域名: $domain1 -> IP: $ip2');
      
      // 3.1. 再次检查缓存状态
      print('\n3.1. 再次检查缓存状态...');
      print('缓存是否启用: ${_dnsService.isCacheEnabled}');
      print('当前缓存大小: ${_dnsService.cacheSize}');
      print('最大缓存大小: ${_dnsService.maxCacheSize}');
      
      // 4. 清除缓存
      print('\n4. 清除DNS缓存...');
      final clearSuccess = await _dnsService.clearCache();
      if (clearSuccess) {
        print('✅ DNS缓存清除成功');
      } else {
        print('❌ DNS缓存清除失败');
      }
      
      // 4.1. 清除指定域名缓存
      print('\n4.1. 清除指定域名缓存...');
      final clearSpecificSuccess = await _dnsService.clearCache(['www.aliyun.com']);
      if (clearSpecificSuccess) {
        print('✅ 指定域名缓存清除成功');
      } else {
        print('❌ 指定域名缓存清除失败');
      }
      
      // 4.2. 检查清除后的缓存状态
      print('\n4.2. 检查清除后的缓存状态...');
      print('缓存是否启用: ${_dnsService.isCacheEnabled}');
      print('当前缓存大小: ${_dnsService.cacheSize}');
      print('最大缓存大小: ${_dnsService.maxCacheSize}');
      
      // 5. 再次解析域名（缓存已清除，应该重新解析）
      print('\n5. 再次解析域名（缓存已清除）...');
      final ip3 = await _dnsService.resolveDomainNullable(domain1);
      print('域名: $domain1 -> IP: $ip3');
      
      // 6. 测试动态切换缓存状态
      print('\n6. 测试动态切换缓存状态...');
      print('当前缓存状态: ${_dnsService.isCacheEnabled}');
      
      // 禁用缓存
      await _dnsService.setEnableCache(false);
      print('禁用缓存后状态: ${_dnsService.isCacheEnabled}');
      
      // 解析域名（不会缓存）
      final domain2 = 'www.taobao.com';
      final ip4 = await _dnsService.resolveDomainNullable(domain2);
      print('域名: $domain2 -> IP: $ip4');
      print('禁用缓存时的缓存大小: ${_dnsService.cacheSize}');
      
      // 重新启用缓存
      await _dnsService.setEnableCache(true);
      print('重新启用缓存后状态: ${_dnsService.isCacheEnabled}');
      
      // 再次解析域名（会缓存）
      final ip5 = await _dnsService.resolveDomainNullable(domain2);
      print('域名: $domain2 -> IP: $ip5');
      print('启用缓存时的缓存大小: ${_dnsService.cacheSize}');
      
      print('\n=== 缓存功能测试完成 ===');
      
    } catch (e) {
      print('❌ 测试过程中发生错误: $e');
    }
  }
}
