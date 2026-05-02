import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Environment configuration for MediMinder Flutter app
class Environment {
  // Track if environment has been loaded
  static bool _isLoaded = false;

  /// Default host for dev. **Physical devices:** `10.0.2.2` (Android) and `localhost`
  /// (iOS/desktop) point at the **phone**, not your PC — set `MOBILE_API_BASE_URL` in `.env`
  /// to `http://<your-computer-LAN-IP>:<port>` (e.g. Docker backend often `:8001`).
  static String get _defaultDevApiBaseUrl {
    try {
      return (!kIsWeb && Platform.isAndroid)
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000';
    } catch (_) {
      return 'http://localhost:8000';
    }
  }

  // Auth Provider Configuration
  static String get authProvider =>
      _isLoaded ? (dotenv.env['AUTH_PROVIDER'] ?? 'firebase') : 'firebase';

  /// Backend origin for REST calls. Prefer `MOBILE_API_BASE_URL` in `.env` for real devices.
  static String get apiBaseUrl {
    final configured = _isLoaded
        ? (dotenv.env['MOBILE_API_BASE_URL'] ?? dotenv.env['API_BASE_URL'])
        : null;
    final resolved = (configured != null && configured.trim().isNotEmpty)
        ? configured.trim()
        : _defaultDevApiBaseUrl;
    return resolved;
  }

  // App Environment
  static String get flutterEnv =>
      _isLoaded ? (dotenv.env['FLUTTER_ENV'] ?? 'development') : 'development';

  // Environment checks
  static bool get isProduction => flutterEnv == 'production';
  static bool get isStaging => flutterEnv == 'staging';
  static bool get isDevelopment => flutterEnv == 'development';

  /// Load environment variables from .env file
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      debugPrint('Environment file not found, using defaults: $e');
    }
  }

  /// Validate that required environment variables are set
  static void validate() {
    // Skip validation if not loaded - we're in development mode
    if (!_isLoaded) {
      return;
    }

    final requiredVars = isProduction
        ? <String>['MOBILE_API_BASE_URL']
        : <String>[];

    final missing = requiredVars.where((String varName) =>
        dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty);

    if (missing.isNotEmpty) {
      // Don't throw exception in development - use defaults
      if (flutterEnv == 'production') {
        throw Exception(
            'Missing required environment variables: ${missing.join(', ')}');
      }
    }

    final usingLocalhost = apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1');
    if ((isProduction || isStaging) && usingLocalhost) {
      throw Exception(
          'Invalid API base URL for $flutterEnv: $apiBaseUrl. Use a non-local backend URL.');
    }
  }
}
