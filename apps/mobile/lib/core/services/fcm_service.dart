import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

/// Firebase Cloud Messaging: token sync to Firestore and foreground display.
class FCMService {
  FCMService._();
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> _persistToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Registers background handler (once), requests permission, saves token to
  /// `users/{userId}` (`fcmToken`), and wires foreground / token refresh.
  Future<void> initialize(String userId) async {
    await _onMessageSub?.cancel();
    await _onTokenRefreshSub?.cancel();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _persistToken(userId, token);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final id = message.hashCode & 0x7fffffff;
      final title = message.notification?.title ?? 'Reminder';
      final body = message.notification?.body ?? '';
      final notif = NotificationService();
      await notif.initialize();
      await notif.showInstantNotification(
        notificationId: id == 0 ? 1 : id,
        title: title,
        body: body.isEmpty ? ' ' : body,
      );
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(userId, newToken);
    });
  }
}
