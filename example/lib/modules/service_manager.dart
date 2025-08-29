import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns_example/credentials.dart';

/// 服务管理器 - 负责DNS和代理服务的初始化和管理
class ServiceManager {
  final FlutterAliHttpDns _dnsService = FlutterAliHttpDns();
  String _proxyAddress = '';
  String _initializationStatus = '未初始化';
  String _lastError = '';
  DateTime? _lastInitializationTime;
  
  // 回调函数
  final Function(String) onLogMessage;
  final Function(String) onSnackBarMessage;

  ServiceManager({
    required this.onLogMessage,
    required this.onSnackBarMessage,
  });

  // Getters
  FlutterAliHttpDns get dnsService => _dnsService;
  bool get isInitialized => _dnsService.isInitialized;
  bool get isProxyRunning => _dnsService.isProxyRunning;
  String get proxyAddress => _proxyAddress;
  String get initializationStatus => _initializationStatus;
  String get lastError => _lastError;
  DateTime? get lastInitializationTime => _lastInitializationTime;

  /// DNS配置
  DnsConfig getDnsConfig({required bool enableCache, required bool enableSpeedTest}) => DnsConfig(
    accountId: AliHttpDnsCredentials.accountId,
    accessKeyId: AliHttpDnsCredentials.accessKeyId,
    accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
    enableCache: enableCache,
    maxCacheSize: 1000,
    enableSpeedTest: enableSpeedTest,
    timeout: 5,
    preloadDomains: ['www.aliyun.com', 'www.taobao.com', 'www.tmall.com'],
    keepAliveDomains: ['www.aliyun.com'],
  );

  /// 代理配置
  ProxyConfig get proxyConfig => const ProxyConfig(
    portPool: [4041, 4042, 4043], // 端口池
    startPort: 4044,              // 起始端口
    endPort: 4050,                // 结束端口
    enabled: true,                // 启用代理
    host: 'localhost',            // 代理主机
  );

  /// 初始化DNS服务
  Future<void> initializeDns({required bool enableCache, required bool enableSpeedTest}) async {
    try {
      _initializationStatus = '初始化中...';
      
      // 验证认证信息
      if (AliHttpDnsCredentials.accountId.isEmpty || 
          AliHttpDnsCredentials.accessKeyId.isEmpty || 
          AliHttpDnsCredentials.accessKeySecret.isEmpty) {
        _initializationStatus = '认证信息错误';
        _lastError = '认证信息未完整配置';
        
        onLogMessage('认证信息验证失败: 认证信息未完整配置');
        onSnackBarMessage('认证信息配置错误');
        throw Exception('认证信息未完整配置');
      }
      
      final config = getDnsConfig(enableCache: enableCache, enableSpeedTest: enableSpeedTest);
      
      onLogMessage('开始初始化DNS服务...');
      onLogMessage('配置信息: AccountId=${config.accountId}, AccessKeyId=${config.accessKeyId}');
      onLogMessage('缓存设置: 启用=${config.enableCache}, 大小=${config.maxCacheSize}');
      onLogMessage('测速设置: 启用=${config.enableSpeedTest}');
      onLogMessage('预加载域名: ${config.preloadDomains.join(', ')}');
      
      final success = await _dnsService.initialize(config);
      
      if (success) {
        _initializationStatus = '已初始化';
        _lastInitializationTime = DateTime.now();
        _lastError = '';
        
        onLogMessage('DNS 服务初始化成功');
        onLogMessage('初始化时间: ${_lastInitializationTime!.toString().substring(0, 19)}');
        onSnackBarMessage('DNS 服务初始化成功');
      } else {
        _initializationStatus = '初始化失败';
        _lastError = 'DNS服务初始化返回失败';
        
        onLogMessage('DNS 服务初始化失败: 返回false');
        onSnackBarMessage('DNS 服务初始化失败');
        throw Exception('DNS服务初始化失败');
      }
    } catch (e) {
      _initializationStatus = '初始化失败';
      _lastError = e.toString();
      
      onLogMessage('DNS 服务初始化失败: $e');
      onSnackBarMessage('DNS 服务初始化失败: $e');
      rethrow;
    }
  }

  /// 启动代理服务器
  Future<void> startProxy() async {
    if (!_dnsService.isInitialized) {
      onSnackBarMessage('请先初始化 DNS 服务');
      return;
    }

    try {
      onLogMessage('开始启动智能代理服务器...');
      onLogMessage('代理配置: 端口池=${proxyConfig.portPool}, 主机=${proxyConfig.host}');
      
      final success = await _dnsService.startProxy(config: proxyConfig);

      if (success) {
        final addresses = await _dnsService.getAllProxyAddresses();
        _proxyAddress = addresses.isNotEmpty ? addresses.join(', ') : 'Unknown';
        
        onLogMessage('智能代理服务器启动成功');
        onLogMessage('代理地址: $_proxyAddress');
        onSnackBarMessage('智能代理服务器启动成功');
      } else {
        onLogMessage('智能代理服务器启动失败');
        onSnackBarMessage('智能代理服务器启动失败');
      }
    } catch (e) {
      onLogMessage('智能代理服务器启动错误: $e');
      onSnackBarMessage('智能代理服务器启动错误: $e');
      rethrow;
    }
  }

  /// 停止代理服务器
  Future<void> stopProxy() async {
    try {
      onLogMessage('开始停止智能代理服务器...');
      
      final success = await _dnsService.stopProxy();
      _proxyAddress = '';
      
      if (success) {
        onLogMessage('智能代理服务器停止成功');
        onSnackBarMessage('智能代理服务器停止成功');
      } else {
        onLogMessage('智能代理服务器停止失败');
        onSnackBarMessage('智能代理服务器停止失败');
      }
    } catch (e) {
      onLogMessage('智能代理服务器停止错误: $e');
      onSnackBarMessage('智能代理服务器停止错误: $e');
      rethrow;
    }
  }

  /// 清除缓存
  Future<void> clearCache([List<String>? hostNames]) async {
    try {
      if (!_dnsService.isInitialized) {
        onLogMessage('DNS服务未初始化，无法清除缓存');
        onSnackBarMessage('请先初始化DNS服务');
        return;
      }
      
      final cacheType = hostNames != null ? '指定域名' : '所有';
      onLogMessage('开始清除${cacheType}DNS缓存...');
      
      // 调用SDK的清除缓存方法
      final success = await _dnsService.clearCache(hostNames);
      
      if (success) {
        onLogMessage('${cacheType}DNS缓存清除成功');
        onSnackBarMessage('${cacheType}DNS缓存清除成功');
      } else {
        onLogMessage('${cacheType}DNS缓存清除失败');
        onSnackBarMessage('${cacheType}DNS缓存清除失败');
      }
    } catch (e) {
      onLogMessage('清除缓存失败: $e');
      onSnackBarMessage('清除缓存失败: $e');
    }
  }

  /// 动态设置是否启用缓存
  Future<void> setEnableCache(bool enable) async {
    try {
      if (!_dnsService.isInitialized) {
        onLogMessage('DNS服务未初始化，无法设置缓存状态');
        onSnackBarMessage('请先初始化DNS服务');
        return;
      }
      onLogMessage('动态设置缓存为: ${enable ? "启用" : "禁用"}');
      await _dnsService.setEnableCache(enable);
      onSnackBarMessage('缓存已${enable ? "启用" : "禁用"}');
    } catch (e) {
      onLogMessage('设置缓存状态失败: $e');
      onSnackBarMessage('设置缓存状态失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _dnsService.dispose();
    _proxyAddress = '';
    _initializationStatus = '未初始化';
    _lastError = '';
    _lastInitializationTime = null;
    onSnackBarMessage('服务管理器已关闭DNS服务：应用退出，自动清理资源');
  }

  /// 同步状态
  /// 从SDK获取最新状态并更新本地状态
  void syncStatus() {
    // 根据SDK状态更新本地状态
    if (!_dnsService.isInitialized) {
      _initializationStatus = '未初始化';
      _lastError = '';
      _lastInitializationTime = null;
    }
    
    if (!_dnsService.isProxyRunning) {
      _proxyAddress = '';
    }
  }
}
