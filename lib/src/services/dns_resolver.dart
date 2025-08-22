import 'dart:io';
import '../models/dns_config.dart';
import '../utils/logger.dart';

/// DNS 解析器服务
class DnsResolver {
  DnsConfig? _config;
  final Map<String, String> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};

  /// 初始化解析器
  Future<void> initialize(DnsConfig config) async {
    _config = config;
    Logger.info('DnsResolver initialized with cache size: ${config.maxCacheSize}');
    
    // 预加载域名
    if (config.preloadDomains.isNotEmpty) {
      Logger.info('Preloading domains: ${config.preloadDomains}');
      for (final domain in config.preloadDomains) {
        await resolve(domain);
      }
    }
  }

  /// 解析域名
  /// 
  /// [domain] 要解析的域名
  /// 返回解析后的 IP 地址，如果解析失败则返回原域名
  Future<String> resolve(String domain) async {
    if (_config == null) {
      throw StateError('DnsResolver not initialized');
    }

    // 检查缓存
    if (_config!.enableCache) {
      final cachedIp = _getCachedIp(domain);
      if (cachedIp != null) {
        Logger.debug('Domain resolved from cache: $domain -> $cachedIp');
        return cachedIp;
      }
    }

    try {
      Logger.debug('Resolving domain using system DNS: $domain');
      // 使用系统 DNS 解析
      final addresses = await InternetAddress.lookup(domain);
      if (addresses.isNotEmpty) {
        final ip = addresses.first.address;
        
        // 缓存结果
        if (_config!.enableCache) {
          _cacheIp(domain, ip);
        }
        
        Logger.info('Domain resolved successfully: $domain -> $ip');
        return ip;
      }
    } catch (e) {
      Logger.error('Failed to resolve domain $domain', e);
    }

    Logger.warning('Domain resolution failed, returning original domain: $domain');
    return domain;
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

  /// 清理缓存
  void clearCache() {
    final size = _cache.length;
    _cache.clear();
    _cacheExpiry.clear();
    Logger.info('Cache cleared, removed $size entries');
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _config?.maxCacheSize ?? 0,
      'domains': _cache.keys.toList(),
    };
  }
}
