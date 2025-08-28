import 'package:flutter/material.dart';

/// UI组件模块 - 负责构建各种UI组件
class UIComponents {
  /// 构建状态信息卡片
  static Widget buildStatusCard({
    required BuildContext context,
    required bool isInitialized,
    required bool isProxyRunning,
    required String proxyAddress,
    required String initializationStatus,
    required String lastError,
    required DateTime? lastInitializationTime,
    required int totalResolutions,
    required int successfulResolutions,
    required int failedResolutions,
    required double successRate,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '服务状态',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // DNS服务状态
            _buildStatusRow(
              context,
              'DNS 服务',
              initializationStatus,
              isInitialized ? Colors.green : Colors.red,
            ),
            
            if (lastInitializationTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '初始化时间: ${lastInitializationTime.toString().substring(0, 19)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            if (lastError.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  '错误: $lastError',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 代理服务器状态
            _buildStatusRow(
              context,
              '智能代理服务器',
              isProxyRunning ? '运行中' : '已停止',
              isProxyRunning ? Colors.green : Colors.orange,
            ),
            
            if (proxyAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '代理地址: $proxyAddress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 统计信息
            _buildStatisticsSection(context, totalResolutions, successfulResolutions, failedResolutions, successRate),
          ],
        ),
      ),
    );
  }

  /// 构建状态行
  static Widget _buildStatusRow(BuildContext context, String label, String status, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建统计信息部分
  static Widget _buildStatisticsSection(BuildContext context, int total, int success, int failed, double rate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '解析统计',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '总解析',
                total.toString(),
                Icons.analytics,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '成功',
                success.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '失败',
                failed.toString(),
                Icons.error,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '成功率',
                '${rate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建统计卡片
  static Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
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
    required VoidCallback onClearCache,
    required VoidCallback onResetStats,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.control_camera,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '控制面板',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 主要控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isInitialized ? null : onInitializeDns,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('初始化 DNS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInitialized ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProxyRunning ? null : onStartProxy,
                    icon: const Icon(Icons.play_circle),
                    label: const Text('启动代理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isProxyRunning ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProxyRunning ? onStopProxy : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止代理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isProxyRunning ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 辅助控制按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClearCache,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清除缓存'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onResetStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置统计'),
                  ),
                ),
              ],
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '功能测试',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: onTestDomainResolution,
              icon: const Icon(Icons.dns),
              label: const Text('测试域名解析'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onTestHttpClient,
              icon: const Icon(Icons.http),
              label: const Text('测试 HttpClient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onTestDio,
              icon: const Icon(Icons.api),
              label: const Text('测试 Dio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '高级功能测试',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
                          ElevatedButton.icon(
                onPressed: isInitialized ? onTestAdvancedFeatures : null,
                icon: const Icon(Icons.settings),
                label: const Text('测试高级功能'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInitialized ? Colors.deepPurple : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isInitialized ? onTestPerformance : null,
              icon: const Icon(Icons.speed),
              label: const Text('测试性能'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isInitialized ? Colors.amber : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isInitialized ? onTestErrorHandling : null,
              icon: const Icon(Icons.error_outline),
              label: const Text('测试错误处理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isInitialized ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
              ),
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                result,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '日志信息',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onClearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('清空日志'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  logMessages.isEmpty ? '暂无日志信息' : logMessages,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
