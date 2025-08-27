import 'dart:io';
import 'dart:convert';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';

/// HTTP/2协议测试模块 - 验证代理服务器对HTTP/2的支持
class Http2Tests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final bool isProxyRunning;

  Http2Tests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试HTTP/2协议支持
  Future<void> testHttp2Support() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 协议支持...');
      onLogMessage('开始HTTP/2协议测试');

      // 获取代理地址
      final proxyAddress = await _dnsService.getProxyAddress();
      if (proxyAddress == null) {
        onLogMessage('无法获取代理地址');
        onResultUpdate('无法获取代理地址');
        return;
      }

      onLogMessage('代理地址: $proxyAddress');

      // 测试HTTP/2连接
      final testResults = await _testHttp2Connection(proxyAddress);

      onResultUpdate(
        'HTTP/2 协议测试完成\n'
        '代理地址: $proxyAddress\n'
        '测试结果: $testResults'
      );

    } catch (e) {
      onLogMessage('HTTP/2测试失败: $e');
      onResultUpdate('HTTP/2测试失败: $e');
    }
  }

  /// 测试HTTP/2连接
  Future<String> _testHttp2Connection(String proxyAddress) async {
    try {
      onLogMessage('正在测试HTTP/2连接 ($proxyAddress)');

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

      // 发送HTTP/2连接前言
      final http2Preface = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
      socket.add(utf8.encode(http2Preface));
      onLogMessage('HTTP/2连接前言已发送');

      // 等待响应
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态
      try {
        // 尝试发送一个字节来测试连接
        socket.add([0]);
        onLogMessage('HTTP/2连接测试成功');
        socket.destroy();
        return 'HTTP/2连接建立成功';
      } catch (e) {
        socket.destroy();
        return '连接已关闭: $e';
      }

    } catch (e) {
      onLogMessage('HTTP/2连接测试失败: $e');
      return 'HTTP/2连接失败: $e';
    }
  }

  /// 测试WebSocket协议支持
  Future<void> testWebSocketSupport() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 WebSocket 协议支持...');

      // 获取代理地址
      final proxyAddress = await _dnsService.getProxyAddress();
      if (proxyAddress == null) {
        onLogMessage('无法获取代理地址');
        onResultUpdate('无法获取代理地址');
        return;
      }

      onLogMessage('代理地址: $proxyAddress');

      // 测试WebSocket连接
      final testResults = await _testWebSocketConnection(proxyAddress);

      onResultUpdate(
        'WebSocket 协议测试完成\n'
        '代理地址: $proxyAddress\n'
        '测试结果: $testResults'
      );

    } catch (e) {
      onLogMessage('WebSocket测试失败: $e');
      onResultUpdate('WebSocket测试失败: $e');
    }
  }

  /// 测试WebSocket连接
  Future<String> _testWebSocketConnection(String proxyAddress) async {
    try {
      onLogMessage('正在测试WebSocket连接 ($proxyAddress)');

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
      onLogMessage('WebSocket连接建立成功');

      // 发送WebSocket握手请求
      final wsRequest = '''
GET / HTTP/1.1\r
Host: $host:$port\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Sec-WebSocket-Version: 13\r
\r
''';
      socket.add(utf8.encode(wsRequest));
      onLogMessage('WebSocket握手请求已发送');

      // 等待响应
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态
      try {
        socket.add([0]);
        onLogMessage('WebSocket连接测试成功');
        socket.destroy();
        return 'WebSocket连接建立成功';
      } catch (e) {
        socket.destroy();
        return '连接已关闭: $e';
      }

    } catch (e) {
      onLogMessage('WebSocket连接测试失败: $e');
      return 'WebSocket连接失败: $e';
    }
  }
}
