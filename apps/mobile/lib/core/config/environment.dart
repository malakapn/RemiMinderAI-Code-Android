import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for MediMinder Flutter app
class Environment {
  static bool _isLoaded = false;

  static const String _productionApiBaseUrl =
      'https://remiminder-backend-575820802106.us-central1.run.app';

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

  static String get authProvider =>
      _isLoaded ? (dotenv.env['AUTH_PROVIDER'] ?? 'firebase') : 'firebase';

  /// Backend origin for REST calls. Prefer `MOBILE_API_BASE_URL` in `.env` for real devices.
  static String get apiBaseUrl {
    final configured = _isLoaded
        ? (dotenv.env['MOBILE_API_BASE_URL'] ?? dotenv.env['API_BASE_URL'])
        : null;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    if (!_isLoaded && !isDevelopment) {
      return _productionApiBaseUrl;
    }
    return _defaultDevApiBaseUrl;
  }

  static String get flutterEnv =>
      _isLoaded ? (dotenv.env['FLUTTER_ENV'] ?? 'development') : 'development';

  /// OAuth Web client ID for Google Sign-In + Firebase (`serverClientId`).
  static String get googleWebClientId {
    String? pick(String? raw) {
      final t = raw?.trim();
      return (t != null && t.isNotEmpty) ? t : null;
    }

    if (_isLoaded) {
      final fromDotenv = pick(dotenv.env['GOOGLE_WEB_CLIENT_ID']) ??
          pick(dotenv.env['GOOGLE_CLIENT_ID']);
      if (fromDotenv != null) return fromDotenv;
    }

    const fromDefine = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine.trim();

    const fromDefineLegacy = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '',
    );
    if (fromDefineLegacy.isNotEmpty) return fromDefineLegacy.trim();

    return defaultFirebaseWebClientId;
  }

  static const String defaultFirebaseWebClientId =
      '575820802106-m8q0lu61mdgls5r354uvd93phvf7ig9a.apps.googleusercontent.com';

  static const String revenueCatGoogleApiKey =
      'goog_LVocUzGmkyXFyUUUUoRndvEWKli';
  static const String revenueCatAppleApiKey = '';
  static const String revenueCatAndroidPackageName = 'com.remiminderai.app';
  static const String revenueCatCustomUrlScheme = 'rc-e42394e597';
  /// RevenueCat entitlement + product IDs (override via `.env`; no store prices in code).
  static String get revenueCatPremiumEntitlement {
    final fromEnv = _isLoaded
        ? dotenv.env['REVENUECAT_PREMIUM_ENTITLEMENT']?.trim()
        : null;
    return (fromEnv != null && fromEnv.isNotEmpty) ? fromEnv : 'premium';
  }

  static String get revenueCatMonthlyProductId {
    final fromEnv = _isLoaded
        ? dotenv.env['REVENUECAT_MONTHLY_PRODUCT_ID']?.trim()
        : null;
    return (fromEnv != null && fromEnv.isNotEmpty)
        ? fromEnv
        : 'remi_premium_monthly';
  }

  static String get revenueCatAnnualProductId {
    final fromEnv = _isLoaded
        ? dotenv.env['REVENUECAT_ANNUAL_PRODUCT_ID']?.trim()
        : null;
    return (fromEnv != null && fromEnv.isNotEmpty)
        ? fromEnv
        : 'remi_premium_annual';
  }

  static bool get isProduction => flutterEnv == 'production';
  static bool get isStaging => flutterEnv == 'staging';
  static bool get isDevelopment => flutterEnv == 'development';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
    } catch (e, st) {
      debugPrint('Environment.load: could not load .env ($e)');
      debugPrint('$st');
      _isLoaded = false;
    }
  }

  static void validate() {
    if (!_isLoaded) return;

    final requiredVars = isProduction ? <String>['MOBILE_API_BASE_URL'] : <String>[];
    final missing = requiredVars.where((String varName) =>
        dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty);

    if (missing.isNotEmpty && flutterEnv == 'production') {
      throw Exception(
          'Missing required environment variables: ${missing.join(', ')}');
    }

    final usingLocalhost = apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1');
    if ((isProduction || isStaging) && usingLocalhost) {
      throw Exception(
          'Invalid API base URL for $flutterEnv: $apiBaseUrl. Use a non-local backend URL.');
    }
  }
}
