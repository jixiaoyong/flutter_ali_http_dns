import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 测试新的解析方法
class ResolveMethodsTest {
  static Future<void> testResolveMethods() async {
    print('=== 测试新的解析方法 ===');
    
    try {
      // 初始化DNS服务
      final dnsConfig = DnsConfig(
        accountId: 'test',
        accessKeyId: 'test',
        accessKeySecret: 'test',
        enableCache: false,
        maxCacheSize: 100,
        enableSpeedTest: true,
        preloadDomains: [],
      );
      
      await FlutterAliHttpDns.instance.initialize(dnsConfig);
      print('✅ DNS服务初始化成功');
      
      // 测试正常域名
      final testDomain = 'www.google.com';
      
      // 测试 resolveDomainNullable 方法
      print('\n--- 测试 resolveDomainNullable 方法 ---');
      final nullableResult = await FlutterAliHttpDns.instance.resolveDomainNullable(testDomain);
      if (nullableResult != null) {
        print('✅ resolveDomainNullable 成功: $testDomain -> $nullableResult');
      } else {
        print('❌ resolveDomainNullable 失败: $testDomain -> null');
      }
      
      // 测试 resolveDomain 方法
      print('\n--- 测试 resolveDomain 方法 ---');
      final result = await FlutterAliHttpDns.instance.resolveDomain(testDomain);
      print('✅ resolveDomain 结果: $testDomain -> $result');
      
      // 测试无效域名
      final invalidDomain = 'invalid.domain.test';
      
      print('\n--- 测试无效域名 ---');
      final invalidNullableResult = await FlutterAliHttpDns.instance.resolveDomainNullable(invalidDomain);
      if (invalidNullableResult != null) {
        print('✅ 无效域名 resolveDomainNullable 成功: $invalidDomain -> $invalidNullableResult');
      } else {
        print('❌ 无效域名 resolveDomainNullable 失败: $invalidDomain -> null');
      }
      
      final invalidResult = await FlutterAliHttpDns.instance.resolveDomain(invalidDomain);
      print('✅ 无效域名 resolveDomain 结果: $invalidDomain -> $invalidResult');
      
      // 测试禁用系统DNS回退
      print('\n--- 测试禁用系统DNS回退 ---');
      final noFallbackResult = await FlutterAliHttpDns.instance.resolveDomainNullable(
        invalidDomain,
        enableSystemDnsFallback: false,
      );
      if (noFallbackResult != null) {
        print('✅ 禁用回退 resolveDomainNullable 成功: $invalidDomain -> $noFallbackResult');
      } else {
        print('❌ 禁用回退 resolveDomainNullable 失败: $invalidDomain -> null');
      }
      
      final noFallbackResult2 = await FlutterAliHttpDns.instance.resolveDomain(
        invalidDomain,
        enableSystemDnsFallback: false,
      );
      print('✅ 禁用回退 resolveDomain 结果: $invalidDomain -> $noFallbackResult2');
      
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }
}
