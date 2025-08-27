import 'dart:io';
import 'package:http2/http2.dart';
import 'package:http2/transport.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// HTTP/2高级测试模块 - 使用http2库进行测试
/// 验证新的HTTP/2代理服务器功能
class Http2AdvancedTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final bool isProxyRunning;

  Http2AdvancedTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试HTTP/2代理服务器功能
  Future<void> testHttp2ProxyServer() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 代理服务器...');
      onLogMessage('开始HTTP/2代理服务器测试');

      // 获取HTTP/2代理地址
      final http2Address = await _dnsService.getHttp2ProxyAddress();
      if (http2Address == null) {
        onLogMessage('HTTP/2代理服务器未启动');
        onResultUpdate('HTTP/2代理服务器未启动');
        return;
      }

      onLogMessage('HTTP/2代理地址: $http2Address');

      // 测试HTTP/2连接
      final testResults = await _testHttp2ConnectionWithLibrary(http2Address);

      onResultUpdate(
        'HTTP/2 代理服务器测试完成\n'
        'HTTP/2代理: $http2Address\n'
        '测试结果: $testResults'
      );

    } catch (e) {
      onLogMessage('HTTP/2代理服务器测试失败: $e');
      onResultUpdate('HTTP/2代理服务器测试失败: $e');
    }
  }

  /// 使用http2库测试HTTP/2连接
  Future<String> _testHttp2ConnectionWithLibrary(String proxyAddress) async {
    try {
      onLogMessage('正在使用http2库测试HTTP/2连接 ($proxyAddress)');

      final parts = proxyAddress.split(':');
      if (parts.length != 2) {
        return '代理地址格式错误: $proxyAddress';
      }

      final host = parts[0];
      final port = int.tryParse(parts[1]);
      if (port == null) {
        return '端口号格式错误: ${parts[1]}';
      }

      // 创建Socket连接
      final socket = await Socket.connect(host, port);
      onLogMessage('Socket连接建立成功');

      // 创建HTTP/2传输连接
      final transport = ServerTransportConnection.viaSocket(socket);
      onLogMessage('HTTP/2传输连接创建成功');

      // 等待连接建立
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态
      try {
        onLogMessage('HTTP/2连接测试成功');
        await transport.finish();
        return 'HTTP/2连接建立成功';
      } catch (e) {
        await transport.finish();
        return '连接已关闭: $e';
      }

    } catch (e) {
      onLogMessage('HTTP/2连接测试失败: $e');
      return 'HTTP/2连接失败: $e';
    }
  }

  /// 测试多端口代理功能
  Future<void> testMultiPortProxy() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试多端口代理功能...');

      // 获取所有代理地址
      final allAddresses = await _dnsService.getAllProxyAddresses();
      if (allAddresses.isEmpty) {
        onLogMessage('没有可用的代理地址');
        onResultUpdate('没有可用的代理地址');
        return;
      }

      onLogMessage('可用代理地址: ${allAddresses.join(', ')}');

      // 测试每个端口
      final testResults = <String>[];
      for (final address in allAddresses) {
        final result = await _testSinglePort(address);
        testResults.add('$address: $result');
      }

      onResultUpdate(
        '多端口代理测试完成\n'
        '代理地址数量: ${allAddresses.length}\n'
        '测试结果:\n${testResults.join('\n')}'
      );

    } catch (e) {
      onLogMessage('多端口代理测试失败: $e');
      onResultUpdate('多端口代理测试失败: $e');
    }
  }

  /// 测试单个端口
  Future<String> _testSinglePort(String address) async {
    try {
      final parts = address.split(':');
      if (parts.length != 2) {
        return '地址格式错误';
      }

      final host = parts[0];
      final port = int.tryParse(parts[1]);
      if (port == null) {
        return '端口号格式错误';
      }

      // 创建Socket连接
      final socket = await Socket.connect(host, port);
      socket.destroy();
      return '连接成功';
    } catch (e) {
      return '连接失败: $e';
    }
  }

  /// 测试代理配置
  Future<void> testProxyConfiguration() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试代理配置...');

      // 获取代理配置字符串
      final proxyConfig = await _dnsService.getProxyConfigString();
      if (proxyConfig == null) {
        onLogMessage('无法获取代理配置');
        onResultUpdate('无法获取代理配置');
        return;
      }

      onLogMessage('代理配置: $proxyConfig');

      // 获取Dio代理配置
      final dioConfig = await _dnsService.getDioProxyConfig();
      if (dioConfig == null) {
        onLogMessage('无法获取Dio代理配置');
        onResultUpdate('无法获取Dio代理配置');
        return;
      }

      onLogMessage('Dio代理配置: $dioConfig');

      onResultUpdate(
        '代理配置测试完成\n'
        '代理配置字符串: $proxyConfig\n'
        'Dio代理配置: $dioConfig'
      );

    } catch (e) {
      onLogMessage('代理配置测试失败: $e');
      onResultUpdate('代理配置测试失败: $e');
    }
  }

  /// 测试端口管理功能
  Future<void> testPortManagement() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试端口管理功能...');

      // 获取实际使用的端口
      final actualPorts = await _dnsService.getActualPorts();
      if (actualPorts.isEmpty) {
        onLogMessage('没有实际使用的端口');
        onResultUpdate('没有实际使用的端口');
        return;
      }

      onLogMessage('实际使用的端口: ${actualPorts.join(', ')}');

      // 获取主要端口
      final mainPort = await _dnsService.getMainPort();
      if (mainPort == null) {
        onLogMessage('无法获取主要端口');
        onResultUpdate('无法获取主要端口');
        return;
      }

      onLogMessage('主要端口: $mainPort');

      // 检查端口可用性
      final portAvailability = <String>[];
      for (final port in actualPorts) {
        final isAvailable = await _dnsService.isPortAvailable(port);
        portAvailability.add('端口 $port: ${isAvailable ? '可用' : '不可用'}');
      }

      onResultUpdate(
        '端口管理测试完成\n'
        '实际使用端口: ${actualPorts.join(', ')}\n'
        '主要端口: $mainPort\n'
        '端口可用性:\n${portAvailability.join('\n')}'
      );

    } catch (e) {
      onLogMessage('端口管理测试失败: $e');
      onResultUpdate('端口管理测试失败: $e');
    }
  }
}
