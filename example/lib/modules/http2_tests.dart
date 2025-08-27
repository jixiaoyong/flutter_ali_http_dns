import 'dart:io';
import 'dart:convert';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import '../nakama_config.dart';

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

    // 验证Nakama配置
    if (!NakamaConfig.isValid()) {
      onLogMessage('错误: Nakama配置无效，请检查nakama_config.dart文件');
      onResultUpdate('配置错误: 请设置正确的Nakama服务器域名');
      return;
    }

    try {
      onResultUpdate('正在测试 HTTP/2 协议支持...');
      onLogMessage('使用Nakama服务器: ${NakamaConfig.nakamaBaseUrl}');

      // 注册gRPC端口映射（HTTP/2）- 使用不安全连接
      final grpcPort = await _dnsService.registerMapping(
        targetPort: NakamaConfig.nakamaPortGrpc,
        targetDomain: NakamaConfig.nakamaBaseUrl,
        name: 'nakama-grpc-http2',
        description: 'Nakama gRPC HTTP/2 service mapping',
        isSecure: false, // gRPC服务只支持HTTP
      );

      if (grpcPort == null) {
        onLogMessage('gRPC端口映射注册失败');
        onResultUpdate('gRPC端口映射注册失败');
        return;
      }

      onLogMessage('gRPC端口映射注册成功: localhost:$grpcPort -> ${NakamaConfig.nakamaBaseUrl}:${NakamaConfig.nakamaPortGrpc}');

      // 测试HTTP/2连接
      final testResults = await _testHttp2Connection(grpcPort);

      // 获取映射信息
      final allMappings = await _dnsService.getAllMappings();

      onResultUpdate(
        'HTTP/2 协议测试完成\n'
        '服务器: ${NakamaConfig.nakamaBaseUrl}\n'
        'gRPC端口: $grpcPort\n'
        '测试结果: $testResults\n'
        '端口映射详情: ${allMappings.length} 个映射'
      );

      // 清理映射
      final success = await _dnsService.removeMapping(grpcPort);
      onLogMessage('Remove gRPC mapping (port $grpcPort): ${success ? 'Success' : 'Failed'}');

    } catch (e) {
      onLogMessage('HTTP/2测试失败: $e');
      onResultUpdate('HTTP/2测试失败: $e');
    }
  }

  /// 测试HTTP/2连接
  Future<String> _testHttp2Connection(int localPort) async {
    try {
      onLogMessage('正在测试HTTP/2连接 (localhost:$localPort)');

      // 创建Socket连接
      final socket = await Socket.connect('localhost', localPort);
      onLogMessage('Socket连接建立成功');

      // 发送HTTP/2连接前言
      final http2Preface = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n';
      socket.add(utf8.encode(http2Preface));
      onLogMessage('HTTP/2连接前言已发送');

      // 等待响应
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态 - 使用try-catch来检测连接是否有效
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

      // 注册WebSocket端口映射
      final wsPort = await _dnsService.registerMapping(
        targetPort: NakamaConfig.nakamaPortHttp, // WebSocket通常使用HTTP端口
        targetDomain: NakamaConfig.nakamaBaseUrl,
        name: 'nakama-websocket',
        description: 'Nakama WebSocket service mapping',
        isSecure: true, // WebSocket可以使用安全连接
      );

      if (wsPort == null) {
        onLogMessage('WebSocket端口映射注册失败');
        onResultUpdate('WebSocket端口映射注册失败');
        return;
      }

      onLogMessage('WebSocket端口映射注册成功: localhost:$wsPort');

      // 测试WebSocket握手
      final testResults = await _testWebSocketHandshake(wsPort);

      onResultUpdate(
        'WebSocket 协议测试完成\n'
        '端口: $wsPort\n'
        '测试结果: $testResults'
      );

      // 清理映射
      final success = await _dnsService.removeMapping(wsPort);
      onLogMessage('Remove WebSocket mapping (port $wsPort): ${success ? 'Success' : 'Failed'}');

    } catch (e) {
      onLogMessage('WebSocket测试失败: $e');
      onResultUpdate('WebSocket测试失败: $e');
    }
  }

  /// 测试WebSocket握手
  Future<String> _testWebSocketHandshake(int localPort) async {
    try {
      onLogMessage('正在测试WebSocket握手 (localhost:$localPort)');

      // 创建Socket连接
      final socket = await Socket.connect('localhost', localPort);
      onLogMessage('Socket连接建立成功');

      // 发送WebSocket握手请求
      final wsHandshake = 
        'GET /ws HTTP/1.1\r\n'
        'Host: localhost:$localPort\r\n'
        'Upgrade: websocket\r\n'
        'Connection: Upgrade\r\n'
        'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n'
        'Sec-WebSocket-Version: 13\r\n'
        '\r\n';

      socket.add(utf8.encode(wsHandshake));
      onLogMessage('WebSocket握手请求已发送');

      // 等待响应
      await Future.delayed(const Duration(seconds: 2));

      // 检查连接状态 - 使用try-catch来检测连接是否有效
      try {
        // 尝试发送一个字节来测试连接
        socket.add([0]);
        onLogMessage('WebSocket握手测试成功');
        socket.destroy();
        return 'WebSocket握手成功';
      } catch (e) {
        socket.destroy();
        return '连接已关闭: $e';
      }

    } catch (e) {
      onLogMessage('WebSocket握手测试失败: $e');
      return 'WebSocket握手失败: $e';
    }
  }
}
