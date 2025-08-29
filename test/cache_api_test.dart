import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

void main() {
  group('Cache API Tests', () {
    late FlutterAliHttpDns dns;

    setUp(() {
      dns = FlutterAliHttpDns.instance;
    });

    test('should get cache size directly from FlutterAliHttpDns', () {
      // 即使未初始化，也应该返回0
      final size = dns.cacheSize;
      expect(size, equals(0));
    });

    test('should get max cache size directly from FlutterAliHttpDns', () {
      // 即使未初始化，也应该返回0
      final maxSize = dns.maxCacheSize;
      expect(maxSize, equals(0));
    });

    test('should check cache enabled status', () {
      final isEnabled = dns.isCacheEnabled;
      expect(isEnabled, isA<bool>());
    });

    test('should clear cache through FlutterAliHttpDns', () {
      // 这个方法需要初始化，但我们只是测试API存在
      expect(dns.clearCache, isA<Function>());
    });
  });
}
