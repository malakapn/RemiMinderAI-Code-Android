import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/environment.dart';
import 'core/services/notification_service.dart';

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await Environment.load();
  Environment.validate();

  // Initialize Firebase
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    // Preloads reCAPTCHA Enterprise config so email/password on Android is less
    // likely to fail on first attempt (RecaptchaCallWrapper / network).
    try {
      await FirebaseAuth.instance.initializeRecaptchaConfig();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirebaseAuth.initializeRecaptchaConfig (non-fatal): $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: RemiMinderApp(),
    ),
  );
}
