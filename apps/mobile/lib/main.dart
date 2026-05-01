import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/config/environment.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';

/// App entry point with Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await Environment.load();
  Environment.validate(); // Ensure required vars are set

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Log error but continue - app can still show welcome screen
    // This prevents app crash on Firebase init failure
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: RemiMinderApp(),
    ),
  );

  // Defer heavy native setup so the first frame (auth splash) paints sooner.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FCMService().initialize(uid);
      } catch (e) {
        debugPrint('FCMService initialization failed: $e');
      }
    }
  });
}
