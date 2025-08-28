import 'dart:io';
import '../../flutter_ali_http_dns.dart';
import '../../flutter_ali_http_dns_platform_interface.dart';

/// DNS 解析器服务
class DnsResolver {
  DnsConfig? _config;
  final Map<String, String> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  final Map<String, int> _retryCount = {};
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// 初始化解析器
  Future<void> initialize(DnsConfig config) async {
    _config = config;
    Logger.info(
        'DnsResolver initialized with cache size: ${config.maxCacheSize}');

    // 预加载域名
    if (config.preloadDomains.isNotEmpty) {
      Logger.info('Preloading domains: ${config.preloadDomains}');
      for (final domain in config.preloadDomains) {
        final result = await resolve(domain, enableSystemDnsFallback: false);
        if (result != null) {
          Logger.debug('Preloaded domain: $domain -> $result');
        } else {
          Logger.warning('Failed to preload domain: $domain');
        }
      }
    }
  }

  /// 解析域名
  ///
  /// [domain] 要解析的域名
  /// [enableSystemDnsFallback] 是否启用系统DNS回退，默认为true
  /// 返回解析后的 IP 地址，如果解析失败则返回 null
  Future<String?> resolve(String domain,
      {bool enableSystemDnsFallback = true}) async {
    if (_config == null) {
      Logger.error('DnsResolver not initialized');
      return null;
    }

    // 检查缓存
    if (_config!.enableCache) {
      final cachedIp = _getCachedIp(domain);
      if (cachedIp != null) {
        Logger.debug('Domain resolved from cache: $domain -> $cachedIp');
        return cachedIp;
      }
    }

    // 尝试HTTPDNS解析，带重试机制
    String? ip = await _resolveWithRetry(domain);

    if (ip != null && ip.isNotEmpty) {
      // 缓存结果
      if (_config!.enableCache) {
        _cacheIp(domain, ip);
      }
      Logger.info('Domain resolved successfully via HTTPDNS: $domain -> $ip');
      return ip;
    }

    // 根据配置决定是否回退到系统DNS
    if (enableSystemDnsFallback) {
      Logger.warning(
          'HTTPDNS resolution failed for $domain. Falling back to system DNS.');
      return await resolveWithSystemDns(domain);
    } else {
      Logger.warning(
          'HTTPDNS resolution failed for $domain. System fallback disabled.');
      return null;
    }
  }

  /// 带重试机制的HTTPDNS解析
  Future<String?> _resolveWithRetry(String domain) async {
    int retryCount = _retryCount[domain] ?? 0;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        Logger.debug(
            'HTTPDNS resolution attempt ${attempt + 1} for domain: $domain');

        // 直接调用平台方法，避免循环调用
        final String? ip =
            await FlutterAliHttpDnsPlatform.instance.resolveDomain(domain);

        if (ip != null && ip.isNotEmpty) {
          // 成功解析，重置重试计数
          _retryCount.remove(domain);
          return ip;
        } else {
          Logger.debug(
              'HTTPDNS returned null or empty for $domain (attempt ${attempt + 1})');
        }
      } catch (e) {
        Logger.error(
            'HTTPDNS resolution error for $domain (attempt ${attempt + 1}): $e');
      }

      // 如果不是最后一次尝试，等待后重试
      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay);
      }
    }

    // 所有重试都失败了
    _retryCount[domain] = retryCount + 1;
    Logger.warning(
        'All HTTPDNS resolution attempts failed for domain: $domain');
    return null;
  }

  /// 使用系统DNS作为备选方案
  Future<String?> resolveWithSystemDns(String domain) async {
    try {
      Logger.debug('Resolving domain using system DNS: $domain');

      // 使用超时机制
      final addresses = await InternetAddress.lookup(domain)
          .timeout(const Duration(seconds: 5));

      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        if (_config!.enableCache) {
          _cacheIp(domain, ip);
        }
        Logger.info(
            'Domain resolved successfully via system DNS: $domain -> $ip');
        return ip;
      }
    } catch (e) {
      Logger.error('Failed to resolve domain $domain using system DNS', e);
    }

    Logger.warning('All DNS resolution failed, returning null: $domain');
    return null;
  }

  /// 从缓存获取 IP
  String? _getCachedIp(String domain) {
    final expiry = _cacheExpiry[domain];
    if (expiry != null && DateTime.now().isBefore(expiry)) {
      return _cache[domain];
    }

    // 清理过期缓存
    _cache.remove(domain);
    _cacheExpiry.remove(domain);
    return null;
  }

  /// 缓存 IP 地址
  void _cacheIp(String domain, String ip) {
    if (_cache.length >= _config!.maxCacheSize) {
      // 清理最旧的缓存
      final oldestDomain = _cacheExpiry.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _cache.remove(oldestDomain);
      _cacheExpiry.remove(oldestDomain);
      Logger.debug('Cleared oldest cache entry: $oldestDomain');
    }

    _cache[domain] = ip;
    _cacheExpiry[domain] = DateTime.now().add(
      Duration(seconds: _config!.maxCacheTTL),
    );
    Logger.debug('Cached IP: $domain -> $ip (TTL: ${_config!.maxCacheTTL}s)');
  }

  /// 清除所有缓存
  void clearCache() {
    final size = _cache.length;
    _cache.clear();
    _cacheExpiry.clear();
    _retryCount.clear();
    Logger.info('Cache cleared, removed $size entries');
  }

  /// 清除指定域名的缓存
  void clearHosts(List<String> hostNames) {
    int count = 0;
    for (final domain in hostNames) {
      if (_cache.containsKey(domain)) {
        _cache.remove(domain);
        _cacheExpiry.remove(domain);
        _retryCount.remove(domain);
        count++;
      }
    }
    Logger.info('Cleared $count specific hosts from cache: $hostNames');
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _config?.maxCacheSize ?? 0,
      'domains': _cache.keys.toList(),
      'retryCount': _retryCount,
    };
  }
}