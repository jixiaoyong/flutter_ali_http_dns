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
  
  // 配置选项
  bool _enableSystemDnsFallback = true;
  bool _enableCache = true;
  bool _enableSpeedTest = true;
  
  // 当前显示的测试结果
  String _currentTestResult = '点击按钮开始测试';
  String _currentTestTitle = '测试结果';
  
  // 日志滚动控制器
  final ScrollController _logScrollController = ScrollController();

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
      onSnackBarMessage: _showSnackBar,
      isProxyRunning: _serviceManager.isProxyRunning,
      enableSystemDnsFallback: _enableSystemDnsFallback,
    );

    _advancedTests = AdvancedTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _advancedResult = result),
      onSnackBarMessage: _showSnackBar,
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
      onSnackBarMessage: _showSnackBar,
      isProxyRunning: _serviceManager.isProxyRunning,
      enableSystemDnsFallback: _enableSystemDnsFallback,
    );

    _advancedTests = AdvancedTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _advancedResult = result),
      onSnackBarMessage: _showSnackBar,
      isInitialized: _serviceManager.isInitialized,
      isProxyRunning: _serviceManager.isProxyRunning,
    );
  }

  /// 添加日志消息
  void _addLogMessage(String message) {
    setState(() {
      _logMessages = '${DateTime.now().toString().substring(11, 19)} $message\n$_logMessages';
    });
    // 滚动到最新日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// 添加日志分割线
  void _addLogDivider() {
    setState(() {
      _logMessages = '${DateTime.now().toString().substring(11, 19)} ========================================\n$_logMessages';
    });
    // 滚动到最新日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
    await _serviceManager.initializeDns(
      enableCache: _enableCache,
      enableSpeedTest: _enableSpeedTest,
    );
  }

  /// 启动代理
  Future<void> _startProxy() async {
    await _serviceManager.startProxy();
  }

  /// 停止代理
  Future<void> _stopProxy() async {
    await _serviceManager.stopProxy();
  }

  /// 清除缓存
  void _clearCache() {
    _serviceManager.clearCache();
  }
  
  /// 切换系统DNS回退
  void _toggleSystemDnsFallback(bool value) {
    setState(() {
      _enableSystemDnsFallback = value;
    });
  }
  
  /// 切换缓存启用
  void _toggleCache(bool value) {
    setState(() {
      _enableCache = value;
    });
  }
  
  /// 切换测速启用
  void _toggleSpeedTest(bool value) {
    setState(() {
      _enableSpeedTest = value;
    });
  }



  /// 测试域名解析
  Future<void> _testDomainResolution() async {
    setState(() {
      _currentTestTitle = '域名解析结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _basicTests.testDomainResolution();
    setState(() {
      _currentTestResult = _resolutionResult;
    });
  }

  /// 测试HttpClient
  Future<void> _testHttpClient() async {
    setState(() {
      _currentTestTitle = 'HttpClient 测试结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _basicTests.testHttpClient();
    setState(() {
      _currentTestResult = _httpResult;
    });
  }

  /// 测试Dio
  Future<void> _testDio() async {
    setState(() {
      _currentTestTitle = 'Dio 测试结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _basicTests.testDio();
    setState(() {
      _currentTestResult = _dioResult;
    });
  }

  /// 测试高级功能
  Future<void> _testAdvancedFeatures() async {
    setState(() {
      _currentTestTitle = '高级功能测试结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _advancedTests.testAdvancedFeatures();
    setState(() {
      _currentTestResult = _advancedResult;
    });
  }

  /// 测试性能
  Future<void> _testPerformance() async {
    setState(() {
      _currentTestTitle = '性能测试结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _advancedTests.testPerformance();
    setState(() {
      _currentTestResult = _advancedResult;
    });
  }

  /// 测试错误处理
  Future<void> _testErrorHandling() async {
    setState(() {
      _currentTestTitle = '错误处理测试结果';
      _currentTestResult = '正在测试...';
    });
    _addLogDivider();
    await _advancedTests.testErrorHandling();
    setState(() {
      _currentTestResult = _advancedResult;
    });
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
        elevation: 2,
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
              initializationStatus: _serviceManager.initializationStatus,
              lastError: _serviceManager.lastError,
              lastInitializationTime: _serviceManager.lastInitializationTime,
            ),
            const SizedBox(height: 16),

            // 控制面板
            UIComponents.buildControlPanelCard(
              context: context,
              isInitialized: _serviceManager.isInitialized,
              isProxyRunning: _serviceManager.isProxyRunning,
              enableSystemDnsFallback: _enableSystemDnsFallback,
              enableCache: _enableCache,
              enableSpeedTest: _enableSpeedTest,
              onInitializeDns: _initializeDns,
              onStartProxy: _startProxy,
              onStopProxy: _stopProxy,
              onClearCache: _clearCache,
              onSystemDnsFallbackChanged: _toggleSystemDnsFallback,
              onCacheChanged: _toggleCache,
              onSpeedTestChanged: _toggleSpeedTest,
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

            // 测试结果
            UIComponents.buildResultCard(
              context: context,
              title: _currentTestTitle,
              result: _currentTestResult,
            ),
            const SizedBox(height: 16),

            // 日志信息
            UIComponents.buildLogCard(
              context: context,
              logMessages: _logMessages,
              onClearLogs: _clearLogs,
              scrollController: _logScrollController,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serviceManager.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
}
