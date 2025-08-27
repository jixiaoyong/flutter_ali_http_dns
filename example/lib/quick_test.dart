import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// 快速测试isSecure参数传递
class QuickTest {
  static Future<void> testIsSecure() async {
    print('=== 快速测试isSecure参数传递 ===');
    
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
      await FlutterAliHttpDns.instance.startProxy();
      
      // 2. 注册不安全映射
      print('注册不安全映射...');
      final localPort = await FlutterAliHttpDns.instance.registerMapping(
        targetPort: 7349,
        targetDomain: 'api.example.com',
        name: 'Test Insecure',
        isSecure: false,
      );
      
      if (localPort != null) {
        print('✅ 注册成功，端口: $localPort');
        
        // 3. 立即验证映射
        final mapping = await FlutterAliHttpDns.instance.getMapping(localPort);
        if (mapping != null) {
          print('✅ 映射信息:');
          print('   - isSecure: ${mapping['isSecure']}');
          print('   - targetDomain: ${mapping['targetDomain']}');
          print('   - targetPort: ${mapping['targetPort']}');
          
          if (mapping['isSecure'] == false) {
            print('🎉 isSecure参数传递成功！');
          } else {
            print('❌ isSecure参数传递失败！');
          }
        } else {
          print('❌ 无法获取映射信息');
        }
      } else {
        print('❌ 注册失败');
      }
      
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }
}
