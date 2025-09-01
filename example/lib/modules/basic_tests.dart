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
  final Function(String) onHttpResultUpdate; // 新增HttpClient结果回调
  final Function(String) onDioResultUpdate; // 新增Dio结果回调
  final Function(String) onSnackBarMessage;
  final bool isProxyRunning;

  BasicTests({
    required FlutterAliHttpDns dnsService,
    required this.onLogMessage,
    required this.onResultUpdate,
    required this.onHttpResultUpdate,
    required this.onDioResultUpdate,
    required this.onSnackBarMessage,
    required this.isProxyRunning,
  }) : _dnsService = dnsService;

  /// 测试域名解析
  Future<void> testDomainResolution(
      {required bool enableSystemDnsFallback}) async {
    try {
      onResultUpdate('正在解析...');

      final domains = ['www.taobao.com', 'www.douyin.com', 'www.baidu.com'];
      final results = <String>[];
      int successCount = 0;
      int totalCount = domains.length;

      for (final domain in domains) {
        try {
          onLogMessage('开始解析域名: $domain');
          final ip = await _dnsService.resolveDomainNullable(domain,
              enableSystemDnsFallback: enableSystemDnsFallback);

          if (ip != domain && ip != null && ip.isNotEmpty) {
            results.add('✅ $domain -> $ip');
            successCount++;
            onLogMessage('域名解析成功: $domain -> $ip');
          } else {
            results.add('❌ $domain -> $ip 解析失败/返回原域名');
            onLogMessage('域名解析失败: $ip');
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
      const errorMessage = '❌ HttpClient 测试失败\n'
          '   错误: 代理服务器未启动\n'
          '   解决方案: 请先点击"启动代理"按钮启动代理服务器\n'
          '   状态: 测试已终止';

      onLogMessage('HttpClient 测试失败: 代理服务器未启动');
      onHttpResultUpdate(errorMessage);
      onSnackBarMessage('HttpClient 测试失败: 请先启动代理服务器');
      return;
    }

    try {
      onHttpResultUpdate('正在测试 HttpClient...');

      final client = HttpClient();
      await _dnsService.configureHttpClient(client);

      onLogMessage('HttpClient 已配置代理');

      // 测试多个URL以获取更详细的结果
      final testUrls = [
        'https://httpbin.org/ip',
        'https://httpbin.org/user-agent',
        'https://www.taobao.com',
      ];

      final results = <String>[];
      int successCount = 0;
      int totalCount = testUrls.length;

      for (final url in testUrls) {
        try {
          onLogMessage('测试 HttpClient 请求: $url');

          final stopwatch = Stopwatch()..start();

          // 测试普通 HTTP 请求（保持原域名和端口）
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();

          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;

          // 获取响应头信息
          final contentType = response.headers.contentType?.toString() ?? '未知';
          final contentLength =
              response.headers.contentLength ?? responseBody.length;
          final server = response.headers.value('server') ?? '未知';
          final date = response.headers.value('date') ?? '未知';

          final result = '✅ $url\n'
              '   状态码: ${response.statusCode}\n'
              '   响应时间: ${duration}ms\n'
              '   内容类型: $contentType\n'
              '   内容长度: $contentLength 字节\n'
              '   服务器: $server\n'
              '   响应时间: $date\n'
              '   响应预览: ${responseBody.length > 100 ? responseBody.substring(0, 100) + '...' : responseBody}';

          results.add(result);
          successCount++;
          onLogMessage('HttpClient 请求成功: $url (${duration}ms)');

          // 实时更新结果
          final currentResult = 'HttpClient 测试进行中...\n'
              '已完成: $successCount/$totalCount\n'
              '详细结果:\n${results.join('\n\n')}';
          onHttpResultUpdate(currentResult);
        } catch (e) {
          final result = '❌ $url\n'
              '   错误: $e';
          results.add(result);
          onLogMessage('HttpClient 请求失败: $url -> $e');

          // 实时更新结果
          final currentResult = 'HttpClient 测试进行中...\n'
              '已完成: $successCount/$totalCount\n'
              '详细结果:\n${results.join('\n\n')}';
          onHttpResultUpdate(currentResult);
        }
      }

      final successRate = (successCount / totalCount * 100).toStringAsFixed(1);
      final summary =
          'HttpClient 测试统计: $successCount/$totalCount 成功 (${successRate}%)';

      final detailedResult = '$summary\n\n${results.join('\n\n')}';

      onHttpResultUpdate(detailedResult);
      onLogMessage('HttpClient 测试完成: $summary');
      onSnackBarMessage('HttpClient 测试完成: $successCount/$totalCount 成功');
    } catch (e) {
      final errorMessage = '❌ HttpClient 配置错误\n'
          '   错误: $e\n'
          '   状态: 测试已终止';
      onHttpResultUpdate(errorMessage);
      onLogMessage('HttpClient 测试失败: $e');
      onSnackBarMessage('HttpClient 测试失败: ${e.toString().split(':').first}');
    }
  }

  /// 测试Dio
  Future<void> testDio() async {
    if (!isProxyRunning) {
      const errorMessage = '❌ Dio 测试失败\n'
          '   错误: 代理服务器未启动\n'
          '   解决方案: 请先点击"启动代理"按钮启动代理服务器\n'
          '   状态: 测试已终止';

      onLogMessage('Dio 测试失败: 代理服务器未启动');
      onDioResultUpdate(errorMessage);
      onSnackBarMessage('Dio 测试失败: 请先启动代理服务器');
      return;
    }

    try {
      onDioResultUpdate('正在测试 Dio...');

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
        onLogMessage(
            'Dio 已配置代理: ${proxyConfig['host']}:${proxyConfig['port']}');
      } else {
        onLogMessage('无法获取代理配置');
      }

      // 测试多个URL以获取更详细的结果
      final testUrls = [
        'https://httpbin.org/ip',
        'https://httpbin.org/user-agent',
        'https://www.douyin.com',
      ];

      final results = <String>[];
      int successCount = 0;
      int totalCount = testUrls.length;

      for (final url in testUrls) {
        try {
          onLogMessage('测试 Dio 请求: $url');

          final stopwatch = Stopwatch()..start();

          // 测试 Dio 请求（保持原域名和端口）
          final response = await dio.get(url);

          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;

          // 获取响应头信息
          final headers = response.headers.map;
          final contentType = headers['content-type']?.first ?? '未知';
          final contentLength = headers['content-length']?.first ??
              response.data.toString().length.toString();
          final server = headers['server']?.first ?? '未知';
          final date = headers['date']?.first ?? '未知';

          final result = '✅ $url\n'
              '   状态码: ${response.statusCode}\n'
              '   响应时间: ${duration}ms\n'
              '   内容类型: $contentType\n'
              '   内容长度: $contentLength 字节\n'
              '   服务器: $server\n'
              '   响应时间: $date\n'
              '   代理配置: ${proxyConfig != null ? '已启用 (${proxyConfig['host']}:${proxyConfig['port']})' : '未配置'}\n'
              '   响应预览: ${response.data.toString().length > 100 ? response.data.toString().substring(0, 100) + '...' : response.data.toString()}';

          results.add(result);
          successCount++;
          onLogMessage('Dio 请求成功: $url (${duration}ms)');

          // 实时更新结果
          final currentResult = 'Dio 测试进行中...\n'
              '已完成: $successCount/$totalCount\n'
              '详细结果:\n${results.join('\n\n')}';
          onDioResultUpdate(currentResult);
        } catch (e) {
          final result = '❌ $url\n'
              '   错误: $e\n'
              '   代理配置: ${proxyConfig != null ? '已启用 (${proxyConfig['host']}:${proxyConfig['port']})' : '未配置'}';
          results.add(result);
          onLogMessage('Dio 请求失败: $url -> $e');

          // 实时更新结果
          final currentResult = 'Dio 测试进行中...\n'
              '已完成: $successCount/$totalCount\n'
              '详细结果:\n${results.join('\n\n')}';
          onDioResultUpdate(currentResult);
        }
      }

      final successRate = (successCount / totalCount * 100).toStringAsFixed(1);
      final summary =
          'Dio 测试统计: $successCount/$totalCount 成功 (${successRate}%)';

      final detailedResult = '$summary\n\n${results.join('\n\n')}';

      onDioResultUpdate(detailedResult);
      onLogMessage('Dio 测试完成: $summary');
      onSnackBarMessage('Dio 测试完成: $successCount/$totalCount 成功');
    } catch (e) {
      final errorMessage = '❌ Dio 配置错误\n'
          '   错误: $e\n'
          '   状态: 测试已终止';
      onDioResultUpdate(errorMessage);
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
          client.findProxy =
              (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
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

      onResultUpdate('Dio 代理测试完成\n'
          '成功: $successCount/$totalCount (${successRate}%)\n'
          '代理地址: ${proxyConfig['host']}:${proxyConfig['port']}\n'
          '详细结果:\n${results.join('\n')}');
    } catch (e) {
      onLogMessage('Dio代理测试失败: $e');
      onResultUpdate('Dio代理测试失败: $e');
    }
  }
}
