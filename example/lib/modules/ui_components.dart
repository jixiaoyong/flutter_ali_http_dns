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
          ],
        ),
      ),
    );
  }

  /// 构建状态行
  static Widget _buildStatusRow(
      BuildContext context, String label, String status, Color color) {
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

  /// 构建控制面板卡片
  static Widget buildControlPanelCard({
    required BuildContext context,
    required bool isInitialized,
    required bool isProxyRunning,
    required bool enableSystemDnsFallback,
    required bool enableCache,
    required bool enableSpeedTest,
    required TextEditingController hostInputController,
    required VoidCallback onInitializeDns,
    required VoidCallback onStartProxy,
    required VoidCallback onStopProxy,
    required VoidCallback onClearAllCache,
    required VoidCallback onClearHostsCache,
    required ValueChanged<bool> onSystemDnsFallbackChanged,
    required ValueChanged<bool> onCacheChanged,
    required ValueChanged<bool> onSpeedTestChanged,
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

            // DNS配置选项（仅在未初始化时显示）
            if (!isInitialized) ...[
              Text(
                'DNS 初始化配置',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Switch(
                          value: enableSpeedTest,
                          onChanged: onSpeedTestChanged,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '启用测速',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '选择最优IP',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
            ],

            // 主要控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isInitialized ? null : onInitializeDns,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('初始化 DNS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isInitialized ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 11,
                      ),
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
                      backgroundColor:
                          isProxyRunning ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 11,
                      ),
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
                      backgroundColor:
                          isProxyRunning ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 运行时配置选项
            Text(
              '运行时配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 系统DNS回退选项
            Row(
              children: [
                Switch(
                  value: enableSystemDnsFallback,
                  onChanged: onSystemDnsFallbackChanged,
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '系统DNS回退',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'HTTPDNS解析失败时回退到系统DNS',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 缓存选项
            Row(
              children: [
                Switch(
                  value: enableCache,
                  onChanged: isInitialized ? onCacheChanged : null,
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '启用缓存',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '可动态修改，无需重新初始化',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 清除缓存功能
            TextField(
              controller: hostInputController,
              decoration: const InputDecoration(
                labelText: '指定域名 (多个用逗号隔开)',
                hintText: 'e.g. www.taobao.com,www.aliyun.com',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClearHostsCache,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('清除指定缓存'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClearAllCache,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清除所有缓存'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
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
    required VoidCallback onTestSystemDnsFallback,
    required VoidCallback onTestCacheFunctionality,
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

            // 域名解析测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onTestDomainResolution,
                  icon: const Icon(Icons.dns),
                  label: const Text('测试域名解析'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '解析淘宝、抖音、百度等域名，验证DNS服务是否正常工作',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // HttpClient测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onTestHttpClient,
                  icon: const Icon(Icons.http),
                  label: const Text('测试 HttpClient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用HttpClient发送HTTPS请求，验证代理配置是否正确',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dio测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onTestDio,
                  icon: const Icon(Icons.api),
                  label: const Text('测试 Dio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用Dio HTTP客户端发送请求，测试代理集成效果',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 系统DNS回退测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onTestSystemDnsFallback,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('测试系统DNS回退'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '测试启用/禁用系统DNS回退功能，验证配置是否生效',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 缓存功能测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onTestCacheFunctionality,
                  icon: const Icon(Icons.cached),
                  label: const Text('测试缓存功能'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '测试DNS缓存功能，包括启用缓存、清除缓存等操作',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
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

            // 高级功能测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: isInitialized ? onTestAdvancedFeatures : null,
                  icon: const Icon(Icons.settings),
                  label: const Text('测试高级功能'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isInitialized ? Colors.deepPurple : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '测试端口管理、进程信息、代理配置等高级功能',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 性能测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: isInitialized ? onTestPerformance : null,
                  icon: const Icon(Icons.speed),
                  label: const Text('测试性能'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInitialized ? Colors.amber : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '测试DNS解析性能、并发处理能力和响应时间',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 错误处理测试
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: isInitialized ? onTestErrorHandling : null,
                  icon: const Icon(Icons.error_outline),
                  label: const Text('测试错误处理'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInitialized ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '测试网络异常、域名无效等错误情况的处理机制',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                ),
              ],
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
    ScrollController? scrollController,
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
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
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