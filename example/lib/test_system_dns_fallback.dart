import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 测试系统DNS回退功能
class SystemDnsFallbackTest {
  static Future<void> runTest({required bool enableSystemDnsFallback}) async {
    final status = enableSystemDnsFallback ? "启用" : "禁用";
    print('=== 系统DNS回退功能测试 (当前设置为: $status) ===');

    try {
      // 检查服务是否已初始化
      if (!FlutterAliHttpDns.instance.isInitialized) {
        print('❌ DNS服务未初始化，请先点击 \"Initialize DNS\"');
        return;
      }
      print('✅ DNS服务已初始化');

      // 测试域名，包含一个可能失败的域名
      const testDomains = ['www.aliyun.com', 'www.taobao.com', 'nonexistent-domain-12345.com'];

      print('\n2. 开始使用当前配置 ($status) 解析域名...');
      for (final domain in testDomains) {
        final result = await FlutterAliHttpDns.instance.resolveDomainNullable(
          domain,
          enableSystemDnsFallback: enableSystemDnsFallback,
        );
        if (result != null) {
          print('✅ $domain -> $result');
        } else {
          print('❌ $domain -> null');
        }
      }

      print('\n=== 测试完成 ===');

    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }
}