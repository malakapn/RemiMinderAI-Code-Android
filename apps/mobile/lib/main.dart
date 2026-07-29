import "core/services/revenuecat_service.dart";
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

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await Environment.load();
  Environment.validate(); // Ensure required vars are set
  debugPrint('📡 API base URL: ${Environment.apiBaseUrl}');

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Log error but continue - app can still show welcome screen
    // This prevents app crash on Firebase init failure
    debugPrint('Firebase initialization failed: $e');
  }

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }

  try {
    await RevenueCatService().initialize();
  } catch (e) {
    debugPrint("RevenueCat initialization failed: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: RemiMinderApp(),
    ),
  );
}
