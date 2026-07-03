import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'deep_link_service.dart';
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
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> _persistToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  String? _deepLinkFromMessage(RemoteMessage message) {
    final link = message.data['deep_link']?.toString().trim();
    if (link != null && link.isNotEmpty) return link;
    return null;
  }

  void _navigateFromMessage(RemoteMessage message) {
    final link = _deepLinkFromMessage(message);
    if (link != null) {
      DeepLinkService.instance.navigate(link);
    }
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
    await _onMessageOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();

    final token = await _messaging.getToken();
    if (token != null) {
      await _persistToken(userId, token);
    }

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _navigateFromMessage(initial);
    }

    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);

    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final id = message.hashCode;
      final title = message.notification?.title ?? 'Reminder';
      final body = message.notification?.body ?? '';
      await NotificationService().scheduleReminder(
        id: id,
        title: title,
        body: body,
        scheduledTime: DateTime.now(),
        payload: _deepLinkFromMessage(message),
      );
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(userId, newToken);
    });
  }
}
