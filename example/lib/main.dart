import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ali_http_dns/flutter_ali_http_dns.dart';
import 'package:flutter_ali_http_dns/src/models/dns_config.dart';
import 'package:flutter_ali_http_dns/src/models/proxy_config.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'credentials.dart';
import 'dns_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Ali HttpDNS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Ali HttpDNS Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterAliHttpDns _dnsPlugin = FlutterAliHttpDns.instance;
  bool _isInitialized = false;
  bool _isProxyRunning = false;
  String _resolutionResult = '点击按钮开始测试';
  String _httpResult = '点击按钮开始测试';
  String _dioResult = '点击按钮开始测试';
  String _nakamaResult = '点击按钮开始测试';

  // 配置参数（使用配置文件）
  final _dnsConfig = const DnsConfig(
    accountId: AliHttpDnsCredentials.accountId,
    accessKeyId: AliHttpDnsCredentials.accessKeyId,
    accessKeySecret: AliHttpDnsCredentials.accessKeySecret,
    enableCache: AliHttpDnsConfig.enableCache,
    maxCacheSize: AliHttpDnsConfig.maxCacheSize,
    maxNegativeCache: AliHttpDnsConfig.maxNegativeCache,
    enableIPv6: AliHttpDnsConfig.enableIPv6,
    enableShort: false,
    enableSpeedTest: AliHttpDnsConfig.enableSpeedTest,
    preloadDomains: AliHttpDnsConfig.preloadDomains,
    keepAliveDomains: AliHttpDnsConfig.keepAliveDomains,
    timeout: AliHttpDnsConfig.timeout,
    maxCacheTTL: AliHttpDnsConfig.maxCacheTTL,
    ispEnable: AliHttpDnsConfig.ispEnable,
    speedPort: AliHttpDnsConfig.speedPort,
  );

  // 智能代理配置
  final _proxyConfig = const ProxyConfig(
    port: 4041,
    portMap: {
      '4041': 7350, // Nakama HTTP 端口映射
      '4042': 7349, // Nakama gRPC 端口映射
    },
    fixedDomain: {
      '4041': 'api.game-service.com', // 游戏服务域名
      '4042': 'chat.game-service.com', // 聊天服务域名
    },
    enabled: true,
    host: 'localhost',
  );

  @override
  void initState() {
    super.initState();
    _initializeDns();
  }

  Future<void> _initializeDns() async {
    try {
      final result = await _dnsPlugin.initialize(_dnsConfig);
      setState(() {
        _isInitialized = result;
      });
      if (result) {
        _showSnackBar('DNS 服务初始化成功');
      } else {
        _showSnackBar('DNS 服务初始化失败');
      }
    } catch (e) {
      _showSnackBar('DNS 服务初始化错误: $e');
    }
  }

  Future<void> _startProxy() async {
    if (!_isInitialized) {
      _showSnackBar('请先初始化 DNS 服务');
      return;
    }

    try {
      final result = await _dnsPlugin.startProxy(_proxyConfig);
      setState(() {
        _isProxyRunning = result;
      });
      if (result) {
        _showSnackBar('智能代理服务器启动成功');
      } else {
        _showSnackBar('智能代理服务器启动失败');
      }
    } catch (e) {
      _showSnackBar('智能代理服务器启动错误: $e');
    }
  }

  Future<void> _stopProxy() async {
    try {
      final result = await _dnsPlugin.stopProxy();
      setState(() {
        _isProxyRunning = !result;
      });
      if (result) {
        _showSnackBar('智能代理服务器停止成功');
      } else {
        _showSnackBar('智能代理服务器停止失败');
      }
    } catch (e) {
      _showSnackBar('智能代理服务器停止错误: $e');
    }
  }

  Future<void> _testDomainResolution() async {
    if (!_isInitialized) {
      _showSnackBar('请先初始化 DNS 服务');
      return;
    }

    try {
      setState(() {
        _resolutionResult = '正在解析...';
      });

      final domains = ['www.taobao.com', 'www.douyin.com', 'www.baidu.com'];
      final results = <String>[];

      for (final domain in domains) {
        final ip = await _dnsPlugin.resolveDomain(domain);
        results.add('$domain -> $ip');
      }

      setState(() {
        _resolutionResult = results.join('\n');
      });
    } catch (e) {
      setState(() {
        _resolutionResult = '解析错误: $e';
      });
    }
  }

  Future<void> _testHttpClient() async {
    if (!_isProxyRunning) {
      _showSnackBar('请先启动代理服务器');
      return;
    }

    try {
      setState(() {
        _httpResult = '正在测试...';
      });

      final client = HttpClient();
      await _dnsPlugin.configureHttpClient(client);

      // 测试普通 HTTP 请求（保持原域名和端口）
      final request = await client.getUrl(Uri.parse('https://www.taobao.com'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      setState(() {
        _httpResult = 'HTTP 请求成功\n状态码: ${response.statusCode}\n响应长度: ${responseBody.length}';
      });
    } catch (e) {
      setState(() {
        _httpResult = 'HTTP 请求错误: $e';
      });
    }
  }

  Future<void> _testDio() async {
    if (!_isProxyRunning) {
      _showSnackBar('请先启动代理服务器');
      return;
    }

    try {
      setState(() {
        _dioResult = '正在测试...';
      });

      final dio = Dio();
      final proxyConfig = await _dnsPlugin.getDioProxyConfig();
      
      if (proxyConfig != null) {
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            final client = HttpClient();
            client.findProxy = (uri) => 'PROXY ${proxyConfig['host']}:${proxyConfig['port']}';
            return client;
          },
        );
      }

      // 测试 Dio 请求（保持原域名和端口）
      final response = await dio.get('https://www.douyin.com');
      
      setState(() {
        _dioResult = 'Dio 请求成功\n状态码: ${response.statusCode}\n响应长度: ${response.data.toString().length}';
      });
    } catch (e) {
      setState(() {
        _dioResult = 'Dio 请求错误: $e';
      });
    }
  }

  Future<void> _testNakamaProxy() async {
    if (!_isProxyRunning) {
      _showSnackBar('请先启动代理服务器');
      return;
    }

    try {
      setState(() {
        _nakamaResult = '正在测试 Nakama 代理...';
      });

      final client = HttpClient();
      await _dnsPlugin.configureHttpClient(client);

      // 测试 Nakama 场景（使用 localhost + 端口映射）
      // 这里模拟 Nakama 连接到 localhost:4041，代理会自动映射到固定域名和端口
      // 注意：使用HTTP协议，因为目标服务器可能不支持HTTPS
      final request = await client.getUrl(Uri.parse('http://localhost:4041'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      setState(() {
        _nakamaResult = 'Nakama 代理测试成功\n状态码: ${response.statusCode}\n响应长度: ${responseBody.length}';
      });
    } catch (e) {
      setState(() {
        _nakamaResult = 'Nakama 代理测试错误: $e';
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 状态信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '服务状态',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('DNS 服务: ${_isInitialized ? "已初始化" : "未初始化"}'),
                    Text('智能代理服务器: ${_isProxyRunning ? "运行中" : "已停止"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 控制按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '控制面板',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isInitialized ? null : _initializeDns,
                      child: const Text('初始化 DNS 服务'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isProxyRunning ? null : _startProxy,
                      child: const Text('启动智能代理服务器'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isProxyRunning ? _stopProxy : null,
                      child: const Text('停止智能代理服务器'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 测试按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '功能测试',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _testDomainResolution,
                      child: const Text('测试域名解析'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _testHttpClient,
                      child: const Text('测试 HttpClient (Dio 场景)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _testDio,
                      child: const Text('测试 Dio (Dio 场景)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _testNakamaProxy,
                      child: const Text('测试 Nakama 代理'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 结果显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '域名解析结果',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(_resolutionResult),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HttpClient 测试结果 (Dio 场景)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(_httpResult),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dio 测试结果 (Dio 场景)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(_dioResult),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nakama 代理测试结果',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(_nakamaResult),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dnsPlugin.dispose();
    super.dispose();
  }
}
