import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ali_http_dns/src/services/cache_manager.dart';

void main() {
  group('CacheManager Tests', () {
    late CacheManager cacheManager;

    setUp(() {
      cacheManager = CacheManager.instance;
      cacheManager.reset(); // 重置状态
    });

    test('should start with cache disabled', () {
      expect(cacheManager.isEnabled, isFalse);
    });

    test('should set cache state', () {
      cacheManager.setEnabled(true);
      expect(cacheManager.isEnabled, isTrue);

      cacheManager.setEnabled(false);
      expect(cacheManager.isEnabled, isFalse);
    });

    test('should be singleton', () {
      final instance1 = CacheManager.instance;
      final instance2 = CacheManager.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should configure cache parameters', () {
      cacheManager.configure(maxCacheSize: 200, maxCacheTTL: 7200);
      final stats = cacheManager.getCacheStats();
      expect(stats['maxSize'], equals(200));
    });

    test('should cache and retrieve IP when enabled', () {
      cacheManager.setEnabled(true);
      cacheManager.cacheIp('example.com', '93.184.216.34');

      final cachedIp = cacheManager.getCachedIp('example.com');
      expect(cachedIp, equals('93.184.216.34'));
    });

    test('should not cache when disabled', () {
      cacheManager.setEnabled(false);
      cacheManager.cacheIp('example.com', '93.184.216.34');

      final cachedIp = cacheManager.getCachedIp('example.com');
      expect(cachedIp, isNull);
    });

    test('should clear all cache', () {
      cacheManager.setEnabled(true);
      cacheManager.cacheIp('example.com', '93.184.216.34');
      cacheManager.cacheIp('google.com', '142.250.190.78');

      expect(cacheManager.getCachedIp('example.com'), isNotNull);
      expect(cacheManager.getCachedIp('google.com'), isNotNull);

      cacheManager.clearCache();

      expect(cacheManager.getCachedIp('example.com'), isNull);
      expect(cacheManager.getCachedIp('google.com'), isNull);
    });

    test('should clear specific hosts', () {
      cacheManager.setEnabled(true);
      cacheManager.cacheIp('example.com', '93.184.216.34');
      cacheManager.cacheIp('google.com', '142.250.190.78');

      cacheManager.clearHosts(['example.com']);

      expect(cacheManager.getCachedIp('example.com'), isNull);
      expect(cacheManager.getCachedIp('google.com'), isNotNull);
    });

    test('should manage retry count', () {
      cacheManager.setRetryCount('example.com', 3);
      expect(cacheManager.getRetryCount('example.com'), equals(3));

      cacheManager.removeRetryCount('example.com');
      expect(cacheManager.getRetryCount('example.com'), equals(0));
    });

    test('should get cache stats', () {
      cacheManager.setEnabled(true);
      cacheManager.cacheIp('example.com', '93.184.216.34');
      cacheManager.setRetryCount('google.com', 2);

      final stats = cacheManager.getCacheStats();
      expect(stats['size'], equals(1)); // 只有缓存的域名
      expect(stats['domains'], contains('example.com'));
      expect(stats['retryCount']['google.com'], equals(2));

      // 清理状态
      cacheManager.clearCache();
    });
  });
}
