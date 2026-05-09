import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

/// Firebase Cloud Messaging: token sync to Firestore and foreground display.
class FCMService {
  FCMService._();
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _backgroundHandlerRegistered = false;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> _persistToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Registers background handler (once), saves token to
  /// `users/{userId}` (`fcmToken`), and wires foreground / token refresh.
  /// Does not show a launch-time OS notification prompt.
  Future<void> initialize(String userId) async {
    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _backgroundHandlerRegistered = true;
    }

    await _onMessageSub?.cancel();
    await _onTokenRefreshSub?.cancel();

    final token = await _messaging.getToken();
    if (token != null) {
      await _persistToken(userId, token);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final id = message.hashCode;
      final title = message.notification?.title ?? 'Reminder';
      final body = message.notification?.body ?? '';
      await NotificationService().scheduleReminder(
        id: id,
        title: title,
        body: body,
        scheduledTime: DateTime.now(),
      );
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(userId, newToken);
    });
  }
}
