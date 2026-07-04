import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/environment.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/config/supported_languages.dart';
import 'core/providers/locale_provider.dart';

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.load();
  try {
    Environment.validate();
  } catch (e) {
    debugPrint('Environment.validate: $e');
  }
  debugPrint('📡 API base URL: ${Environment.apiBaseUrl}');

  final prefs = await SharedPreferences.getInstance();
  final initialLocale = Locale(
    normalizeLanguageCode(prefs.getString(kPreferredLanguagePrefsKey) ?? 'en'),
  );

  final firebaseReady = await bootstrapFirebase();
  if (firebaseReady) {
    registerFirebaseBackgroundMessaging();
  } else {
    debugPrint(
      'Skipping FCM background handler — Firebase not ready. '
      'Check apps/mobile/android/app/google-services.json (download from Firebase Console).',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          () => LocaleNotifier(initial: initialLocale),
        ),
      ],
      child: const RemiMinderApp(),
    ),
  );

  if (firebaseReady) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(bootstrapNotifications());
    });
  }
}
