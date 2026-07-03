import 'package:flutter/foundation.dart';

/// Lightweight logging wrapper around [debugPrint].
class AppLogger {
  static void info(String message) {
    if (kReleaseMode) return;
    debugPrint('[INFO] $message');
  }

  static void warn(String message) {
    debugPrint('[WARN] $message');
  }

  static void error(String message) {
    debugPrint('[ERROR] $message');
  }
}
