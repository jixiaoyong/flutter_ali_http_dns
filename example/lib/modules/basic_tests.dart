import 'dart:io';
import 'dart:convert';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// 基础功能测试模块 - 负责域名解析和基础HTTP测试
class BasicTests {
  final FlutterAliHttpDns _dnsService;
  final Function(String) onLogMessage;
  final Function(String) onResultUpdate;
  final Function(String) onSnackBarMessage;
  final bool isProxyRunning;
  final bool enableSystemDnsFallback;

  BasicTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.onSnackBarMessage,
    required this.isProxyRunning,
    required this.enableSystemDnsFallback,
  }) : _dnsService = dnsService;

  /// 测试域名解析
  Future<void> testDomainResolution() async {
    try {
      onResultUpdate('正在解析...');

      final domains = ['www.taobao.com', 'www.douyin.com', 'www.baidu.com'];
      final results = <String>[];
      int successCount = 0;
      int totalCount = domains.length;

      for (final domain in domains) {
        try {
          onLogMessage('开始解析域名: $domain');
          final ip = await _dnsService.resolveDomain(domain, enableSystemDnsFallback: enableSystemDnsFallback);
          
          if (ip != domain && ip.isNotEmpty) {
            results.add('✅ $domain -> $ip');
            successCount++;
            onLogMessage('域名解析成功: $domain -> $ip');
          } else {
            results.add('❌ $domain -> 解析失败 (返回原域名)');
            onLogMessage('域名解析失败: $domain (返回原域名)');
          }
        } catch (e) {
          results.add('❌ $domain -> 解析错误: $e');
          onLogMessage('域名解析异常: $domain -> $e');
        }
      }

      final successRate = (successCount / totalCount * 100).toStringAsFixed(1);
      final summary = '解析统计: $successCount/$totalCount 成功 (${successRate}%)';
      
      onResultUpdate('$summary\n\n${results.join('\n')}');
      onLogMessage('域名解析测试完成: $summary');
      
      // 显示 SnackBar 消息
      if (successCount > 0) {
        final firstSuccess = results.firstWhere(
          (result) => result.startsWith('✅'),
          orElse: () => '',
        );
        if (firstSuccess.isNotEmpty) {
          final parts = firstSuccess.split(' -> ');
          if (parts.length == 2) {
            onSnackBarMessage('解析成功: ${parts[0].substring(2)} -> ${parts[1]}');
          }
        }
      } else {
        onSnackBarMessage('域名解析失败，请检查网络连接');
      }
    } catch (e) {
      onResultUpdate('解析错误: $e');
      onLogMessage('域名解析测试失败: $e');
    }
  }

  /// 测试HttpClient
  Future<void> testHttpClient() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      onResultUpdate('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 HttpClient...');

      final client = HttpClient();
      await _dnsService.configureHttpClient(client);

      onLogMessage('HttpClient 已配置代理');

      // 测试普通 HTTP 请求（保持原域名和端口）
      final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      final result = 'HttpClient 请求成功\n'
          '状态码: ${response.statusCode}\n'
          '响应长度: ${responseBody.length} 字符\n'
          '代理配置: 已启用';
      
      onResultUpdate(result);
      onLogMessage('HttpClient 测试成功: 状态码 ${response.statusCode}');
      onSnackBarMessage('HttpClient 测试成功: 状态码 ${response.statusCode}');
    } catch (e) {
      onResultUpdate('HttpClient 请求错误: $e');
      onLogMessage('HttpClient 测试失败: $e');
      onSnackBarMessage('HttpClient 测试失败: ${e.toString().split(':').first}');
    }
  }

  /// 测试Dio
  Future<void> testDio() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      onResultUpdate('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 Dio...');

      final dio = Dio();
      final proxyConfig = await _dnsService.getDioProxyConfig();

      if (proxyConfig != null) {
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            final client = HttpClient();
            client.findProxy =
                (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
            return client;
          },
        );
        onLogMessage('Dio 已配置代理: ${proxyConfig['host']}:${proxyConfig['port']}');
      } else {
        onLogMessage('无法获取代理配置');
      }

      // 测试 Dio 请求（保持原域名和端口）
      final response = await dio.get('https://www.douyin.com');

      final result = 'Dio 请求成功\n'
          '状态码: ${response.statusCode}\n'
          '响应长度: ${response.data.toString().length} 字符\n'
          '代理配置: ${proxyConfig != null ? '已启用' : '未配置'}';
      
      onResultUpdate(result);
      onLogMessage('Dio 测试成功: 状态码 ${response.statusCode}');
      onSnackBarMessage('Dio 测试成功: 状态码 ${response.statusCode}');
    } catch (e) {
      onResultUpdate('Dio 请求错误: $e');
      onLogMessage('Dio 测试失败: $e');
      onSnackBarMessage('Dio 测试失败: ${e.toString().split(':').first}');
    }
  }

  /// 测试Dio代理功能
  Future<void> testDioProxy() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      onResultUpdate('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试 Dio 代理功能...');

      // 配置Dio使用代理
      final dio = Dio();
      final proxyConfig = await _dnsService.getDioProxyConfig();

      if (proxyConfig == null) {
        onLogMessage('无法获取代理配置');
        onResultUpdate('代理配置获取失败');
        return;
      }

      onLogMessage('代理配置: ${proxyConfig['host']}:${proxyConfig['port']}');

      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
          return client;
        },
      );

      // 测试请求
      final testUrls = [
        'https://httpbin.org/ip',
        'https://httpbin.org/user-agent',
        'https://httpbin.org/headers',
      ];

      final results = <String>[];
      int successCount = 0;

      for (final url in testUrls) {
        try {
          onLogMessage('测试请求: $url');
          
          final response = await dio.get(url);
          
          if (response.statusCode == 200) {
            final result = '✅ $url - 成功 (${response.statusCode})';
            onLogMessage(result);
            results.add(result);
            successCount++;
          } else {
            final result = '❌ $url - 失败 (${response.statusCode})';
            onLogMessage(result);
            results.add(result);
          }
        } catch (e) {
          final result = '❌ $url - 错误: $e';
          onLogMessage(result);
          results.add(result);
        }
      }

      final totalCount = results.length;
      final successRate = (successCount / totalCount * 100).toStringAsFixed(1);

      onResultUpdate(
        'Dio 代理测试完成\n'
        '成功: $successCount/$totalCount (${successRate}%)\n'
        '代理地址: ${proxyConfig['host']}:${proxyConfig['port']}\n'
        '详细结果:\n${results.join('\n')}'
      );

    } catch (e) {
      onLogMessage('Dio代理测试失败: $e');
      onResultUpdate('Dio代理测试失败: $e');
    }
  }
}
