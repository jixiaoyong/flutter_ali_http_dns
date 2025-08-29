import 'dart:async';
import 'dart:io';

import 'flutter_ali_http_dns_platform_interface.dart';
import 'src/models/dns_config.dart';
import 'src/models/proxy_config.dart';
import 'src/services/dns_resolver.dart';
import 'src/services/proxy_server.dart';
import 'src/utils/logger.dart';
import 'src/utils/port_utils.dart';

export 'src/models/dns_config.dart';
export 'src/models/proxy_config.dart';
export 'src/utils/logger.dart';
export 'src/utils/port_utils.dart';

/// Flutter 阿里云 HttpDNS 插件主类
class FlutterAliHttpDns {
  static final FlutterAliHttpDns _instance = FlutterAliHttpDns._internal();
  factory FlutterAliHttpDns() => _instance;
  FlutterAliHttpDns._internal();

  final FlutterAliHttpDnsPlatform _platform =
      FlutterAliHttpDnsPlatform.instance;
  final DnsResolver _dnsResolver = DnsResolver();
  ProxyServer? _proxyServer;

  bool _isInitialized = false;
  bool _isProxyRunning = false;

  // 启动锁，防止并发启动
  Future<bool>? _startProxyFuture;

  /// 获取插件实例
  static FlutterAliHttpDns get instance => _instance;

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 检查代理是否正在运行
  bool get isProxyRunning => _isProxyRunning;

  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    Logger.setLevel(level);
  }

  /// 启用或禁用日志
  static void setLogEnabled(bool enabled) {
    Logger.setEnabled(enabled);
  }

  /// 初始化 DNS 服务
  ///
  /// [config] DNS 配置参数
  /// 返回初始化是否成功
  Future<bool> initialize(DnsConfig config) async {
    try {
      Logger.info('Initializing DNS service with config: ${config.accountId}');
      Logger.debug(
          'Full config details: accountId=${config.accountId}, accessKeyId=${config.accessKeyId}, enableCache=${config.enableCache}');

      // 清理可能存在的残留端口
      await _cleanupStalePorts();

      final result = await _platform.initializeDns(config);
      Logger.info('Platform initialization result: $result');

      if (result) {
        _isInitialized = true;
        await _dnsResolver.initialize(config);
        Logger.info('DNS service initialized successfully');
      } else {
        Logger.error('Failed to initialize DNS service');
      }
      return result;
    } catch (e) {
      Logger.error('Failed to initialize DNS service', e);
      return false;
    }
  }

  /// 解析域名（可能返回 null）
  ///
  /// [domain] 要解析的域名
  /// [enableSystemDnsFallback] 是否启用系统DNS回退，默认为true
  /// 返回解析后的 IP 地址，如果解析失败则返回 null
  Future<String?> resolveDomainNullable(String domain,
      {bool enableSystemDnsFallback = true}) async {
    if (!_isInitialized) {
      Logger.error('DNS service not initialized. Call initialize() first.');
      return null;
    }

    try {
      Logger.debug(
          'Resolving domain (nullable): $domain (system fallback: $enableSystemDnsFallback)');
      return await _dnsResolver.resolve(domain,
          enableSystemDnsFallback: enableSystemDnsFallback);
    } catch (e) {
      Logger.error('Failed to resolve domain $domain', e);
      return null;
    }
  }

  /// 解析域名（失败时返回原域名）
  ///
  /// [domain] 要解析的域名
  /// [enableSystemDnsFallback] 是否启用系统DNS回退，默认为true
  /// 返回解析后的 IP 地址，如果解析失败则返回原域名
  Future<String> resolveDomain(String domain,
      {bool enableSystemDnsFallback = true}) async {
    final result = await resolveDomainNullable(domain,
        enableSystemDnsFallback: enableSystemDnsFallback);
    return result ?? domain;
  }

  /// 动态设置是否启用缓存
  ///
  /// [enable] 是否启用
  Future<void> setEnableCache(bool enable) async {
    if (!_isInitialized) {
      Logger.error('DNS service not initialized. Call initialize() first.');
      return;
    }
    await _platform.setEnableCache(enable);
  }

  /// 启动代理服务器
  ///
  /// [config] 代理配置参数
  /// 返回启动是否成功
  Future<bool> startProxy({ProxyConfig config = const ProxyConfig()}) async {
    if (!_isInitialized) {
      Logger.error('DNS service not initialized. Call initialize() first.');
      return false;
    }

    // 验证端口配置
    if (!_validateProxyConfig(config)) {
      Logger.error('Proxy configuration validation failed');
      return false;
    }

    // 如果代理已经在运行，直接返回成功
    if (_isProxyRunning && _proxyServer != null && _proxyServer!.isRunning) {
      Logger.info('Proxy server is already running');
      return true;
    }

    // 如果正在启动中，等待当前启动完成
    if (_startProxyFuture != null) {
      Logger.info('Proxy server is starting, waiting for completion...');
      try {
        final result = await _startProxyFuture!;
        Logger.info('Previous start attempt completed with result: $result');
        return result;
      } catch (e) {
        Logger.error('Previous start attempt failed', e);
        // 重置启动锁，允许重试
        _startProxyFuture = null;
      }
    }

    // 创建新的启动任务
    _startProxyFuture = _startProxyInternal(config);

    try {
      final result = await _startProxyFuture!;
      return result;
    } finally {
      // 清理启动锁
      _startProxyFuture = null;
    }
  }

  /// 内部启动方法 - 启动默认代理
  Future<bool> _startProxyInternal(ProxyConfig config) async {
    try {
      Logger.info('Starting default proxy server with smart port allocation');

      // 如果已有代理服务器，先停止
      if (_proxyServer != null) {
        Logger.info('Stopping existing proxy server');
        await _proxyServer!.stop();
        _proxyServer = null;
        _isProxyRunning = false;
      }

      // 启动默认代理服务器（用于Dio等普通场景）
      _proxyServer = await ProxyServer.start(config, _dnsResolver);
      if (_proxyServer == null) {
        Logger.error('Failed to start default proxy server');
        return false;
      }
      _isProxyRunning = true;

      final address = _proxyServer!.getAddress();
      Logger.info('Default proxy server started successfully on $address');
      return true;
    } catch (e) {
      Logger.error('Failed to start default proxy server', e);
      _isProxyRunning = false;
      _proxyServer = null;
      return false;
    }
  }

  /// 停止代理服务器
  ///
  /// 返回停止是否成功
  Future<bool> stopProxy() async {
    try {
      Logger.info('Stopping proxy server');

      // 清理启动锁
      _startProxyFuture = null;

      if (_proxyServer != null) {
        // 获取所有监听的端口
        final listeningPorts = _proxyServer!.getListeningPorts();
        Logger.info('Deregistering all listening ports: $listeningPorts');

        // 取消注册所有端口
        for (final port in listeningPorts) {
          await _proxyServer!.deregisterPort(port);
        }

        // 停止代理服务器
        await _proxyServer!.stop();
        _proxyServer = null;
      }
      _isProxyRunning = false;
      Logger.info('Proxy server stopped successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to stop proxy server', e);
      return false;
    }
  }

  /// 获取代理地址
  ///
  /// 返回代理服务器地址字符串，格式为 "host:port"
  Future<String?> getProxyAddress() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return null;
    }

    return _proxyServer!.getAddress();
  }

  /// 获取HTTP/2代理地址
  ///
  /// 返回HTTP/2代理服务器地址字符串，格式为 "host:port"
  Future<String?> getHttp2ProxyAddress() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return null;
    }

    return _proxyServer!.getHttp2Address();
  }

  /// 获取所有代理地址
  ///
  /// 返回所有代理服务器地址列表，格式为 ["host:port1", "host:port2", ...]
  Future<List<String>> getAllProxyAddresses() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return [];
    }

    // 直接返回所有地址，避免重复
    return _proxyServer!.getAllAddresses();
  }

  /// 获取主要端口（第一个端口）
  ///
  /// 返回主要代理端口，适用于单端口场景
  Future<int?> getMainPort() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return null;
    }

    final ports = _proxyServer!.allocatedPorts;
    return ports.isNotEmpty ? ports.first : null;
  }

  /// 获取实际使用的端口列表
  ///
  /// 返回当前实际使用的端口列表
  Future<List<int>> getActualPorts() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return [];
    }

    return _proxyServer!.allocatedPorts;
  }

  /// 检查端口是否可用
  ///
  /// [port] 端口号
  /// 返回端口是否可用
  Future<bool> isPortAvailable(int port) async {
    return await PortUtils.isPortAvailable(port);
  }

  /// 获取代理配置字符串
  ///
  /// 返回用于 HttpClient 配置的代理字符串
  Future<String?> getProxyConfigString() async {
    if (!_isProxyRunning) {
      return null;
    }

    final address = await getProxyAddress();
    return address != null ? 'PROXY $address' : null;
  }

  /// 检查代理服务器状态
  ///
  /// 返回代理服务器是否正在运行
  Future<bool> checkProxyStatus() async {
    _isProxyRunning = _proxyServer?.isRunning ?? false;
    return _isProxyRunning;
  }

  /// 获取当前代理服务器实例
  ///
  /// 返回当前运行的代理服务器实例，如果没有则返回 null
  ProxyServer? get currentProxyServer => _proxyServer;

  /// 为 HttpClient 配置代理
  ///
  /// [client] HttpClient 实例
  /// 配置 HttpClient 使用插件提供的代理
  /// 返回配置是否成功
  Future<bool> configureHttpClient(HttpClient client) async {
    if (!_isProxyRunning) {
      Logger.error('Proxy server not running. Call startProxy() first.');
      return false;
    }

    try {
      final proxyConfig = await getProxyConfigString();
      if (proxyConfig != null) {
        client.findProxy = (uri) => proxyConfig;
        Logger.info('HttpClient configured with proxy: $proxyConfig');
        return true;
      } else {
        Logger.warning('No proxy configuration available');
        return false;
      }
    } catch (e) {
      Logger.error('Failed to configure HttpClient with proxy', e);
      return false;
    }
  }

  /// 获取 Dio 代理配置
  ///
  /// 返回用于 Dio 配置的代理设置
  Future<Map<String, dynamic>?> getDioProxyConfig() async {
    if (!_isProxyRunning) {
      return null;
    }

    final address = await getProxyAddress();
    if (address != null) {
      final parts = address.split(':');
      if (parts.length == 2) {
        return {
          'host': parts[0],
          'port': int.tryParse(parts[1]) ?? 4041,
        };
      }
    }
    return null;
  }

  /// 清除DNS缓存
  ///
  /// [hostNames] 可选的域名列表，如果提供则清除指定域名的缓存，否则清除所有缓存
  /// 返回清除是否成功
  Future<bool> clearCache([List<String>? hostNames]) async {
    if (!_isInitialized) {
      Logger.error('DNS service not initialized. Call initialize() first.');
      return false;
    }

    try {
      Logger.info('Clearing DNS cache for: ${hostNames ?? 'all hosts'}');

      // 调用平台方法清除缓存
      final platformResult = await _platform.clearCache(hostNames);

      // 同时清除本地DNS解析器缓存
      if (hostNames == null || hostNames.isEmpty) {
        _dnsResolver.clearCache();
      } else {
        _dnsResolver.clearHosts(hostNames);
      }

      Logger.info('DNS cache cleared successfully');
      return platformResult;
    } catch (e) {
      Logger.error('Failed to clear DNS cache', e);
      return false;
    }
  }

  /// 清理资源
  ///
  /// 停止代理服务器并清理相关资源
  Future<void> dispose() async {
    Logger.info('Disposing plugin resources');
    if (_isProxyRunning) {
      await stopProxy();
    }
    await _proxyServer?.dispose();
    _isInitialized = false;
    Logger.info('Plugin resources disposed');
  }

  /// 验证代理配置中的端口设置
  ///
  /// [config] 代理配置
  /// 返回验证是否成功
  bool _validateProxyConfig(ProxyConfig config) {
    Logger.info('Validating proxy configuration...');

    try {
      // 验证端口池中的每个端口
      if (config.portPool != null && config.portPool!.isNotEmpty) {
        Logger.info('Validating port pool: ${config.portPool}');
        for (final port in config.portPool!) {
          if (!PortUtils.isValidPort(port)) {
            Logger.error(
                'Invalid port in port pool: $port (must be between 1 and 65535)');
            return false;
          }
        }
        Logger.info('Port pool validation passed');
      }

      // 验证端口范围
      final startPort = config.startPort ?? 4041;
      final endPort = config.endPort ?? (startPort + 100);

      Logger.info('Validating port range: $startPort-$endPort');
      if (!PortUtils.isValidPortRange(startPort, endPort)) {
        Logger.error(
            'Invalid port range: startPort ($startPort) and endPort ($endPort) must be valid and endPort must be greater than startPort');
        return false;
      }
      Logger.info('Port range validation passed');

      Logger.info('Proxy configuration validation completed successfully');
      return true;
    } catch (e) {
      Logger.error('Error during proxy configuration validation', e);
      return false;
    }
  }

  /// 清理残留端口
  Future<void> _cleanupStalePorts() async {
    try {
      Logger.info('Cleaning up stale ports...');

      // 使用PortUtils清理常见的代理端口
      final cleanedPorts = await PortUtils.cleanupCommonProxyPorts();

      if (cleanedPorts.isNotEmpty) {
        Logger.info(
            'Cleaned up ${cleanedPorts.length} stale ports: $cleanedPorts');
      } else {
        Logger.info('No stale ports found to clean up');
      }
    } catch (e) {
      Logger.error('Error during port cleanup', e);
    }
  }
}
