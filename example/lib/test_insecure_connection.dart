import 'dart:io';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'nakama_config.dart';

/// 测试不安全连接的功能
class TestInsecureConnection {
  static Future<void> testInsecureGrpcConnection() async {
    print('=== 测试不安全gRPC连接 ===');
    
    try {
      // 1. 初始化DNS服务
      print('1. 初始化DNS服务...');
      final dnsConfig = DnsConfig(
        accountId: 'your_account_id',
        accessKeyId: 'your_access_key_id',
        accessKeySecret: 'your_access_key_secret',
        enableCache: true,
        maxCacheSize: 100,
        maxCacheTTL: 300,
        preloadDomains: [],
      );
      
      final initialized = await FlutterAliHttpDns.instance.initialize(dnsConfig);
      if (!initialized) {
        print('❌ DNS服务初始化失败');
        return;
      }
      print('✅ DNS服务初始化成功');
      
      // 2. 启动代理服务器
      print('2. 启动代理服务器...');
      final proxyConfig = ProxyConfig(
        host: '127.0.0.1',
        startPort: 4041,
        endPort: 4141,
        enabled: true,
      );
      
      final proxyStarted = await FlutterAliHttpDns.instance.startProxy(config: proxyConfig);
      if (!proxyStarted) {
        print('❌ 代理服务器启动失败');
        return;
      }
      print('✅ 代理服务器启动成功');
      
      // 3. 注册不安全的gRPC映射
      print('3. 注册不安全的gRPC映射...');
      final localPort = await NakamaConfig.registerInsecureGrpcMapping();
      if (localPort == null) {
        print('❌ gRPC映射注册失败');
        return;
      }
      print('✅ gRPC映射注册成功，本地端口: $localPort');
      
      // 4. 验证映射信息
      print('4. 验证映射信息...');
      final mapping = await FlutterAliHttpDns.instance.getMapping(localPort);
      if (mapping != null) {
        print('✅ 映射信息: $mapping');
        print('   - isSecure: ${mapping['isSecure']}');
        print('   - targetDomain: ${mapping['targetDomain']}');
        print('   - targetPort: ${mapping['targetPort']}');
      } else {
        print('❌ 无法获取映射信息');
      }
      
      // 5. 测试连接（这里只是验证配置，实际连接测试需要gRPC客户端）
      print('5. 配置验证完成');
      print('   现在可以使用以下地址连接:');
      print('   - 本地地址: 127.0.0.1:$localPort');
      print('   - 目标地址: ${NakamaConfig.nakamaGrpcUrl}');
      print('   - 连接类型: 不安全 (HTTP/2 over cleartext)');
      
    } catch (e) {
      print('❌ 测试过程中发生错误: $e');
    }
  }
  
  static Future<void> testSecureConnection() async {
    print('\n=== 测试安全连接 ===');
    
    try {
      // 注册安全的HTTP映射
      final localPort = await NakamaConfig.registerSecureHttpMapping();
      if (localPort == null) {
        print('❌ 安全HTTP映射注册失败');
        return;
      }
      print('✅ 安全HTTP映射注册成功，本地端口: $localPort');
      
      // 验证映射信息
      final mapping = await FlutterAliHttpDns.instance.getMapping(localPort);
      if (mapping != null) {
        print('✅ 映射信息: $mapping');
        print('   - isSecure: ${mapping['isSecure']}');
      }
      
    } catch (e) {
      print('❌ 测试过程中发生错误: $e');
    }
  }
  
  static Future<void> runAllTests() async {
    print('开始测试HTTP/2安全连接功能...\n');
    
    await testInsecureGrpcConnection();
    await testSecureConnection();
    
    print('\n=== 测试完成 ===');
    print('如果看到"isSecure: false"的映射信息，说明不安全连接配置成功！');
  }
}
