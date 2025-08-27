import 'dart:io';
import 'process_utils.dart';
import 'logger.dart';

/// 端口占用信息
class PortInfo {
  final int port;
  final int? pid;
  final String? processName;
  final String? command;
  final bool isOwnProcess;

  PortInfo({
    required this.port,
    this.pid,
    this.processName,
    this.command,
    required this.isOwnProcess,
  });

  @override
  String toString() {
    if (pid == null) {
      return 'Port $port is not in use';
    }
    return 'Port $port is used by PID $pid ($processName) - ${isOwnProcess ? "Own process" : "Other process"}';
  }
}

/// 端口相关的工具类
class PortUtils {
  /// 检查端口是否可用
  static Future<bool> isPortAvailable(int port) async {
    try {
      final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取端口占用详细信息
  static Future<PortInfo> getPortInfo(int port) async {
    try {
      // 首先尝试绑定端口来检查是否可用
      final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await socket.close();
      return PortInfo(port: port, isOwnProcess: false);
    } catch (e) {
      // 端口被占用，尝试获取占用信息
      return await _getPortUsageInfo(port);
    }
  }

  /// 获取端口使用信息
  static Future<PortInfo> _getPortUsageInfo(int port) async {
    try {
      // 只支持iOS和Android平台
      if (!Platform.isIOS && !Platform.isAndroid) {
        Logger.warning('Port usage info not supported on this platform');
        return PortInfo(port: port, isOwnProcess: false);
      }

      // 在移动平台上，我们主要依赖Dart的端口绑定测试
      // 因为无法直接访问系统命令
      final currentPid = ProcessUtils.getCurrentPid();
      
      // 尝试绑定端口来检查是否被占用
      try {
        final socket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await socket.close();
        return PortInfo(port: port, isOwnProcess: false);
      } catch (e) {
        // 端口被占用，假设是自己的进程（在移动平台上这是最常见的情况）
        return PortInfo(
          port: port,
          pid: currentPid,
          processName: 'Flutter App',
          command: null,
          isOwnProcess: true,
        );
      }
    } catch (e) {
      Logger.warning('Failed to get port usage info: $e');
      return PortInfo(port: port, isOwnProcess: false);
    }
  }

  /// 检查端口是否被自己的应用占用
  static Future<bool> isPortUsedByOwnApp(int port) async {
    try {
      final portInfo = await getPortInfo(port);
      return portInfo.isOwnProcess;
    } catch (e) {
      return false;
    }
  }

  /// 查找可用端口
  static Future<int> findAvailablePort({
    int startPort = 4041,
    int endPort = 4141,
    int maxAttempts = 100,
  }) async {
    // 首先在指定范围内寻找
    for (int port = startPort; port <= endPort && port <= startPort + maxAttempts; port++) {
      if (await isPortAvailable(port)) {
        return port;
      }
    }
    
    // 如果指定范围内没有可用端口，向上突破范围寻找
    Logger.warning('No available ports in range $startPort-$endPort, expanding search upward');
    for (int port = endPort + 1; port <= endPort + maxAttempts; port++) {
      if (await isPortAvailable(port)) {
        Logger.info('Found available port $port outside configured range');
        return port;
      }
    }
    
    // 如果向上突破也没有，向下突破范围寻找
    Logger.warning('No available ports above $endPort, expanding search downward');
    for (int port = startPort - 1; port >= startPort - maxAttempts; port--) {
      if (port > 0 && await isPortAvailable(port)) {
        Logger.info('Found available port $port outside configured range');
        return port;
      }
    }
    
    throw Exception('No available ports found in range $startPort-$endPort or nearby ranges');
  }

  /// 检查端口范围是否有效
  static bool isValidPortRange(int startPort, int endPort) {
    return startPort > 0 && endPort > 0 && endPort > startPort && endPort <= 65535;
  }

  /// 验证端口号是否有效
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }

  /// 等待端口完全释放
  static Future<bool> waitForPortRelease(int port, {Duration maxWaitTime = const Duration(seconds: 5)}) async {
    const checkInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxWaitTime) {
      if (await isPortAvailable(port)) {
        Logger.debug('Port $port released successfully');
        return true;
      }
      await Future.delayed(checkInterval);
    }
    
    Logger.warning('Port $port may not be fully released after ${maxWaitTime.inSeconds} seconds');
    return false;
  }

  /// 强制释放端口
  static Future<bool> forceReleasePort(int port) async {
    try {
      Logger.info('Attempting to force release port $port');
      
      // 只支持iOS和Android平台
      if (!Platform.isIOS && !Platform.isAndroid) {
        Logger.warning('Force port release not supported on this platform');
        return false;
      }
      
      // 在移动平台上，我们主要依赖Dart的端口绑定测试
      // 因为无法直接访问系统命令来强制释放端口
      
      // 等待一段时间让端口自然释放
      await Future.delayed(Duration(milliseconds: 1000));
      
      // 验证端口是否已释放
      if (await isPortAvailable(port)) {
        Logger.info('Port $port released successfully');
        return true;
      }
      
      Logger.warning('Failed to force release port $port');
      return false;
    } catch (e) {
      Logger.error('Error forcing port release for port $port', e);
      return false;
    }
  }

  /// 清理残留端口
  static Future<List<int>> cleanupStalePorts(List<int> portsToCheck) async {
    final cleanedPorts = <int>[];
    
    try {
      Logger.info('Cleaning up stale ports: $portsToCheck');
      
      for (final port in portsToCheck) {
        try {
          final portInfo = await getPortInfo(port);
          if (portInfo.pid != null && portInfo.isOwnProcess) {
            Logger.info('Found stale port $port owned by current process, attempting cleanup');
            
            // 尝试强制释放端口
            final released = await forceReleasePort(port);
            if (released) {
              cleanedPorts.add(port);
            }
          }
        } catch (e) {
          Logger.debug('Error checking port $port: $e');
        }
      }
      
      if (cleanedPorts.isNotEmpty) {
        Logger.info('Cleaned up ${cleanedPorts.length} stale ports: $cleanedPorts');
      } else {
        Logger.info('No stale ports found to clean up');
      }
    } catch (e) {
      Logger.error('Error during port cleanup', e);
    }
    
    return cleanedPorts;
  }

  /// 清理常见的代理端口
  static Future<List<int>> cleanupCommonProxyPorts() async {
    const commonPorts = [4041, 4042, 4043, 4044, 4045, 8080, 8081, 8082];
    return await cleanupStalePorts(commonPorts);
  }

  /// 验证端口是否真正可用（包括绑定测试）
  static Future<bool> isPortTrulyAvailable(int port) async {
    // 基本可用性检查
    if (!await isPortAvailable(port)) {
      Logger.debug('Port $port is not available (system check failed)');
      return false;
    }
    
    // 额外检查：确保端口确实可以被绑定
    try {
      final testSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await testSocket.close();
      Logger.debug('Port $port is truly available');
      return true;
    } catch (e) {
      Logger.debug('Port $port binding test failed: $e');
      return false;
    }
  }
}
