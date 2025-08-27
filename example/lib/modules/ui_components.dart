import 'package:flutter/material.dart';

/// UI组件模块 - 负责构建各种UI组件
class UIComponents {
  /// 构建状态信息卡片
  static Widget buildStatusCard({
    required BuildContext context,
    required bool isInitialized,
    required bool isProxyRunning,
    required String proxyAddress,
  }) {
    return Card(
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
            Text('DNS 服务: ${isInitialized ? "已初始化" : "未初始化"}'),
            Text('智能代理服务器: ${isProxyRunning ? "运行中" : "已停止"}'),
            if (proxyAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('代理地址: $proxyAddress'),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建控制面板卡片
  static Widget buildControlPanelCard({
    required BuildContext context,
    required bool isInitialized,
    required bool isProxyRunning,
    required VoidCallback onInitializeDns,
    required VoidCallback onStartProxy,
    required VoidCallback onStopProxy,
  }) {
    return Card(
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
              onPressed: isInitialized ? null : onInitializeDns,
              child: const Text('初始化 DNS 服务'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isProxyRunning ? null : onStartProxy,
              child: const Text('启动智能代理服务器'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isProxyRunning ? onStopProxy : null,
              child: const Text('停止智能代理服务器'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能测试卡片
  static Widget buildFunctionTestCard({
    required BuildContext context,
    required VoidCallback onTestDomainResolution,
    required VoidCallback onTestHttpClient,
    required VoidCallback onTestDio,
  }) {
    return Card(
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
              onPressed: onTestDomainResolution,
              child: const Text('测试域名解析'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onTestHttpClient,
              child: const Text('测试 HttpClient'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onTestDio,
              child: const Text('测试 Dio'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建高级功能测试卡片
  static Widget buildAdvancedTestCard({
    required BuildContext context,
    required bool isInitialized,
    required VoidCallback onTestAdvancedFeatures,
    required VoidCallback onTestPerformance,
    required VoidCallback onTestErrorHandling,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '高级功能测试',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isInitialized ? onTestAdvancedFeatures : null,
              child: const Text('测试高级功能'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isInitialized ? onTestPerformance : null,
              child: const Text('测试性能'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isInitialized ? onTestErrorHandling : null,
              child: const Text('测试错误处理'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建结果显示卡片
  static Widget buildResultCard({
    required BuildContext context,
    required String title,
    required String result,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(result),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建日志信息卡片
  static Widget buildLogCard({
    required BuildContext context,
    required String logMessages,
    required VoidCallback onClearLogs,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '日志信息',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: onClearLogs,
                  child: const Text('清空日志'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  logMessages.isEmpty ? '暂无日志信息' : logMessages,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
