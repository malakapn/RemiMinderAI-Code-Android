import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Returns true when Firebase Core is ready for auth, Firestore, and FCM.
Future<bool> bootstrapFirebase({Duration timeout = const Duration(seconds: 8)}) async {
  if (Firebase.apps.isNotEmpty) return true;

  try {
    await Firebase.initializeApp().timeout(timeout);
    final ready = Firebase.apps.isNotEmpty;
    if (ready) {
      debugPrint('Firebase initialized');
    }
    return ready;
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e');
    if (kDebugMode) debugPrint('$st');
    return false;
  }
}

void registerFirebaseBackgroundMessaging() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> bootstrapNotifications() async {
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
}
