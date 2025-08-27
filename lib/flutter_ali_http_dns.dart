import 'dart:async';
import 'dart:io';

import 'flutter_ali_http_dns_platform_interface.dart';
import 'src/models/dns_config.dart';
import 'src/models/proxy_config.dart';
import 'src/services/dns_resolver.dart';
import 'src/services/proxy_server.dart';
import 'src/utils/logger.dart';
import 'src/utils/port_utils.dart';
import 'src/utils/process_utils.dart';

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
  Future<bool> startProxy({ProxyConfig config = const ProxyConfig()}) async {
    if (!_isInitialized) {
      throw StateError('DNS service not initialized. Call initialize() first.');
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
      _proxyServer = await ProxyServer.startDefault(config, _dnsResolver);
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

    final addresses = <String>[];
    
    // 添加HTTP/1.1代理地址
    addresses.addAll(_proxyServer!.getAllAddresses());
    
    // 添加HTTP/2代理地址
    final http2Address = _proxyServer!.getHttp2Address();
    if (http2Address != null) {
      addresses.add(http2Address);
    }
    
    return addresses;
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

  /// 获取端口占用详细信息
  ///
  /// [port] 要检查的端口号
  /// 返回端口占用信息，包括进程ID、进程名称等
  static Future<PortInfo> getPortInfo(int port) async {
    return await PortUtils.getPortInfo(port);
  }

  /// 获取当前应用进程ID
  ///
  /// 返回当前应用的进程ID
  static int getCurrentProcessId() {
    // 直接调用静态方法获取当前 PID
    return ProcessUtils.getCurrentPid();
  }

  /// 检查端口是否被自己的应用占用
  ///
  /// [port] 要检查的端口号
  /// 返回 true 如果是被自己的应用占用，false 如果是被其他程序占用或端口可用
  static Future<bool> isPortUsedByOwnApp(int port) async {
    final portInfo = await getPortInfo(port);
    return portInfo.isOwnProcess;
  }

  /// 获取当前代理的可用端口（内部使用）
  ///
  /// 返回当前代理服务器监听的端口列表
  Future<List<int>> getAvailablePorts() async {
    if (!_isProxyRunning || _proxyServer == null) {
      return [];
    }

    return _proxyServer!.getListeningPorts();
  }

  /// 注册端口监听（内部使用）
  ///
  /// [port] 要监听的端口
  /// 返回注册是否成功
  Future<bool> registerPort(int port) async {
    if (!_isProxyRunning || _proxyServer == null) {
      Logger.warning('Proxy server is not running');
      return false;
    }

    return await _proxyServer!.registerPort(port);
  }

  /// 取消注册端口监听（内部使用）
  ///
  /// [port] 要取消监听的端口
  /// 返回取消注册是否成功
  Future<bool> deregisterPort(int port) async {
    if (!_isProxyRunning || _proxyServer == null) {
      Logger.warning('Proxy server is not running');
      return false;
    }

    return await _proxyServer!.deregisterPort(port);
  }

  /// 检查端口是否正在被监听（内部使用）
  ///
  /// [port] 要检查的端口
  /// 返回端口是否正在被监听
  /// 注意：用户通常不需要手动调用此方法，主要用于内部端口管理
  Future<bool> isPortListening(int port) async {
    if (!_isProxyRunning || _proxyServer == null) {
      return false;
    }

    return _proxyServer!.isPortListening(port);
  }

  /// 获取当前代理服务器实例
  ///
  /// 返回当前运行的代理服务器实例，如果没有则返回 null
  ProxyServer? get currentProxyServer => _proxyServer;

  /// 获取指定端口的代理服务器实例
  ///
  /// [port] 端口号
  /// 返回指定端口的代理服务器实例，如果没有则返回 null
  static ProxyServer? getProxyServerByPort(int port) {
    return ProxyServer.getInstanceByPort(port);
  }

  /// 停止所有代理服务器实例
  ///
  /// 停止当前应用中的所有代理服务器实例
  static Future<void> stopAllProxyServers() async {
    await ProxyServer.stopAll();
  }

  /// 获取所有运行的代理服务器端口
  ///
  /// 返回当前应用中所有运行的代理服务器端口列表
  static List<int> getRunningProxyPorts() {
    return ProxyServer.getRunningPorts();
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



  /// 清理残留端口
  Future<void> _cleanupStalePorts() async {
    try {
      Logger.info('Cleaning up stale ports...');
      
      // 使用PortUtils清理常见的代理端口
      final cleanedPorts = await PortUtils.cleanupCommonProxyPorts();
      
      if (cleanedPorts.isNotEmpty) {
        Logger.info('Cleaned up ${cleanedPorts.length} stale ports: $cleanedPorts');
      } else {
        Logger.info('No stale ports found to clean up');
      }
    } catch (e) {
      Logger.error('Error during port cleanup', e);
    }
  }
}
