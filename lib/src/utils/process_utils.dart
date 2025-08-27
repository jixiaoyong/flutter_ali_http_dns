import 'dart:io';
import 'logger.dart';

/// 进程相关的工具类
class ProcessUtils {
  static int? _currentPid;

  /// 获取当前进程ID
  static int getCurrentPid() {
    if (_currentPid != null) {
      return _currentPid!;
    }

    try {
      // 只支持iOS和Android平台
      if (Platform.isIOS || Platform.isAndroid) {
        // 在移动平台上，我们使用一个简单的计数器作为进程ID
        // 因为无法直接获取真实的进程ID
        _currentPid = DateTime.now().millisecondsSinceEpoch % 100000;
        Logger.debug('Using generated PID for mobile platform: $_currentPid');
      }
      // 在桌面平台上使用系统命令
      else if (Platform.isMacOS || Platform.isLinux) {
        final result = Process.runSync('sh', ['-c', 'echo \$\$']);
        _currentPid = int.tryParse(result.stdout.toString().trim()) ?? 0;
      }
      // 在 Windows 上使用 %PID%
      else if (Platform.isWindows) {
        final result = Process.runSync('cmd', ['/c', 'echo %PID%']);
        _currentPid = int.tryParse(result.stdout.toString().trim()) ?? 0;
      } else {
        _currentPid = 0;
      }
      return _currentPid!;
    } catch (e) {
      Logger.warning('Failed to get current PID: $e');
      _currentPid = 0;
      return 0;
    }
  }

  /// 获取进程名称
  static String? getProcessName(int pid) {
    try {
      // 只支持iOS和Android平台
      if (Platform.isIOS || Platform.isAndroid) {
        // 在移动平台上，返回固定的进程名称
        return 'Flutter App';
      }
      // 在桌面平台上使用系统命令
      else if (Platform.isMacOS || Platform.isLinux) {
        final psResult = Process.runSync('ps', ['-p', '$pid', '-o', 'comm=']);
        return psResult.stdout.toString().trim();
      } else if (Platform.isWindows) {
        final tasklistResult = Process.runSync('tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV']);
        final lines = tasklistResult.stdout.toString().split('\n');
        if (lines.isNotEmpty) {
          final parts = lines[1].split(',');
          if (parts.length > 0) {
            return parts[0].replaceAll('"', '');
          }
        }
      }
      return null;
    } catch (e) {
      Logger.warning('Failed to get process name: $e');
      return null;
    }
  }

  /// 检查进程是否存在
  static bool isProcessRunning(int pid) {
    try {
      // 只支持iOS和Android平台
      if (Platform.isIOS || Platform.isAndroid) {
        // 在移动平台上，假设进程总是运行（因为这是当前应用）
        return true;
      }
      // 在桌面平台上使用系统命令
      else if (Platform.isMacOS || Platform.isLinux) {
        final result = Process.runSync('ps', ['-p', '$pid']);
        return result.exitCode == 0;
      } else if (Platform.isWindows) {
        final result = Process.runSync('tasklist', ['/FI', 'PID eq $pid']);
        return result.exitCode == 0 && result.stdout.toString().contains('$pid');
      }
      return false;
    } catch (e) {
      Logger.warning('Failed to check if process is running: $e');
      return false;
    }
  }
}
