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

      expect(config.port, equals(4041));
      expect(config.host, equals('localhost'));
      expect(config.enabled, isTrue);
      expect(config.portMap, isEmpty);
      expect(config.fixedDomain, isEmpty);
    });

    test('should create ProxyConfig with custom values', () {
      final config = ProxyConfig(
        port: 8080,
        portMap: {'4041': 7350, '4042': 7349},
        fixedDomain: {'4041': 'api.game-service.com', '4042': 'chat.game-service.com'},
        enabled: false,
        host: '127.0.0.1',
      );

      expect(config.port, equals(8080));
      expect(config.host, equals('127.0.0.1'));
      expect(config.enabled, isFalse);
      expect(config.portMap, equals({'4041': 7350, '4042': 7349}));
      expect(config.fixedDomain, equals({'4041': 'api.game-service.com', '4042': 'chat.game-service.com'}));
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
        port: 8080,
        portMap: {'4041': 7350, '4042': 7349},
        fixedDomain: {'4041': 'api.game-service.com', '4042': 'chat.game-service.com'},
        enabled: true,
        host: 'localhost',
      );

      final json = config.toJson();
      expect(json['port'], equals(8080));
      expect(json['portMap'], equals({'4041': 7350, '4042': 7349}));
      expect(json['fixedDomain'], equals({'4041': 'api.game-service.com', '4042': 'chat.game-service.com'}));
      expect(json['enabled'], isTrue);
      expect(json['host'], equals('localhost'));
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
        'port': 8080,
        'portMap': {'4041': 7350, '4042': 7349},
        'fixedDomain': {'4041': 'api.game-service.com', '4042': 'chat.game-service.com'},
        'enabled': true,
        'host': 'localhost',
      };

      final config = ProxyConfig.fromJson(json);
      expect(config.port, equals(8080));
      expect(config.portMap, equals({'4041': 7350, '4042': 7349}));
      expect(config.fixedDomain, equals({'4041': 'api.game-service.com', '4042': 'chat.game-service.com'}));
      expect(config.enabled, isTrue);
      expect(config.host, equals('localhost'));
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
        port: 8080,
        portMap: {'4041': 7350},
        fixedDomain: {'4041': 'api.game-service.com'},
      );
      
      final config2 = ProxyConfig(
        port: 8080,
        portMap: {'4041': 7350},
        fixedDomain: {'4041': 'api.game-service.com'},
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
      final original = ProxyConfig();

      final modified = original.copyWith(
        port: 8080,
        portMap: {'4041': 7350},
        fixedDomain: {'4041': 'api.game-service.com'},
      );

      expect(modified.port, equals(8080));
      expect(modified.portMap, equals({'4041': 7350}));
      expect(modified.fixedDomain, equals({'4041': 'api.game-service.com'}));
      expect(modified.host, equals(original.host));
      expect(modified.enabled, equals(original.enabled));
    });
  });
}
