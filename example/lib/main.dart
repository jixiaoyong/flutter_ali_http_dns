import 'package:flutter/material.dart';
import 'modules/modules.dart';

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
  // 服务管理器
  late ServiceManager _serviceManager;
  
  // 测试模块
  late BasicTests _basicTests;
  late AdvancedTests _advancedTests;

  // 状态变量
  String _resolutionResult = '点击按钮开始测试';
  String _httpResult = '点击按钮开始测试';
  String _dioResult = '点击按钮开始测试';
  String _advancedResult = '点击按钮开始测试';
  String _logMessages = '';

  @override
  void initState() {
    super.initState();
    _initializeModules();
  }

  /// 初始化所有模块
  void _initializeModules() {
    // 初始化服务管理器
    _serviceManager = ServiceManager(
      onLogMessage: _addLogMessage,
      onSnackBarMessage: _showSnackBar,
      onStateChanged: _updateState,
    );

    // 初始化测试模块
    _basicTests = BasicTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _resolutionResult = result),
      isProxyRunning: _serviceManager.isProxyRunning,
    );

    _advancedTests = AdvancedTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _advancedResult = result),
      isInitialized: _serviceManager.isInitialized,
      isProxyRunning: _serviceManager.isProxyRunning,
    );
  }

  /// 更新测试模块状态
  void _updateTestModules() {
    _basicTests = BasicTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _resolutionResult = result),
      isProxyRunning: _serviceManager.isProxyRunning,
    );

    _advancedTests = AdvancedTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _advancedResult = result),
      isInitialized: _serviceManager.isInitialized,
      isProxyRunning: _serviceManager.isProxyRunning,
    );
  }

  /// 添加日志消息
  void _addLogMessage(String message) {
    setState(() {
      _logMessages = '${DateTime.now().toString().substring(11, 19)} $message\n$_logMessages';
    });
  }

  /// 显示SnackBar消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 更新状态
  void _updateState() {
    setState(() {});
    _updateTestModules();
  }

  /// 初始化DNS
  Future<void> _initializeDns() async {
    await _serviceManager.initializeDns();
  }

  /// 启动代理
  Future<void> _startProxy() async {
    await _serviceManager.startProxy();
  }

  /// 停止代理
  Future<void> _stopProxy() async {
    await _serviceManager.stopProxy();
  }

  /// 测试域名解析
  Future<void> _testDomainResolution() async {
    await _basicTests.testDomainResolution();
  }

  /// 测试HttpClient
  Future<void> _testHttpClient() async {
    await _basicTests.testHttpClient();
    setState(() => _httpResult = _resolutionResult);
  }

  /// 测试Dio
  Future<void> _testDio() async {
    await _basicTests.testDio();
    setState(() => _dioResult = _resolutionResult);
  }

  /// 测试高级功能
  Future<void> _testAdvancedFeatures() async {
    await _advancedTests.testAdvancedFeatures();
  }

  /// 测试性能
  Future<void> _testPerformance() async {
    await _advancedTests.testPerformance();
  }

  /// 测试错误处理
  Future<void> _testErrorHandling() async {
    await _advancedTests.testErrorHandling();
  }

  /// 清除日志
  void _clearLogs() {
    setState(() {
      _logMessages = '';
    });
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
            UIComponents.buildStatusCard(
              context: context,
              isInitialized: _serviceManager.isInitialized,
              isProxyRunning: _serviceManager.isProxyRunning,
              proxyAddress: _serviceManager.proxyAddress,
            ),
            const SizedBox(height: 16),

            // 控制面板
            UIComponents.buildControlPanelCard(
              context: context,
              isInitialized: _serviceManager.isInitialized,
              isProxyRunning: _serviceManager.isProxyRunning,
              onInitializeDns: _initializeDns,
              onStartProxy: _startProxy,
              onStopProxy: _stopProxy,
            ),
            const SizedBox(height: 16),

            // 功能测试
            UIComponents.buildFunctionTestCard(
              context: context,
              onTestDomainResolution: _testDomainResolution,
              onTestHttpClient: _testHttpClient,
              onTestDio: _testDio,
            ),
            const SizedBox(height: 16),

            // 高级功能测试
            UIComponents.buildAdvancedTestCard(
              context: context,
              isInitialized: _serviceManager.isInitialized,
              onTestAdvancedFeatures: _testAdvancedFeatures,
              onTestPerformance: _testPerformance,
              onTestErrorHandling: _testErrorHandling,
            ),
            const SizedBox(height: 16),

            // 域名解析结果
            UIComponents.buildResultCard(
              context: context,
              title: '域名解析结果',
              result: _resolutionResult,
            ),
            const SizedBox(height: 16),

            // HttpClient测试结果
            UIComponents.buildResultCard(
              context: context,
              title: 'HttpClient 测试结果',
              result: _httpResult,
            ),
            const SizedBox(height: 16),

            // Dio测试结果
            UIComponents.buildResultCard(
              context: context,
              title: 'Dio 测试结果',
              result: _dioResult,
            ),
            const SizedBox(height: 16),

            // 高级功能测试结果
            UIComponents.buildResultCard(
              context: context,
              title: '高级功能测试结果',
              result: _advancedResult,
            ),
            const SizedBox(height: 16),

            // 日志信息
            UIComponents.buildLogCard(
              context: context,
              logMessages: _logMessages,
              onClearLogs: _clearLogs,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serviceManager.dispose();
    super.dispose();
  }
}
