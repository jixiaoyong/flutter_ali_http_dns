import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns/src/models/dns_config.dart';
import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';
import 'package:flutter_ali_http_dns/src/utils/logger.dart';
import '../example/lib/credentials.dart' as credentials;

void main() {
  group('FlutterAliHttpDns Core Tests', () {
    test('should create singleton instance', () {
      final instance1 = FlutterAliHttpDns.instance;
      final instance2 = FlutterAliHttpDns.instance;
      expect(instance1, equals(instance2));
    });

    test('should have correct initial state', () {
      final plugin = FlutterAliHttpDns.instance;
      expect(plugin.isInitialized, isFalse);
      expect(plugin.isProxyRunning, isFalse);
    });

    test('should create DnsConfig with default and custom values', () {
      // 测试默认配置
      final defaultConfig = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
      );

      expect(defaultConfig.accountId, equals(credentials.AliHttpDnsCredentials.accountId));
      expect(defaultConfig.enableCache, isTrue);
      expect(defaultConfig.maxCacheSize, equals(100));
      expect(defaultConfig.preloadDomains, isEmpty);

      // 测试自定义配置
      final customConfig = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
        enableCache: false,
        maxCacheSize: 200,
        preloadDomains: ['www.example.com'],
        timeout: 5,
      );

      expect(customConfig.enableCache, isFalse);
      expect(customConfig.maxCacheSize, equals(200));
      expect(customConfig.preloadDomains, equals(['www.example.com']));
      expect(customConfig.timeout, equals(5));
    });

    test('should create ProxyConfig with default and custom values', () {
      // 测试默认配置
      final defaultConfig = ProxyConfig();
      expect(defaultConfig.portPool, isNull);
      expect(defaultConfig.enabled, isTrue);
      expect(defaultConfig.host, equals('localhost'));

      // 测试自定义配置
      final customConfig = ProxyConfig(
        portPool: [4041, 4042],
        enabled: false,
        host: '127.0.0.1',
      );
      expect(customConfig.portPool, equals([4041, 4042]));
      expect(customConfig.enabled, isFalse);
      expect(customConfig.host, equals('127.0.0.1'));
    });

    test('should handle JSON serialization and deserialization', () {
      // 测试 DnsConfig JSON 序列化
      final dnsConfig = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
        enableCache: false,
        preloadDomains: ['www.example.com'],
      );

      final dnsJson = dnsConfig.toJson();
      final dnsConfigFromJson = DnsConfig.fromJson(dnsJson);
      expect(dnsConfigFromJson.accountId, equals(credentials.AliHttpDnsCredentials.accountId));
      expect(dnsConfigFromJson.enableCache, isFalse);

      // 测试 ProxyConfig JSON 序列化
      final proxyConfig = ProxyConfig(
        portPool: [4041, 4042],
        enabled: false,
        host: '127.0.0.1',
      );

      final proxyJson = proxyConfig.toJson();
      final proxyConfigFromJson = ProxyConfig.fromJson(proxyJson);
      expect(proxyConfigFromJson.portPool, equals([4041, 4042]));
      expect(proxyConfigFromJson.enabled, isFalse);
    });

    test('should handle config equality', () {
      final config1 = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
      );
      
      final config2 = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should handle proxy config equality', () {
      final config1 = ProxyConfig(
        portPool: [4041, 4042],
        enabled: false,
        host: '127.0.0.1',
      );

      final config2 = ProxyConfig(
        portPool: [4041, 4042],
        enabled: false,
        host: '127.0.0.1',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });
  });

  group('Logger Tests', () {
    test('should set log level', () {
      FlutterAliHttpDns.setLogLevel(LogLevel.debug);
      // 验证日志级别设置成功（通过检查没有异常）
      expect(true, isTrue);
    });

    test('should enable/disable logging', () {
      FlutterAliHttpDns.setLogEnabled(true);
      FlutterAliHttpDns.setLogEnabled(false);
      // 验证日志开关设置成功（通过检查没有异常）
      expect(true, isTrue);
    });
  });
}
