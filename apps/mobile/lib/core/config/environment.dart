import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'billing_redirect_stub.dart'
    if (dart.library.io) 'billing_redirect.dart' as billing_redirect;

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

  /// OAuth Web client ID for Google Sign-In + Firebase (`serverClientId`).
  ///
  /// Resolution order: `apps/mobile/.env` (`GOOGLE_WEB_CLIENT_ID` / `GOOGLE_CLIENT_ID`),
  /// then `--dart-define=GOOGLE_WEB_CLIENT_ID=...`, then
  /// `--dart-define=GOOGLE_CLIENT_ID=...`, then [defaultFirebaseWebClientId] from ENV_SETUP.md.
  ///
  /// Note: Previously this returned null whenever `.env` failed to load; CI/APK builds often
  /// had no bundle → "Google Sign-In is not configured" even when Firebase was set up.
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

  /// Firebase Web client ID for this repo (public; same value as ENV_SETUP.md).
  static const String defaultFirebaseWebClientId =
      '575820802106-m8q0lu61mdgls5r354uvd93phvf7ig9a.apps.googleusercontent.com';

  /// Default app URL scheme for Stripe Checkout return URLs (mobile).
  static String get _billingUrlScheme {
    if (_isLoaded && dotenv.env['BILLING_URL_SCHEME'] != null) {
      final s = dotenv.env['BILLING_URL_SCHEME']!.trim();
      if (s.isNotEmpty) return s;
    }
    return billing_redirect.defaultBillingUrlScheme();
  }

  /// Stripe Checkout success URL; must include literal `{CHECKOUT_SESSION_ID}` for Stripe.
  static String get billingSuccessUrl {
    if (_isLoaded &&
        dotenv.env['BILLING_SUCCESS_URL'] != null &&
        dotenv.env['BILLING_SUCCESS_URL']!.trim().isNotEmpty) {
      return dotenv.env['BILLING_SUCCESS_URL']!.trim();
    }
    return '$_billingUrlScheme://billing/success?session_id={CHECKOUT_SESSION_ID}';
  }

  /// Stripe Checkout cancel URL.
  static String get billingCancelUrl {
    if (_isLoaded &&
        dotenv.env['BILLING_CANCEL_URL'] != null &&
        dotenv.env['BILLING_CANCEL_URL']!.trim().isNotEmpty) {
      return dotenv.env['BILLING_CANCEL_URL']!.trim();
    }
    return '$_billingUrlScheme://billing/cancel';
  }

  // Environment checks
  static bool get isProduction => flutterEnv == 'production';
  static bool get isStaging => flutterEnv == 'staging';
  static bool get isDevelopment => flutterEnv == 'development';

  /// Load environment variables from `.env` (must be listed under `flutter: assets:` in pubspec).
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
    } catch (e, st) {
      debugPrint('Environment.load: could not load .env ($e)');
      debugPrint('$st');
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
