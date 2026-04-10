import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    filter: _AppFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void d(String tag, String message) {
    _logger.d('[$tag] $message');
  }

  static void i(String tag, String message) {
    _logger.i('[$tag] $message');
  }

  static void w(String tag, String message) {
    _logger.w('[$tag] $message');
  }

  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.e('[$tag] $message');
    }
  }
}

class _AppFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // 在开发环境显示所有日志，在生产环境只显示警告和错误
    if (kDebugMode) {
      return true;
    }
    return event.level.index >= Level.warning.index;
  }
}
