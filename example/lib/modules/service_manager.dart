import 'package:flutter/material.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns_example/credentials.dart';

/// 服务管理器 - 负责DNS和代理服务的初始化和管理
class ServiceManager {
  final FlutterAliHttpDns _dnsService = FlutterAliHttpDns();
  bool _isInitialized = false;
  bool _isProxyRunning = false;
  String _proxyAddress = '';
  String _initializationStatus = '未初始化';
  String _lastError = '';
  DateTime? _lastInitializationTime;
  int _totalResolutions = 0;
  int _successfulResolutions = 0;
  int _failedResolutions = 0;
  
  // 回调函数
  final Function(String) onLogMessage;
  final Function(String) onSnackBarMessage;
  final VoidCallback onStateChanged;

  ServiceManager({
    required this.onLogMessage,
    required this.onSnackBarMessage,
    required this.onStateChanged,
  });

  // Getters
  FlutterAliHttpDns get dnsService => _dnsService;
  bool get isInitialized => _isInitialized;
  bool get isProxyRunning => _isProxyRunning;
  String get proxyAddress => _proxyAddress;
  String get initializationStatus => _initializationStatus;
  String get lastError => _lastError;
  DateTime? get lastInitializationTime => _lastInitializationTime;
  int get totalResolutions => _totalResolutions;
  int get successfulResolutions => _successfulResolutions;
  int get failedResolutions => _failedResolutions;
  double get successRate => _totalResolutions > 0 ? (_successfulResolutions / _totalResolutions) * 100 : 0.0;

  /// DNS配置
  DnsConfig get dnsConfig => const DnsConfig(
    accountId: AliHttpDnsCredentials.accountId,
    accessKeyId: AliHttpDnsCredentials.accessKeyId,
    accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
    enableCache: true,
    maxCacheSize: 1000,
    enableSpeedTest: true,
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
  Future<void> initializeDns() async {
    try {
      _initializationStatus = '初始化中...';
      onStateChanged();
      
      // 验证认证信息
      if (AliHttpDnsCredentials.accountId.isEmpty || 
          AliHttpDnsCredentials.accessKeyId.isEmpty || 
          AliHttpDnsCredentials.accessKeySecret.isEmpty) {
        _isInitialized = false;
        _initializationStatus = '认证信息错误';
        _lastError = '认证信息未完整配置';
        
        onLogMessage('认证信息验证失败: 认证信息未完整配置');
        onSnackBarMessage('认证信息配置错误');
        onStateChanged();
        throw Exception('认证信息未完整配置');
      }
      
      onLogMessage('开始初始化DNS服务...');
      onLogMessage('配置信息: AccountId=${dnsConfig.accountId}, AccessKeyId=${dnsConfig.accessKeyId}');
      onLogMessage('缓存设置: 启用=${dnsConfig.enableCache}, 大小=${dnsConfig.maxCacheSize}');
      onLogMessage('预加载域名: ${dnsConfig.preloadDomains.join(', ')}');
      
      final success = await _dnsService.initialize(dnsConfig);
      
      if (success) {
        _isInitialized = true;
        _initializationStatus = '已初始化';
        _lastInitializationTime = DateTime.now();
        _lastError = '';
        
        onLogMessage('DNS 服务初始化成功');
        onLogMessage('初始化时间: ${_lastInitializationTime!.toString().substring(0, 19)}');
        onSnackBarMessage('DNS 服务初始化成功');
        onStateChanged();
      } else {
        _isInitialized = false;
        _initializationStatus = '初始化失败';
        _lastError = 'DNS服务初始化返回失败';
        
        onLogMessage('DNS 服务初始化失败: 返回false');
        onSnackBarMessage('DNS 服务初始化失败');
        onStateChanged();
        throw Exception('DNS服务初始化失败');
      }
    } catch (e) {
      _isInitialized = false;
      _initializationStatus = '初始化失败';
      _lastError = e.toString();
      
      onLogMessage('DNS 服务初始化失败: $e');
      onSnackBarMessage('DNS 服务初始化失败: $e');
      onStateChanged();
      rethrow;
    }
  }

  /// 启动代理服务器
  Future<void> startProxy() async {
    if (!_isInitialized) {
      onSnackBarMessage('请先初始化 DNS 服务');
      return;
    }

    try {
      onLogMessage('开始启动智能代理服务器...');
      onLogMessage('代理配置: 端口池=${proxyConfig.portPool}, 主机=${proxyConfig.host}');
      
      final success = await _dnsService.startProxy(config: proxyConfig);

      if (success) {
        final addresses = await _dnsService.getAllProxyAddresses();
        _isProxyRunning = true;
        _proxyAddress = addresses.isNotEmpty ? addresses.join(', ') : 'Unknown';
        
        onLogMessage('智能代理服务器启动成功');
        onLogMessage('代理地址: $_proxyAddress');
        onSnackBarMessage('智能代理服务器启动成功');
        onStateChanged();
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
      _isProxyRunning = false;
      _proxyAddress = '';
      
      if (success) {
        onLogMessage('智能代理服务器停止成功');
        onSnackBarMessage('智能代理服务器停止成功');
      } else {
        onLogMessage('智能代理服务器停止失败');
        onSnackBarMessage('智能代理服务器停止失败');
      }
      onStateChanged();
    } catch (e) {
      onLogMessage('智能代理服务器停止错误: $e');
      onSnackBarMessage('智能代理服务器停止错误: $e');
      rethrow;
    }
  }

  /// 记录解析统计
  void recordResolution(bool success) {
    _totalResolutions++;
    if (success) {
      _successfulResolutions++;
    } else {
      _failedResolutions++;
    }
    onStateChanged();
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    try {
      // 由于FlutterAliHttpDns没有直接的缓存统计方法，返回基本统计信息
      return {
        'totalResolutions': _totalResolutions,
        'successfulResolutions': _successfulResolutions,
        'failedResolutions': _failedResolutions,
        'successRate': successRate,
        'isInitialized': _isInitialized,
        'isProxyRunning': _isProxyRunning,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 清除缓存
  void clearCache() {
    try {
      // 由于FlutterAliHttpDns没有直接的清除缓存方法，重置统计信息
      resetStats();
      onLogMessage('DNS统计信息已重置');
      onStateChanged();
    } catch (e) {
      onLogMessage('重置统计失败: $e');
    }
  }

  /// 重置统计
  void resetStats() {
    _totalResolutions = 0;
    _successfulResolutions = 0;
    _failedResolutions = 0;
    onLogMessage('统计信息已重置');
    onStateChanged();
  }

  /// 释放资源
  void dispose() {
    _dnsService.dispose();
  }
}
