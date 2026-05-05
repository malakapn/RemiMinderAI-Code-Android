import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/environment.dart';
import 'auth_service.dart';

/// Local scheduled notifications (Android foreground/background).
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  StreamSubscription<String>? _fcmTokenRefreshSub;

  /// Initializes plugin, timezone DB, Android channel, and requests
  /// POST_NOTIFICATIONS on Android 13+.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Falls back to UTC if local timezone not found
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        const channel = AndroidNotificationChannel(
          'reminders',
          'Medication Reminders',
          description: 'Scheduled medication and care reminders.',
          importance: Importance.max,
        );
        await android.createNotificationChannel(channel);
        await android.requestNotificationsPermission();
      }
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Stable notification id derived from API reminder id (may include prefixes).
  int notificationIdFromReminderId(String reminderId) =>
      reminderId.hashCode & 0x7fffffff;

  /// Cancels the local notification tied to a reminder id string.
  Future<void> cancelFromReminderId(String reminderId) async {
    await cancelReminder(notificationIdFromReminderId(reminderId));
  }

  /// Schedules from patient/caregiver sync payloads (used by [ReminderNotificationSync]).
  Future<void> scheduleFromReminderData({
    required String reminderId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    bool isRecurring = false,
    String recurrencePattern = 'once',
    String? notificationBody,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now.subtract(const Duration(seconds: 1)))) {
      debugPrint('NotificationService: skip scheduleFromReminderData — past');
      return;
    }

    final id = notificationIdFromReminderId(reminderId);
    final body = (notificationBody != null && notificationBody.trim().isNotEmpty)
        ? notificationBody.trim()
        : (dosage.trim().isNotEmpty
            ? dosage.trim()
            : 'Take your medication as prescribed');

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Medication Reminders',
      channelDescription: 'Scheduled medication and care reminders.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final when = tz.TZDateTime.from(scheduledTime, tz.local);

    if (!isRecurring || recurrencePattern == 'once') {
      await _plugin.zonedSchedule(
        id,
        medicationName,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }

    final match = recurrencePattern.toLowerCase().contains('week')
        ? DateTimeComponents.dayOfWeekAndTime
        : DateTimeComponents.time;

    await _plugin.zonedSchedule(
      id,
      medicationName,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  }

  /// Ensures plugin is ready and Android notification permission is requested.
  Future<void> requestPermissions() async {
    await initialize();
  }

  /// Android 12+: request exact alarm permission when required for scheduled notifications.
  Future<void> requestExactAlarmPermission() async {
    await initialize();
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  /// Schedules a one-shot notification at [scheduledTime] in the device's
  /// local timezone ([tz.local]).
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();

    // Allow "immediate" schedules (e.g. FCM foreground) where [scheduledTime]
    // is effectively [DateTime.now()] and would otherwise read as past after init.
    final now = DateTime.now();
    if (scheduledTime.isBefore(now.subtract(const Duration(seconds: 1)))) {
      debugPrint('NotificationService: skip schedule — time in the past');
      return;
    }

    final when = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Medication Reminders',
      channelDescription: 'Scheduled medication and care reminders.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Shows a notification immediately (e.g. test notification from settings).
  Future<void> showInstantNotification({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminders',
      'Medication Reminders',
      channelDescription: 'Scheduled medication and care reminders.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(notificationId, title, body, details);
  }

  Future<void> cancelReminder(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _plugin.cancelAll();
  }

  /// Current FCM device token for push delivery (nullable on web/simulator/unavailable).
  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e, st) {
      debugPrint('NotificationService.getFcmToken: $e\n$st');
      return null;
    }
  }

  /// Registers a listener for rotated FCM tokens.
  ///
  /// [callback] receives the raw token string. Only one subscriber is tracked;
  /// calling again replaces the previous subscription.
  Future<void> onTokenRefresh(
      Future<void> Function(String token) callback) async {
    if (kIsWeb) return;
    await _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await callback(token);
      } catch (e, st) {
        debugPrint('NotificationService.onTokenRefresh callback: $e\n$st');
      }
    });
  }

  /// Removes this user's FCM row on the backend (call while JWT is valid).
  Future<void> unregisterBackendFcmToken() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final uri = Uri.parse('${Environment.apiBaseUrl}/api/reminders/fcm/token');
      await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort; sign-out callers continue regardless.
    }
  }

  /// Deletes local FCM installation token so the device gets a fresh one next launch.
  Future<void> clearLocalFcmRegistration() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    await _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub = null;
  }
}
