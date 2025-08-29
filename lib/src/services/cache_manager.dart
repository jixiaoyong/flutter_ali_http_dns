import '../utils/logger.dart';

/// DNS缓存管理器
/// 负责管理DNS缓存的状态和操作
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// 缓存是否启用
  bool _isEnabled = false;

  /// 缓存存储
  final Map<String, String> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  final Map<String, int> _retryCount = {};

  /// 缓存配置
  int _maxCacheSize = 100;
  int _maxCacheTTL = 3600;

  /// 获取缓存管理器实例
  static CacheManager get instance => _instance;

  /// 检查缓存是否启用
  bool get isEnabled => _isEnabled;

  /// 设置缓存状态
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    Logger.info('Cache ${enabled ? 'enabled' : 'disabled'}');
  }

  /// 重置缓存状态
  void reset() {
    _isEnabled = false;
    _cache.clear();
    _cacheExpiry.clear();
    _retryCount.clear();
    Logger.info('Cache state reset');
  }

  /// 配置缓存参数
  void configure({int? maxCacheSize, int? maxCacheTTL}) {
    if (maxCacheSize != null) {
      _maxCacheSize = maxCacheSize;
      Logger.info('Cache max size configured: $maxCacheSize');
    }
    if (maxCacheTTL != null) {
      _maxCacheTTL = maxCacheTTL;
      Logger.info('Cache TTL configured: ${maxCacheTTL}s');
    }
  }

  /// 从缓存获取 IP
  String? getCachedIp(String domain) {
    if (!_isEnabled) return null;

    final expiry = _cacheExpiry[domain];
    if (expiry != null && DateTime.now().isBefore(expiry)) {
      Logger.debug('Domain resolved from cache: $domain -> ${_cache[domain]}');
      return _cache[domain];
    }

    // 清理过期缓存
    _cache.remove(domain);
    _cacheExpiry.remove(domain);
    return null;
  }

  /// 缓存 IP 地址
  void cacheIp(String domain, String ip) {
    if (!_isEnabled) return;

    if (_cache.length >= _maxCacheSize) {
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
      Duration(seconds: _maxCacheTTL),
    );
    Logger.debug('Cached IP: $domain -> $ip (TTL: ${_maxCacheTTL}s)');
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
      'maxSize': _maxCacheSize,
      'domains': _cache.keys.toList(),
      'retryCount': Map<String, int>.from(_retryCount),
    };
  }

  /// 设置重试计数
  void setRetryCount(String domain, int count) {
    _retryCount[domain] = count;
  }

  /// 获取重试计数
  int getRetryCount(String domain) {
    return _retryCount[domain] ?? 0;
  }

  /// 移除重试计数
  void removeRetryCount(String domain) {
    _retryCount.remove(domain);
  }
}
