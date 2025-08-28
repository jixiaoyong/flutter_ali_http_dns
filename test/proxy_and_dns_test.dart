import 'package:flutter_ali_http_dns/src/models/dns_config.dart';
import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';
import 'package:flutter_ali_http_dns/src/services/dns_resolver.dart';
import 'package:flutter_ali_http_dns/src/services/proxy_server.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/lib/credentials.dart' as credentials;

void main() {
  // 确保Flutter环境已初始化，以便使用MethodChannel
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DnsResolver Tests', () {
    late DnsResolver dnsResolver;
    final dnsConfig = DnsConfig(
      accountId: credentials.AliHttpDnsCredentials.accountId,
      accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
      accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
      enableCache: true,
      maxCacheSize: 100,
      maxCacheTTL: 300,
    );

    setUp(() {
      dnsResolver = DnsResolver();
      dnsResolver.initialize(dnsConfig);
    });

    test('should initialize with config', () {
      expect(dnsResolver, isNotNull);
    });

    test('should resolve domain with system DNS fallback', () async {
      // 测试系统 DNS 解析
      final ip = await dnsResolver.resolveWithSystemDns('example.com');
      expect(ip, isNotEmpty);
      expect(ip != 'example.com', isTrue); // 应该解析为 IP 地址
    });

    test('should handle cache operations', () {
      // 测试缓存统计
      final stats = dnsResolver.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['size'], isA<int>());
      expect(stats['maxSize'], isA<int>());
    });

    test('should clear cache properly', () async {
      // 先解析一个域名
      await dnsResolver.resolveWithSystemDns('example.com');

      // 检查缓存统计
      final stats = dnsResolver.getCacheStats();
      expect(stats['size'], greaterThan(0));

      // 清理缓存
      dnsResolver.clearCache();

      // 再次检查缓存统计
      final newStats = dnsResolver.getCacheStats();
      expect(newStats['size'], 0);
    });

    test('should handle network unavailability gracefully', () async {
      // 测试网络不可用的情况
      // 这里我们通过解析一个不存在的域名来模拟网络问题
      final ip = await dnsResolver
          .resolve('invalid-domain-that-does-not-exist-12345.com');
      // 由于系统DNS可能会返回一个IP（比如NXDOMAIN被重定向），我们只验证返回的不是原始域名
      expect(ip, isNotEmpty);
      expect(ip != 'invalid-domain-that-does-not-exist-12345.com', isTrue);
    });
  });

  group('ProxyServer Basic Tests', () {
    test('should create proxy server with config', () {
      final config = ProxyConfig(portPool: [4041]);
      final dnsResolver = DnsResolver();
      final proxyServer = ProxyServer(
        config: config,
        dnsResolver: dnsResolver,
      );

      expect(proxyServer, isNotNull);
      expect(proxyServer.config, equals(config));
    });

    test('should get listening ports', () {
      final config = ProxyConfig(portPool: [4041, 4042]);
      final dnsResolver = DnsResolver();
      final proxyServer = ProxyServer(
        config: config,
        dnsResolver: dnsResolver,
      );

      final ports = proxyServer.getListeningPorts();
      expect(ports, isEmpty); // 未启动时应该为空
    });

    test('should check if port is listening', () {
      final config = ProxyConfig(portPool: [4041]);
      final dnsResolver = DnsResolver();
      final proxyServer = ProxyServer(
        config: config,
        dnsResolver: dnsResolver,
      );

      final isListening = proxyServer.isPortListening(4041);
      expect(isListening, isFalse); // 未启动时应该为false
    });
  });

  group('Configuration Tests', () {
    test('should create valid DnsConfig', () {
      final config = DnsConfig(
        accountId: credentials.AliHttpDnsCredentials.accountId,
        accessKeyId: credentials.AliHttpDnsCredentials.accessKeyId,
        accessKeySecret: credentials.AliHttpDnsCredentials.accessKeySecret,
        enableCache: true,
        maxCacheSize: 100,
      );

      expect(config.accountId, equals(credentials.AliHttpDnsCredentials.accountId));
      expect(config.enableCache, isTrue);
      expect(config.maxCacheSize, equals(100));
    });

    test('should create valid ProxyConfig', () {
      final config = ProxyConfig(
        portPool: [4041, 4042],
        enabled: true,
        host: 'localhost',
      );

      expect(config.portPool, equals([4041, 4042]));
      expect(config.enabled, isTrue);
      expect(config.host, equals('localhost'));
    });
  });
}
