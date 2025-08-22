import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志工具类
class Logger {
  static LogLevel _level = LogLevel.debug;
  static bool _enabled = kDebugMode;

  /// 设置日志级别
  static void setLevel(LogLevel level) {
    _level = level;
  }

  /// 启用或禁用日志
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// 检查是否应该打印指定级别的日志
  static bool _shouldLog(LogLevel level) {
    // 在release模式下禁用所有日志
    if (!kDebugMode) {
      return false;
    }
    return _enabled && level.index >= _level.index;
  }

  /// 获取日志级别名称
  static String _getLevelName(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  /// 打印调试日志
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.debug)) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  /// 打印信息日志
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.info)) {
      _log(LogLevel.info, message, error, stackTrace);
    }
  }

  /// 打印警告日志
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.warning)) {
      _log(LogLevel.warning, message, error, stackTrace);
    }
  }

  /// 打印错误日志
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.error)) {
      _log(LogLevel.error, message, error, stackTrace);
    }
  }

  /// 内部日志打印方法
  static void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelName = _getLevelName(level);
    final prefix = '[flutter_ali_http_dns] [$timestamp] [$levelName]';
    
    print('$prefix $message');
    
    if (error != null) {
      print('$prefix Error: $error');
    }
    
    if (stackTrace != null) {
      print('$prefix StackTrace: $stackTrace');
    }
  }
}
