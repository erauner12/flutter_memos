import 'package:flutter/foundation.dart';

/// Simple logger utility to avoid using print statements directly
class Logger {
  final String tag;
  final bool enabled;

  const Logger(this.tag, {this.enabled = true});

  void info(String message) {
    if (enabled) {
      if (kDebugMode) {
        debugPrint('[$tag] $message');
      }
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enabled) {
      if (kDebugMode) {
        debugPrint('[$tag ERROR] $message');
        if (error != null) {
          debugPrint('Error details: $error');
        }
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
  }
}
