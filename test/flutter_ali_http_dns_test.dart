import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns/src/models/dns_config.dart';
import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';

void main() {
  group('FlutterAliHttpDns Tests', () {
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

    test('should create DnsConfig with default values', () {
      final config = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
      );

      expect(config.accountId, equals('test_account'));
      expect(config.accessKeyId, equals('test_key_id'));
      expect(config.accessKeySecret, equals('test_secret'));
      expect(config.enableCache, isTrue);
      expect(config.maxCacheSize, equals(100));
      expect(config.maxNegativeCache, equals(30));
      expect(config.enableIPv6, isFalse);
      expect(config.enableShort, isFalse);
      expect(config.enableSpeedTest, isTrue);
      expect(config.preloadDomains, isEmpty);
      expect(config.keepAliveDomains, isEmpty);
      expect(config.timeout, equals(3));
      expect(config.maxCacheTTL, equals(3600));
      expect(config.ispEnable, isTrue);
      expect(config.speedPort, equals(80));
    });

    test('should create DnsConfig with custom values', () {
      final config = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
        enableCache: false,
        maxCacheSize: 200,
        maxNegativeCache: 60,
        enableIPv6: true,
        enableShort: true,
        enableSpeedTest: false,
        preloadDomains: ['www.example.com', 'api.example.com'],
        keepAliveDomains: ['www.example.com'],
        timeout: 5,
        maxCacheTTL: 7200,
        ispEnable: false,
        speedPort: 443,
      );

      expect(config.accountId, equals('test_account'));
      expect(config.accessKeyId, equals('test_key_id'));
      expect(config.accessKeySecret, equals('test_secret'));
      expect(config.enableCache, isFalse);
      expect(config.maxCacheSize, equals(200));
      expect(config.maxNegativeCache, equals(60));
      expect(config.enableIPv6, isTrue);
      expect(config.enableShort, isTrue);
      expect(config.enableSpeedTest, isFalse);
      expect(config.preloadDomains, equals(['www.example.com', 'api.example.com']));
      expect(config.keepAliveDomains, equals(['www.example.com']));
      expect(config.timeout, equals(5));
      expect(config.maxCacheTTL, equals(7200));
      expect(config.ispEnable, isFalse);
      expect(config.speedPort, equals(443));
    });

    test('should create ProxyConfig with default values', () {
      final config = ProxyConfig();
      expect(config.portPool, isNull);
      expect(config.startPort, isNull);
      expect(config.endPort, isNull);
      expect(config.enabled, isTrue);
      expect(config.host, equals('localhost'));
    });

    test('should create ProxyConfig with custom values', () {
      final config = ProxyConfig(
        portPool: [4041, 4042],
        startPort: 4043,
        endPort: 4050,
        enabled: false,
        host: '127.0.0.1',
      );
      expect(config.portPool, equals([4041, 4042]));
      expect(config.startPort, equals(4043));
      expect(config.endPort, equals(4050));
      expect(config.enabled, isFalse);
      expect(config.host, equals('127.0.0.1'));
    });

    test('should serialize DnsConfig to JSON', () {
      final config = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
        preloadDomains: ['www.example.com'],
        keepAliveDomains: ['www.example.com'],
      );

      final json = config.toJson();
      expect(json['accountId'], equals('test_account'));
      expect(json['accessKeyId'], equals('test_key_id'));
      expect(json['accessKeySecret'], equals('test_secret'));
      expect(json['preloadDomains'], equals(['www.example.com']));
      expect(json['keepAliveDomains'], equals(['www.example.com']));
      expect(json['enableCache'], isTrue);
      expect(json['maxCacheSize'], equals(100));
      expect(json['maxNegativeCache'], equals(30));
      expect(json['enableIPv6'], isFalse);
      expect(json['enableShort'], isFalse);
      expect(json['enableSpeedTest'], isTrue);
      expect(json['timeout'], equals(3));
      expect(json['maxCacheTTL'], equals(3600));
      expect(json['ispEnable'], isTrue);
      expect(json['speedPort'], equals(80));
    });

    test('should serialize ProxyConfig to JSON', () {
      final config = ProxyConfig(
        portPool: [4041, 4042],
        startPort: 4043,
        endPort: 4050,
        enabled: false,
        host: '127.0.0.1',
      );

      final json = config.toJson();

      expect(json['portPool'], equals([4041, 4042]));
      expect(json['startPort'], equals(4043));
      expect(json['endPort'], equals(4050));
      expect(json['enabled'], isFalse);
      expect(json['host'], equals('127.0.0.1'));
    });

    test('should deserialize DnsConfig from JSON', () {
      final json = {
        'accountId': 'test_account',
        'accessKeyId': 'test_key_id',
        'accessKeySecret': 'test_secret',
        'enableCache': false,
        'maxCacheSize': 200,
        'maxNegativeCache': 60,
        'enableIPv6': true,
        'enableShort': true,
        'enableSpeedTest': false,
        'preloadDomains': ['www.example.com', 'api.example.com'],
        'keepAliveDomains': ['www.example.com'],
        'timeout': 5,
        'maxCacheTTL': 7200,
        'ispEnable': false,
        'speedPort': 443,
      };

      final config = DnsConfig.fromJson(json);
      expect(config.accountId, equals('test_account'));
      expect(config.accessKeyId, equals('test_key_id'));
      expect(config.accessKeySecret, equals('test_secret'));
      expect(config.enableCache, isFalse);
      expect(config.maxCacheSize, equals(200));
      expect(config.maxNegativeCache, equals(60));
      expect(config.enableIPv6, isTrue);
      expect(config.enableShort, isTrue);
      expect(config.enableSpeedTest, isFalse);
      expect(config.preloadDomains, equals(['www.example.com', 'api.example.com']));
      expect(config.keepAliveDomains, equals(['www.example.com']));
      expect(config.timeout, equals(5));
      expect(config.maxCacheTTL, equals(7200));
      expect(config.ispEnable, isFalse);
      expect(config.speedPort, equals(443));
    });

    test('should deserialize ProxyConfig from JSON', () {
      final json = {
        'portPool': [4041, 4042],
        'startPort': 4043,
        'endPort': 4050,
        'enabled': false,
        'host': '127.0.0.1',
      };

      final config = ProxyConfig.fromJson(json);

      expect(config.portPool, equals([4041, 4042]));
      expect(config.startPort, equals(4043));
      expect(config.endPort, equals(4050));
      expect(config.enabled, isFalse);
      expect(config.host, equals('127.0.0.1'));
    });

    test('should handle DnsConfig equality', () {
      final config1 = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
      );
      
      final config2 = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should handle ProxyConfig equality', () {
      final config1 = ProxyConfig(
        portPool: [4041, 4042],
        startPort: 4043,
        endPort: 4050,
        enabled: false,
        host: '127.0.0.1',
      );

      final config2 = ProxyConfig(
        portPool: [4041, 4042],
        startPort: 4043,
        endPort: 4050,
        enabled: false,
        host: '127.0.0.1',
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should copy DnsConfig with changes', () {
      final original = DnsConfig(
        accountId: 'test_account',
        accessKeyId: 'test_key_id',
        accessKeySecret: 'test_secret',
      );

      final modified = original.copyWith(
        enableCache: false,
        maxCacheSize: 200,
        preloadDomains: ['www.example.com'],
      );

      expect(modified.accountId, equals(original.accountId));
      expect(modified.accessKeyId, equals(original.accessKeyId));
      expect(modified.accessKeySecret, equals(original.accessKeySecret));
      expect(modified.enableCache, isFalse);
      expect(modified.maxCacheSize, equals(200));
      expect(modified.preloadDomains, equals(['www.example.com']));
      expect(modified.enableCache, isNot(equals(original.enableCache)));
    });

    test('should copy ProxyConfig with changes', () {
      final original = ProxyConfig(
        portPool: [4041],
        startPort: 4042,
        endPort: 4045,
        enabled: true,
        host: 'localhost',
      );

      final copied = original.copyWith(
        portPool: [4043, 4044],
        startPort: 4045,
        endPort: 4050,
        enabled: false,
        host: '127.0.0.1',
      );

      expect(copied.portPool, equals([4043, 4044]));
      expect(copied.startPort, equals(4045));
      expect(copied.endPort, equals(4050));
      expect(copied.enabled, isFalse);
      expect(copied.host, equals('127.0.0.1'));

      // Original should remain unchanged
      expect(original.portPool, equals([4041]));
      expect(original.startPort, equals(4042));
      expect(original.endPort, equals(4045));
      expect(original.enabled, isTrue);
      expect(original.host, equals('localhost'));
    });
  });
}
