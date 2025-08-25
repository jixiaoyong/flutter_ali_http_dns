import 'package:flutter/material.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns_example/credentials.dart';

/// 服务管理器 - 负责DNS和代理服务的初始化和管理
class ServiceManager {
  final FlutterAliHttpDns _dnsService = FlutterAliHttpDns();
  bool _isInitialized = false;
  bool _isProxyRunning = false;
  String _proxyAddress = '';
  
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

  /// DNS配置
  DnsConfig get dnsConfig => const DnsConfig(
    accountId: AliHttpDnsCredentials.accountId,
    accessKeyId: AliHttpDnsCredentials.accessKeyId,
    accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
    enableCache: true,
    maxCacheSize: 1000,
    enableSpeedTest: true,
    timeout: 5,
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
      await _dnsService.initialize(dnsConfig);
      _isInitialized = true;
      onLogMessage('DNS 服务初始化成功');
      onSnackBarMessage('DNS 服务初始化成功');
      onStateChanged();
    } catch (e) {
      onLogMessage('DNS 服务初始化失败: $e');
      onSnackBarMessage('DNS 服务初始化失败: $e');
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
      final success = await _dnsService.startProxy(config: proxyConfig);

      if (success) {
        final addresses = await _dnsService.getAllProxyAddresses();
        _isProxyRunning = true;
        _proxyAddress = addresses.isNotEmpty ? addresses.join(', ') : 'Unknown';
        onLogMessage('智能代理服务器启动成功: ${addresses.join(', ')}');
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

  /// 释放资源
  void dispose() {
    _dnsService.dispose();
  }
}
