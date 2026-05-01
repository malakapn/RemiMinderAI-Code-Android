import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'billing_redirect_stub.dart'
    if (dart.library.io) 'billing_redirect.dart' as billing_redirect;

/// Environment configuration for MediMinder Flutter app
class Environment {
  // Track if environment has been loaded
  static bool _isLoaded = false;

  // Auth Provider Configuration
  static String get authProvider =>
      _isLoaded ? (dotenv.env['AUTH_PROVIDER'] ?? 'firebase') : 'firebase';

  // API Configuration
  static String get apiBaseUrl => _isLoaded
      ? (dotenv.env['MOBILE_API_BASE_URL'] ??
          dotenv.env['API_BASE_URL'] ??
          'http://localhost:8000')
      : 'http://localhost:8000';

  // App Environment
  static String get flutterEnv =>
      _isLoaded ? (dotenv.env['FLUTTER_ENV'] ?? 'development') : 'development';

  /// OAuth 2.0 **Web client** ID from Firebase (Project settings → Your apps → Web client,
  /// or Authentication → Sign-in method → Google). On Android this is often required so
  /// `GoogleSignIn` returns a non-null **id token** for `GoogleAuthProvider.credential`.
  static String? get googleWebClientId {
    if (!_isLoaded) return null;
    final v = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

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

  /// Load environment variables from .env file
  static Future<void> load() async {
    try {
      // Load the .env inside the mobile folder FIRST
      await dotenv.load(fileName: '.env');
      _isLoaded = true;
      return;
    } catch (e) {
      // Fallback to root .env ONLY if mobile .env missing
    }

    try {
      await dotenv.load(
          fileName: '/Users/jibinkunjumon/developments/MediMinder/.env');
      _isLoaded = true;
    } catch (e) {
      // No .env found. Running with defaults.
      _isLoaded = false;
    }
  }

  /// Validate that required environment variables are set
  static void validate() {
    // Skip validation if not loaded - we're in development mode
    if (!_isLoaded) {
      return;
    }

    final requiredVars = <String>[];

    final missing = requiredVars.where((String varName) =>
        dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty);

    if (missing.isNotEmpty) {
      // Don't throw exception in development - use defaults
      if (flutterEnv == 'production') {
        throw Exception(
            'Missing required environment variables: ${missing.join(', ')}');
      }
    }
  }
}
