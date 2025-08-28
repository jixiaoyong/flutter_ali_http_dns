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
      
      // 3. 再次解析相同域名（应该从缓存获取）
      print('\n3. 再次解析相同域名（应该从缓存获取）...');
      final ip2 = await _dnsService.resolveDomainNullable(domain1);
      print('域名: $domain1 -> IP: $ip2');
      
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
      
      // 5. 再次解析域名（缓存已清除，应该重新解析）
      print('\n5. 再次解析域名（缓存已清除）...');
      final ip3 = await _dnsService.resolveDomainNullable(domain1);
      print('域名: $domain1 -> IP: $ip3');
      
      // 6. 测试禁用缓存的配置
      print('\n6. 测试禁用缓存的配置...');
      final noCacheConfig = DnsConfig(
        accountId: AliHttpDnsCredentials.accountId,
        accessKeyId: AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
        enableCache: false, // 禁用缓存
        maxCacheSize: 100,
        enableSpeedTest: true,
        timeout: 5,
        preloadDomains: ['www.taobao.com'],
        keepAliveDomains: ['www.taobao.com'],
      );
      
      final reinitSuccess = await _dnsService.initialize(noCacheConfig);
      if (reinitSuccess) {
        print('✅ 禁用缓存的DNS服务初始化成功');
        
        // 测试域名解析（不会缓存）
        final domain2 = 'www.taobao.com';
        final ip4 = await _dnsService.resolveDomainNullable(domain2);
        print('域名: $domain2 -> IP: $ip4');
      } else {
        print('❌ 禁用缓存的DNS服务初始化失败');
      }
      
      print('\n=== 缓存功能测试完成 ===');
      
    } catch (e) {
      print('❌ 测试过程中发生错误: $e');
    } finally {
      // 清理资源
      await _dnsService.dispose();
    }
  }
}
