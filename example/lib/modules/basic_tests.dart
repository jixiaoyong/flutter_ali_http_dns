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
  final bool isProxyRunning;

  BasicTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试域名解析
  Future<void> testDomainResolution() async {
    try {
      onResultUpdate('正在解析...');

      final domains = ['www.taobao.com', 'www.douyin.com', 'www.baidu.com'];
      final results = <String>[];

      for (final domain in domains) {
        try {
          final ip = await _dnsService.resolveDomain(domain);
          results.add('$domain -> $ip');
        } catch (e) {
          results.add('$domain -> 解析失败: $e');
        }
      }

      onResultUpdate(results.join('\n'));
      onLogMessage('域名解析测试完成');
    } catch (e) {
      onResultUpdate('解析错误: $e');
      onLogMessage('域名解析测试失败: $e');
    }
  }

  /// 测试HttpClient
  Future<void> testHttpClient() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试...');

      final client = HttpClient();
      await _dnsService.configureHttpClient(client);

      // 测试普通 HTTP 请求（保持原域名和端口）
      final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      onResultUpdate(
        'HTTP 请求成功\n状态码: ${response.statusCode}\n响应长度: ${responseBody.length}'
      );
      onLogMessage('HttpClient 测试成功');
    } catch (e) {
      onResultUpdate('HTTP 请求错误: $e');
      onLogMessage('HttpClient 测试失败: $e');
    }
  }

  /// 测试Dio
  Future<void> testDio() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
      return;
    }

    try {
      onResultUpdate('正在测试...');

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
      }

      // 测试 Dio 请求（保持原域名和端口）
      final response = await dio.get('https://www.douyin.com');

      onResultUpdate(
        'Dio 请求成功\n状态码: ${response.statusCode}\n响应长度: ${response.data.toString().length}'
      );
      onLogMessage('Dio 测试成功');
    } catch (e) {
      onResultUpdate('Dio 请求错误: $e');
      onLogMessage('Dio 测试失败: $e');
    }
  }

  /// 测试Dio代理功能
  Future<void> testDioProxy() async {
    if (!isProxyRunning) {
      onLogMessage('请先启动代理服务器');
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

      for (final url in testUrls) {
        try {
          onLogMessage('测试请求: $url');
          
          final response = await dio.get(url);
          
          if (response.statusCode == 200) {
            final result = '✅ $url - 成功 (${response.statusCode})';
            onLogMessage(result);
            results.add(result);
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

      final successCount = results.where((r) => r.contains('✅')).length;
      final totalCount = results.length;

      onResultUpdate(
        'Dio 代理测试完成\n'
        '成功: $successCount/$totalCount\n'
        '代理地址: ${proxyConfig['host']}:${proxyConfig['port']}\n'
        '详细结果:\n${results.join('\n')}'
      );

    } catch (e) {
      onLogMessage('Dio代理测试失败: $e');
      onResultUpdate('Dio代理测试失败: $e');
    }
  }
}
