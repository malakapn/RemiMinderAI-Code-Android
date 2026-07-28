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
/// Slightly longer than 8s so India / high-latency mobile networks can finish
/// Firebase init without treating a slow start as total failure.
Future<bool> bootstrapFirebase({Duration timeout = const Duration(seconds: 12)}) async {
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
