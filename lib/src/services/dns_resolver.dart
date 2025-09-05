import 'dart:io';
import '../../flutter_ali_http_dns.dart';
import '../../flutter_ali_http_dns_platform_interface.dart';
import 'cache_manager.dart';

/// DNS 解析器服务
class DnsResolver {
  bool _isInitialized = false;
  List<String> _preloadDomains = [];
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // 缓存管理器
  final CacheManager _cacheManager = CacheManager.instance;

  /// 初始化解析器
  Future<void> initialize(DnsConfig config) async {
    _isInitialized = true;
    _preloadDomains = List.from(config.preloadDomains);

    Logger.info(
        'DnsResolver initialized with cache size: ${config.maxCacheSize}');

    // 预加载域名
    if (_preloadDomains.isNotEmpty) {
      Logger.info('Preloading domains: $_preloadDomains');
      for (final domain in _preloadDomains) {
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
    if (!_isInitialized) {
      Logger.error('DnsResolver not initialized');
      return null;
    }

    // 检查缓存 - 使用缓存管理器
    final cachedIp = _cacheManager.getCachedIp(domain);
    if (cachedIp != null) {
      return cachedIp;
    }

    // 尝试HTTPDNS解析，带重试机制
    String? ip = await _resolveWithRetry(domain);

    if (ip != null && ip.isNotEmpty) {
      // 缓存结果 - 使用缓存管理器
      _cacheManager.cacheIp(domain, ip);
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
    int retryCount = _cacheManager.getRetryCount(domain);

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        Logger.debug(
            'HTTPDNS resolution attempt ${attempt + 1} for domain: $domain');

        // 直接调用平台方法，避免循环调用
        final String? ip =
            await FlutterAliHttpDnsPlatform.instance.resolveDomain(domain);

        if (ip != null && ip.isNotEmpty) {
          // 成功解析，重置重试计数
          _cacheManager.removeRetryCount(domain);
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
    _cacheManager.setRetryCount(domain, retryCount + 1);
    Logger.warning(
        'All HTTPDNS resolution attempts failed for domain: $domain');
    return null;
  }

  /// 验证IP地址是否有效，即该IP地址是否可用于公网通信。
  ///
  /// 该方法会精确过滤掉所有特殊用途的IP地址，这些地址通常不能在互联网上进行路由，
  /// 从而避免因运营商返回内网或无效IP而导致的连接失败。
  ///
  /// 过滤范围包括：
  ///
  /// **IPv4 地址：**
  /// - **本地回环地址** (127.0.0.0/8)：用于本机内部通信。
  /// - **私有地址** (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)：仅用于局域网（LAN）内部通信。
  /// - **链路本地地址** (169.254.0.0/16)：用于无DHCP服务器时的设备间通信。
  /// - **多播地址** (224.0.0.0/4)：用于一对多通信，非单点地址。
  /// - **保留地址** (240.0.0.0/4)：被IANA保留，不能在公网使用。
  ///
  /// **IPv6 地址：**
  /// - **本地回环地址** (::1)：等同于 IPv4 的 127.0.0.1。
  /// - **私有地址** (fc00:/7)：即唯一本地地址，类似于 IPv4 私有地址。
  /// - **链路本地地址** (fe80:/10)：等同于 IPv4 的链路本地地址。
  ///
  ///
  /// [ip] 要验证的IP地址字符串。
  /// 返回 true 表示该IP地址可用于公网通信，返回 false 则表示无效。
  bool _isValidIpAddress(String ip) {
    try {
      final address = InternetAddress(ip);

      // 检查是否为回环地址、多播地址
      if (address.isLoopback) {
        // 本地回环地址: 127.0.0.0/8 (IPv4) 或 ::1 (IPv6)
        Logger.warning('Rejected loopback IP: $ip');
        return false;
      }
      if (address.isMulticast) {
        // 多播地址: 224.0.0.0/4 (IPv4)
        Logger.warning('Rejected multicast IP: $ip');
        return false;
      }
      // 检查是否为链路本地地址
      if (address.isLinkLocal) {
        Logger.warning('Rejected link-local IP: $ip');
        return false;
      }

      // 针对IPv4的特殊地址检查（手动实现私有地址）
      if (address.type == InternetAddressType.IPv4) {
        final parts = ip.split('.');
        final firstOctet = int.parse(parts[0]);
        final secondOctet = int.parse(parts[1]);

        // IPv4 私有地址: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
        if (firstOctet == 10 ||
            (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31) ||
            (firstOctet == 192 && secondOctet == 168)) {
          Logger.warning('Rejected private IP: $ip');
          return false;
        }

        // 保留地址: 240.0.0.0/4
        if (firstOctet >= 240) {
          Logger.warning('Rejected reserved IP: $ip');
          return false;
        }
      }

      // 针对IPv6的特殊地址检查（手动实现私有地址）
      else if (address.type == InternetAddressType.IPv6) {
        final ipLower = ip.toLowerCase();
        // IPv6 私有地址: fc00:: 和 fd00:
        if (ipLower.startsWith('fc00:') || ipLower.startsWith('fd00:')) {
          Logger.warning('Rejected IPv6 private IP: $ip');
          return false;
        }
      }

      return true;
    } on ArgumentError {
      Logger.warning('Invalid IP address format: $ip');
      return false;
    } on Exception catch (e) {
      Logger.warning(
          'An unexpected error occurred during IP validation: $ip', e);
      return false;
    }
  }

  /// 使用系统DNS作为备选方案，默认只返回公网IP地址
  ///
  /// [domain] 要解析的域名
  /// [onlyPublicIp] 是否只返回公网IP地址，默认为true
  Future<String?> resolveWithSystemDns(String domain,
      {bool onlyPublicIp = true}) async {
    try {
      Logger.debug('Resolving domain using system DNS: $domain');

      // 使用超时机制
      final addresses = await InternetAddress.lookup(domain)
          .timeout(const Duration(seconds: 5));

      if (addresses.isNotEmpty) {
        // 遍历所有返回的地址，寻找第一个有效的公网地址
        for (final address in addresses) {
          final ip = address.address;

          // 验证IP地址的有效性
          if (!onlyPublicIp || _isValidIpAddress(ip)) {
            _cacheManager.cacheIp(domain, ip);
            Logger.info(
                'Domain resolved successfully via system DNS: $domain -> $ip');
            return ip;
          } else {
            Logger.debug(
                'Skipping invalid IP address: $ip for domain: $domain');
          }
        }

        // 如果没有找到有效的公网地址，记录警告
        Logger.warning(
            'No valid public IP addresses found for domain: $domain. '
            'All resolved addresses were local/private/reserved.');
      }
    } catch (e) {
      Logger.error('Failed to resolve domain $domain using system DNS', e);
    }

    Logger.warning('All DNS resolution failed, returning null: $domain');
    return null;
  }
}
