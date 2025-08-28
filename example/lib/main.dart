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

  // 当前测试类型
  String _currentTestType = 'Dio'; // 当前测试类型：'Dio' 或 'HttpClient'

  // BottomSheet可见性
  bool _isBottomSheetVisible = true; // 默认显示

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
      onHttpResultUpdate: (result) => setState(() => _httpResult = result),
      onDioResultUpdate: (result) => setState(() => _dioResult = result),
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

    // 设置默认状态
    setState(() {
      _currentTestType = 'General';
      _currentTestTitle = '测试结果';
      _currentTestResult = '点击上方按钮开始测试';
    });
  }

  /// 更新测试模块状态
  void _updateTestModules() {
    _basicTests = BasicTests(
      dnsService: _serviceManager.dnsService,
      onLogMessage: _addLogMessage,
      onResultUpdate: (result) => setState(() => _resolutionResult = result),
      onHttpResultUpdate: (result) => setState(() => _httpResult = result),
      onDioResultUpdate: (result) => setState(() => _dioResult = result),
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
      _logMessages =
          '${DateTime.now().toString().substring(11, 19)} $message\n$_logMessages';
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
      _logMessages =
          '${DateTime.now().toString().substring(11, 19)} ========================================\n$_logMessages';
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
      _currentTestType = 'Domain';
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
      _httpResult = '正在测试...';
      _currentTestType = 'HttpClient';
    });

    _addLogDivider();
    await _basicTests.testHttpClient();

    // 确保结果被正确更新
    setState(() {
      _currentTestResult = _httpResult;
    });
  }

  /// 测试Dio
  Future<void> _testDio() async {
    setState(() {
      _currentTestTitle = 'Dio 测试结果';
      _currentTestResult = '正在测试...';
      _dioResult = '正在测试...';
      _currentTestType = 'Dio';
    });

    _addLogDivider();
    await _basicTests.testDio();

    // 确保结果被正确更新
    setState(() {
      _currentTestResult = _dioResult;
    });
  }

  /// 测试高级功能
  Future<void> _testAdvancedFeatures() async {
    setState(() {
      _currentTestTitle = '高级功能测试结果';
      _currentTestResult = '正在测试...';
      _currentTestType = 'Advanced';
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
      _currentTestType = 'Performance';
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
      _currentTestType = 'Error';
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

  /// 显示BottomSheet
  void _showBottomSheet() {
    setState(() {
      _isBottomSheetVisible = true;
    });
  }

  /// 隐藏BottomSheet
  void _hideBottomSheet() {
    // 使用Navigator.pop()来关闭BottomSheet
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () {
              setState(() {
                _isBottomSheetVisible = !_isBottomSheetVisible;
              });
            },
            tooltip: _isBottomSheetVisible ? '隐藏详情' : '显示详情',
          ),
        ],
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
            )
          ],
        ),
      ),
      bottomSheet: _isBottomSheetVisible
          ? Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 拖拽手柄
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _currentTestType == 'Dio' ||
                                    _currentTestType == 'HttpClient'
                                ? '${_currentTestType}测试结果 & 日志信息'
                                : '${_currentTestTitle} & 日志信息',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: _clearLogs,
                              icon: const Icon(Icons.clear),
                              label: const Text('清空日志'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isBottomSheetVisible = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _logScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 详细测试结果
                          Text(
                            _currentTestType == 'Dio' ||
                                    _currentTestType == 'HttpClient'
                                ? '${_currentTestType}测试结果'
                                : '测试结果',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              _currentTestType == 'Dio'
                                  ? _dioResult
                                  : _currentTestType == 'HttpClient'
                                      ? _httpResult
                                      : _currentTestResult,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 日志信息
                          Text(
                            '日志信息',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SingleChildScrollView(
                              controller: _logScrollController,
                              child: SelectableText(
                                _logMessages.isEmpty ? '暂无日志信息' : _logMessages,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _serviceManager.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
}
