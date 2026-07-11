import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../config/environment.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _fcm;
  FirebaseMessaging get _firebaseMessaging {
    _fcm ??= FirebaseMessaging.instance;
    return _fcm!;
  }

  bool _isInitialized = false;
  AuthService? _authService;
  AuthService get _auth => _authService ??= AuthService();
  void Function(String route)? _navigationHandler;
  String? _pendingNavigationRoute;

  /// New id so Android recreates the channel with sound + max importance (channel
  /// settings are fixed after first creation on the device).
  static const String _channelId = 'medication_reminders_v2';
  static const String _channelName = 'Medication Reminders';
  static const String _channelDescription =
      'Notifications for medication reminders';

  /// Default tone for scheduled / foreground alerts (iOS).
  static const DarwinNotificationDetails _darwinReminderDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentList: true,
    presentSound: true,
    sound: 'default',
    interruptionLevel: InterruptionLevel.active,
  );

  /// High-priority medication channel: heads-up, sound, vibration; stays in shade until dismissed.
  AndroidNotificationDetails _medicationAndroidDetails({
    required String body,
    List<AndroidNotificationAction>? actions,
    bool ongoing = true,
  }) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      ticker: 'Medication Reminder',
      styleInformation: BigTextStyleInformation(body),
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      onlyAlertOnce: false,
      ongoing: ongoing,
      autoCancel: !ongoing,
      actions: actions ??
          const <AndroidNotificationAction>[
            AndroidNotificationAction('take', 'Take Now'),
            AndroidNotificationAction('snooze', 'Snooze 10 min'),
          ],
    );
  }

  NotificationDetails _instantMedicationDetails(String body) {
    return NotificationDetails(
      android: _medicationAndroidDetails(body: body, ongoing: false),
      iOS: _darwinReminderDetails,
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
      }
    }

    // FCM requires Firebase; local notifications work without it.
    if (Firebase.apps.isNotEmpty) {
      await _setupRemoteMessageInteractions();
    } else {
      debugPrint(
          'Skipping FCM setup — Firebase not initialized yet (local notifications only)');
    }

    // Permission dialogs must run while the activity is visible; requesting
    // during cold start (TOP_SLEEPING) is blocked on Android 12+ and leaves
    // the app on a black screen / returns to the launcher.
    _isInitialized = true;
  }

  /// Call after the first frame is on screen (e.g. from [RemiMinderApp]).
  Future<void> ensureRuntimePermissions() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      await requestPermissions();
      await requestExactAlarmPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    try {
      var timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName == 'Etc/UTC') {
        timeZoneName = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  void setNavigationHandler(void Function(String route) handler) {
    _navigationHandler = handler;
    final pending = _pendingNavigationRoute;
    if (pending != null) {
      _pendingNavigationRoute = null;
      handler(pending);
    }
  }

  void _navigateTo(String route) {
    final path = route.startsWith('/') ? route : '/patient/reminder/$route';
    final handler = _navigationHandler;
    if (handler != null) {
      handler(path);
    } else {
      _pendingNavigationRoute = path;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
        'Notification response: ${response.actionId} - ${response.payload}');
    unawaited(_handleNotificationAction(response.actionId, response.payload));
  }

  Future<void> _handleNotificationAction(
      String? actionId, String? payload) async {
    if (payload == null) return;

    switch (actionId) {
      case 'take':
        await _markMedicationTaken(payload);
        break;
      case 'snooze':
        await _snoozeMedication(payload);
        break;
      default:
        _openMedicationDetail(payload);
    }
  }

  Future<void> _markMedicationTaken(String reminderId) async {
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return;

      await http.post(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/reminders/$reminderId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('Failed to mark medication taken: $e');
    }

    // Dismiss the persistent notification now that the action is confirmed
    await cancelFromReminderId(reminderId);

    _openMedicationDetail(reminderId);
  }

  Future<void> _snoozeMedication(String reminderId) async {
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$reminderId/snooze'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('Failed to snooze medication: $e');
    }

    // Cancel original notification and reschedule for 10 minutes later
    await cancelFromReminderId(reminderId);
    await snoozeFromReminderId(reminderId);
  }

  void _openMedicationDetail(String reminderIdOrRoute) {
    _navigateTo(reminderIdOrRoute);
  }

  void _handleRemoteOpen(RemoteMessage message) {
    final deep = message.data['deep_link'];
    if (deep is String && deep.isNotEmpty) {
      _navigateTo(deep);
      return;
    }
    final reminderId =
        message.data['reminder_id'] ?? message.data['medication_id'];
    if (reminderId is String && reminderId.isNotEmpty) {
      _openMedicationDetail(reminderId);
    }
  }

  Future<void> _setupRemoteMessageInteractions() async {
    if (Firebase.apps.isEmpty) return;

    // Foreground FCM: show a local notification when app is open
    FirebaseMessaging.onMessage.listen(_handleForegroundFcm);

    // User tapped a notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteOpen);

    // App launched from a terminated state via notification tap
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteOpen(initialMessage);
    }
  }

  Future<void> _handleForegroundFcm(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'RemiMinder';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (body.isEmpty) return;

    // Prefer reminder_id so FCM + local scheduled alerts collapse to one slot.
    final rid = message.data['reminder_id'];
    final notifId = rid is String && rid.isNotEmpty
        ? rid.hashCode
        : (message.messageId ?? DateTime.now().toIso8601String()).hashCode;

    final details = NotificationDetails(
      android: _medicationAndroidDetails(
        body: body,
        actions: const [],
        ongoing: false,
      ),
      iOS: _darwinReminderDetails,
    );

    await _notifications.show(notifId, title, body, details,
        payload: message.data['deep_link'] ?? message.data['reminder_id'] ?? '');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final result = await android.requestExactAlarmsPermission();
        return result ?? false;
      }
    }
    return false;
  }

  Future<void> scheduleMedicationReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String medicationId,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: _medicationAndroidDetails(
        body: body,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction('take', 'Take Now'),
          AndroidNotificationAction('snooze', 'Snooze 10 min'),
        ],
      ),
      iOS: _darwinReminderDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? medicationId,
      );
    } catch (e) {
      // Some release/device combinations still reject exact alarms despite
      // permission app-op toggles. Fallback to inexact to avoid losing reminders.
      debugPrint(
          'Exact schedule failed for id=$notificationId, retrying inexact: $e');
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? medicationId,
      );
    }
  }

  Future<void> scheduleRecurringReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime firstReminderTime,
    required String medicationId,
    required String recurrencePattern,
  }) async {
    DateTimeComponents? matchTime;

    switch (recurrencePattern) {
      case 'daily':
        matchTime = DateTimeComponents.time;
        break;
      case 'weekly':
        matchTime = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'monthly':
        matchTime = DateTimeComponents.dayOfMonthAndTime;
        break;
      default:
        matchTime = DateTimeComponents.time;
    }

    final details = NotificationDetails(
      android: _medicationAndroidDetails(body: body),
      iOS: _darwinReminderDetails,
    );

    final timezone = tz.TZDateTime.from(firstReminderTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        timezone,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchTime,
        payload: medicationId,
      );
    } catch (e) {
      debugPrint(
          'Exact recurring schedule failed for id=$notificationId, retrying inexact: $e');
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        timezone,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchTime,
        payload: medicationId,
      );
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      notificationId,
      title,
      body,
      _instantMedicationDetails(body),
      payload: payload,
    );
  }

  String? _fcmToken;

  Future<String?> getFcmToken() async {
    if (_fcmToken != null) return _fcmToken;
    if (Firebase.apps.isEmpty) return null;

    try {
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _fcmToken = await _firebaseMessaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> onTokenRefresh(
      FutureOr<void> Function(String token) handler) async {
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      await handler(token);
    });
  }

  /// Remove this device's token from the backend while the user is still signed in.
  Future<void> unregisterBackendFcmToken() async {
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return;
      await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/api/fcm/token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('Error unregistering backend FCM token: $e');
    }
  }

  /// Invalidate the FCM installation on this device (call after Firebase sign-out).
  Future<void> clearLocalFcmRegistration() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
    } catch (e) {
      debugPrint('Error clearing local FCM registration: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  void setForegroundNotificationHandler(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void setBackgroundMessageHandler(
    Future<void> Function(RemoteMessage message) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  // ============================================================
  // REMINDER INTEGRATION
  // ============================================================

  /// Notification copy keyed on API `reminder_type` (`medication` / `task` / `appointment`).
  static ({String title, String body}) _notificationCopyForReminder({
    required String reminderType,
    required String reminderTitle,
    String? appointmentDetail,
    String? dosage,
    String? notificationBody,
  }) {
    switch (reminderType.toLowerCase()) {
      case 'task':
        return (title: "Let's $reminderTitle", body: '');
      case 'appointment':
        final detail = (appointmentDetail ?? '').trim();
        return (
          title: '🗓️ Time for your appointment',
          body: detail,
        );
      case 'medication':
      default:
        final body = (notificationBody != null &&
                notificationBody.trim().isNotEmpty)
            ? notificationBody.trim()
            : (dosage != null && dosage.trim().isNotEmpty
                ? dosage.trim()
                : 'Take your medication as prescribed');
        return (title: "💊 It's time for your medication", body: body);
    }
  }

  Future<void> scheduleFromReminderData({
    required String reminderId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    required String reminderType,
    bool isRecurring = false,
    String recurrencePattern = 'once',
    String? notificationBody,
  }) async {
    if (!_isInitialized) await initialize();

    late final String title;
    late final String body;
    if (reminderId.startsWith('caregiver_')) {
      title = medicationName;
      body = notificationBody?.trim() ?? '';
    } else {
      final copy = _notificationCopyForReminder(
        reminderType: reminderType,
        reminderTitle: medicationName,
        appointmentDetail: notificationBody ?? dosage,
        dosage: dosage,
        notificationBody: notificationBody,
      );
      title = copy.title;
      body = copy.body;
    }

    final notificationId = _stableNotificationId(reminderId);
    await _notifications.cancel(notificationId);

    if (isRecurring) {
      await scheduleRecurringReminder(
        notificationId: notificationId,
        title: title,
        body: body,
        firstReminderTime: scheduledTime,
        medicationId: reminderId,
        recurrencePattern: recurrencePattern,
      );
    } else {
      await scheduleMedicationReminder(
        notificationId: notificationId,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        medicationId: reminderId,
      );
    }
  }

  Future<void> cancelFromReminderId(String reminderId) async {
    final notificationId = _stableNotificationId(reminderId);
    await cancelReminder(notificationId);
  }

  Future<void> snoozeFromReminderId(String reminderId,
      {int minutes = 10}) async {
    final notificationId = _stableNotificationId(reminderId);
    final newScheduledTime = DateTime.now().add(Duration(minutes: minutes));
    final title = '💊 Snoozed: Take your medication';
    final body = 'Time extended by $minutes minutes';

    await scheduleMedicationReminder(
      notificationId: notificationId + 1000000, // Different ID for snooze
      title: title,
      body: body,
      scheduledTime: newScheduledTime,
      medicationId: reminderId,
    );
  }

  int _stableNotificationId(String reminderId) {
    // Keep ID in signed 31-bit range for platform compatibility in release.
    var hash = 0;
    for (final codeUnit in reminderId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    // Avoid zero to keep IDs distinct from default/no-id assumptions.
    return hash == 0 ? 1 : hash;
  }
}
