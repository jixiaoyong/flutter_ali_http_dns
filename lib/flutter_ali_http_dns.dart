
import 'dart:io';

import 'flutter_ali_http_dns_platform_interface.dart';
import 'src/models/dns_config.dart';
import 'src/models/proxy_config.dart';
import 'src/services/dns_resolver.dart';
import 'src/services/proxy_server.dart';
import 'src/utils/logger.dart';

/// Flutter 阿里云 HttpDNS 插件主类
class FlutterAliHttpDns {
  static final FlutterAliHttpDns _instance = FlutterAliHttpDns._internal();
  factory FlutterAliHttpDns() => _instance;
  FlutterAliHttpDns._internal();

  final FlutterAliHttpDnsPlatform _platform = FlutterAliHttpDnsPlatform.instance;
  final DnsResolver _dnsResolver = DnsResolver();
  ProxyServer? _proxyServer;

  bool _isInitialized = false;
  bool _isProxyRunning = false;

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
      Logger.debug('Full config details: accountId=${config.accountId}, accessKeyId=${config.accessKeyId}, enableCache=${config.enableCache}');
      
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

  /// 解析域名
  /// 
  /// [domain] 要解析的域名
  /// 返回解析后的 IP 地址，如果解析失败则返回原域名
  Future<String> resolveDomain(String domain) async {
    if (!_isInitialized) {
      throw StateError('DNS service not initialized. Call initialize() first.');
    }

    try {
      Logger.debug('Resolving domain: $domain');
      // 首先尝试从平台获取解析结果
      final platformResult = await _platform.resolveDomain(domain);
      if (platformResult != null && platformResult != domain) {
        Logger.info('Domain resolved: $domain -> $platformResult');
        return platformResult;
      }

      // 如果平台解析失败，使用本地解析器
      final localResult = await _dnsResolver.resolve(domain);
      Logger.info('Domain resolved locally: $domain -> $localResult');
      return localResult;
    } catch (e) {
      Logger.error('Failed to resolve domain $domain', e);
      return domain;
    }
  }

  /// 启动代理服务器
  /// 
  /// [config] 代理配置参数
  /// 返回启动是否成功
  Future<bool> startProxy(ProxyConfig config) async {
    if (!_isInitialized) {
      throw StateError('DNS service not initialized. Call initialize() first.');
    }

    try {
      Logger.info('Starting proxy server on port ${config.port}');
      // 创建新的代理服务器实例
      _proxyServer = ProxyServer(config: config);
      await _proxyServer!.start();
      _isProxyRunning = true;
      Logger.info('Proxy server started successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to start proxy server', e);
      return false;
    }
  }

  /// 停止代理服务器
  /// 
  /// 返回停止是否成功
  Future<bool> stopProxy() async {
    try {
      Logger.info('Stopping proxy server');
      if (_proxyServer != null) {
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

  /// 为 HttpClient 配置代理
  /// 
  /// [client] HttpClient 实例
  /// 配置 HttpClient 使用插件提供的代理
  Future<void> configureHttpClient(HttpClient client) async {
    if (!_isProxyRunning) {
      throw StateError('Proxy server not running. Call startProxy() first.');
    }

    final proxyConfig = await getProxyConfigString();
    if (proxyConfig != null) {
      client.findProxy = (uri) => proxyConfig;
      Logger.info('HttpClient configured with proxy: $proxyConfig');
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
}
