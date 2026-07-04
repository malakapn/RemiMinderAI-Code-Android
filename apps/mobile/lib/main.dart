import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/environment.dart';
import 'core/config/firebase_bootstrap.dart';

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.load();
  try {
    Environment.validate();
  } catch (e) {
    // Misconfigured .env must not hard-crash the shell; auth/API may fail later.
    debugPrint('Environment.validate: $e');
  }
  debugPrint('📡 API base URL: ${Environment.apiBaseUrl}');

  // Initialize Firebase before registering FCM background handlers — registering
  // first with a bad/missing google-services.json crashes natively on Samsung.
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
    const ProviderScope(
      child: RemiMinderApp(),
    ),
  );

  if (firebaseReady) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(bootstrapNotifications());
    });
  }
}
