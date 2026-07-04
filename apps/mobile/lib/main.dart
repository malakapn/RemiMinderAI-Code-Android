import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'core/config/environment.dart';
import 'core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _bootstrapServices() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 20));
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
}

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Environment.load();
  Environment.validate();
  debugPrint('📡 API base URL: ${Environment.apiBaseUrl}');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: RemiMinderApp(),
    ),
  );

  // Defer heavy init until after the first frame so MainActivity stays visible.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrapServices());
  });
}
