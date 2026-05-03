import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../config/environment.dart';
import 'auth_service.dart';

/// Entry point for notification action taps while the Flutter engine runs in the background.
/// Must be top-level per flutter_local_notifications.
@pragma('vm:entry-point')
Future<void> reminderNotificationTapBackground(
    NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.load();
  await NotificationService().initialize();
  await NotificationService().handleNotificationActionSilent(
    response.actionId,
    response.payload,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _androidFullScreenIntentChannel =
      MethodChannel('com.remiminder.app.dev/full_screen_intent');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _remoteMessagingHandlersAttached = false;
  final AuthService _authService = AuthService();
  void Function(String route)? _navigationHandler;

  /// Shown locally and in alerts — privacy-safe (no PHI).
  static const String medicationReminderPrivacyTitle = '💊 Med Time!';
  static const String medicationReminderPrivacyBody =
      'Time to take your medication. Unlock app for details. 🔒';

  static const String _iosReminderCategoryId = 'reminder_med_category';

  /// New id so Android recreates the channel with sound + max importance (channel
  /// settings are fixed after first creation on the device).
  static const String _channelId = 'medication_reminders_v2';
  static const String _channelName = 'Medication Reminders';
  static const String _channelDescription =
      'Notifications for medication reminders';

  /// Default tone for scheduled / foreground alerts (iOS).
  DarwinNotificationDetails get _darwinReminderDetails =>
      DarwinNotificationDetails(
        categoryIdentifier: _iosReminderCategoryId,
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
      );

  static const List<AndroidNotificationAction> _androidMedicationActions =
      <AndroidNotificationAction>[
    AndroidNotificationAction(
      'taken',
      'Taken ✓',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      'snooze',
      'Snooze 10 min',
      showsUserInterface: false,
    ),
  ];

  /// Whether Android may use full-screen intents (API 34+: user / policy).
  ///
  /// Note: [AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications] covers **exact alarms**,
  /// not FSI. We query FSI eligibility via `NotificationManager.canUseFullScreenIntent` on the native side.
  Future<bool> _androidUseFullScreenIntentForSchedule() async {
    if (!Platform.isAndroid) return false;
    try {
      final allowed = await _androidFullScreenIntentChannel
          .invokeMethod<bool>('canUseFullScreenIntent');
      return allowed ?? false;
    } catch (e, st) {
      debugPrint('Full-screen intent capability check failed (safe fallback): $e\n$st');
      return false;
    }
  }

  Future<NotificationDetails> _scheduledMedicationNotificationDetails() async {
    final useFullScreen = await _androidUseFullScreenIntentForSchedule();
    return NotificationDetails(
      android: _medicationAndroidDetails(
        body: medicationReminderPrivacyBody,
        actions: _androidMedicationActions,
        ongoing: true,
        fullScreenIntent: useFullScreen,
      ),
      iOS: _darwinReminderDetails,
    );
  }

  /// High-priority medication channel: heads-up, alarm audio, vibration; persistent until Taken/dismissed.
  /// [fullScreenIntent] can wake the device with a full-screen UI when permitted (manifest + user settings).
  AndroidNotificationDetails _medicationAndroidDetails({
    required String body,
    List<AndroidNotificationAction>? actions,
    bool ongoing = true,
    bool fullScreenIntent = false,
  }) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      ticker: medicationReminderPrivacyTitle,
      styleInformation: BigTextStyleInformation(body),
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      onlyAlertOnce: false,
      ongoing: ongoing,
      autoCancel: !ongoing,
      fullScreenIntent: fullScreenIntent,
      actions: actions ?? _androidMedicationActions,
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
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _iosReminderCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('taken', 'Taken ✓'),
            DarwinNotificationAction.plain('snooze', 'Snooze 10 min'),
          ],
        ),
      ],
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          reminderNotificationTapBackground,
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
        debugPrint('[NotificationService] createNotificationChannel("$_channelId") invoked');
      } else {
        debugPrint('[NotificationService] WARN: Android plugin null — channel not created');
      }
    }

    await _setupRemoteMessageInteractions();

    await _ensureFcmMessagingPermission();

    // Request necessary permissions
    await requestPermissions();
    final exactAlarmGranted = await requestExactAlarmPermission();
    if (exactAlarmGranted != true) {
      debugPrint(
        '[NotificationService] WARN: exact alarm permission not granted '
        '(result=$exactAlarmGranted). Scheduled reminders may not fire at the '
        'requested time on Android 12+; open app notification / alarm settings.',
      );
    }

    _isInitialized = true;
    debugPrint('[NotificationService] initialize() done; '
        'plugin ready (timezone + Android channel "$_channelId").');
  }

  /// Logs whether the medication channel exists (Android). Call after [initialize].
  Future<void> _debugLogAndroidChannelState(String context) async {
    if (!Platform.isAndroid) {
      debugPrint('[NotificationService] [$context] channel check skipped (not Android)');
      return;
    }
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      debugPrint(
          '[NotificationService] [$context] WARN: Android platform plugin is null');
      return;
    }
    try {
      final list = await android.getNotificationChannels();
      final hasChannel = list?.any((c) => c.id == _channelId) ?? false;
      debugPrint(
          '[NotificationService] [$context] channelId=$_channelId '
          'registered=$hasChannel (total=${list?.length ?? 0})');
    } catch (e, st) {
      debugPrint(
          '[NotificationService] [$context] getNotificationChannels failed: $e\n$st');
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    print(
      '[NotificationService] timezone initialized: local=$timeZoneName '
      '(${tz.local.name})',
    );
  }

  /// Required on iOS (and helps some Android setups) before [FirebaseMessaging.getToken].
  Future<void> _ensureFcmMessagingPermission() async {
    if (kIsWeb) return;
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FirebaseMessaging.requestPermission skipped: $e');
    }
  }

  void setNavigationHandler(void Function(String route) handler) {
    _navigationHandler = handler;
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
        'Notification response: ${response.actionId} - ${response.payload}');
    unawaited(_handleNotificationAction(response.actionId, response.payload));
  }

  Future<void> _handleNotificationAction(
      String? actionId, String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;

    switch (actionId) {
      case 'taken':
      case 'take':
        await _markMedicationTaken(reminderId: payload);
        break;
      case 'snooze':
        await _snoozeMedication(payload);
        break;
      default:
        _openMedicationDetail(payload);
    }
  }

  /// Handles Taken / Snooze from a background isolate (no navigation).
  Future<void> handleNotificationActionSilent(
      String? actionId, String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;
    switch (actionId) {
      case 'taken':
      case 'take':
        await _markMedicationTaken(reminderId: payload);
        break;
      case 'snooze':
        await _snoozeMedication(payload);
        break;
      default:
        break;
    }
  }

  Future<void> _markMedicationTaken({required String reminderId}) async {
    try {
      final token = await _authService.getAccessToken();
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
  }

  Future<void> _snoozeMedication(String reminderId) async {
    try {
      final token = await _authService.getAccessToken();
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

  void _openMedicationDetail(String reminderId) {
    _navigationHandler?.call('/patient/reminder/$reminderId');
  }

  void _handleRemoteOpen(RemoteMessage message) {
    final deep = message.data['deep_link'];
    if (deep is String && deep.isNotEmpty) {
      _navigationHandler?.call(deep);
      return;
    }
    final reminderId =
        message.data['reminder_id'] ?? message.data['medication_id'];
    if (reminderId is String && reminderId.isNotEmpty) {
      _openMedicationDetail(reminderId);
    }
  }

  Future<void> _setupRemoteMessageInteractions() async {
    if (_remoteMessagingHandlersAttached) return;
    _remoteMessagingHandlersAttached = true;

    // Foreground FCM: show a local notification when app is open
    FirebaseMessaging.onMessage.listen(_handleForegroundFcm);

    // User tapped a notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteOpen);

    // App launched from a terminated state via notification tap
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteOpen(initialMessage);
    }
  }

  Future<void> _handleForegroundFcm(RemoteMessage message) async {
    // Prefer reminder_id so FCM + local scheduled alerts collapse to one slot.
    final rid = message.data['reminder_id'];
    final notifId = rid is String && rid.isNotEmpty
        ? rid.hashCode
        : (message.messageId ?? DateTime.now().toIso8601String()).hashCode;

    final payload = (message.data['deep_link'] ?? rid ?? '').toString();
    if (payload.isEmpty) return;

    final details = NotificationDetails(
      android: _medicationAndroidDetails(
        body: medicationReminderPrivacyBody,
        actions: _androidMedicationActions,
        ongoing: false,
      ),
      iOS: _darwinReminderDetails,
    );

    await _notifications.show(
      notifId,
      medicationReminderPrivacyTitle,
      medicationReminderPrivacyBody,
      details,
      payload: payload,
    );
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

  Future<bool> scheduleMedicationReminder({
    required int notificationId,
    required DateTime scheduledTime,
    required String medicationId,
    String? payload,
  }) async {
    final details = await _scheduledMedicationNotificationDetails();

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        notificationId,
        medicationReminderPrivacyTitle,
        medicationReminderPrivacyBody,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload ?? medicationId,
      );
      print(
        '[NotificationService] scheduleMedicationReminder SUCCESS '
        'notificationId=$notificationId at=$tzScheduledTime '
        'androidMode=exactAllowWhileIdle',
      );
      return true;
    } catch (e, st) {
      print('[NotificationService] scheduleMedicationReminder FAILED: $e');
      debugPrint('scheduleMedicationReminder failed: $e\n$st');
      return false;
    }
  }

  Future<bool> scheduleRecurringReminder({
    required int notificationId,
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

    final details = await _scheduledMedicationNotificationDetails();

    final timezone = tz.TZDateTime.from(firstReminderTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        notificationId,
        medicationReminderPrivacyTitle,
        medicationReminderPrivacyBody,
        timezone,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchTime,
        payload: medicationId,
      );
      print(
        '[NotificationService] scheduleRecurringReminder SUCCESS '
        'notificationId=$notificationId first=$timezone '
        'androidMode=exactAllowWhileIdle',
      );
      return true;
    } catch (e, st) {
      print('[NotificationService] scheduleRecurringReminder FAILED: $e');
      debugPrint('scheduleRecurringReminder failed: $e\n$st');
      return false;
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
    // [title] and [body] kept for API compatibility; on-screen text is always privacy-safe.
    assert(() {
      notificationId;
      title;
      body;
      return true;
    }());
    debugPrint('[NotificationService] showInstantNotification start id=$notificationId '
        'initialized=$_isInitialized');
    if (!_isInitialized) await initialize();
    await _debugLogAndroidChannelState('showInstantNotification');
    try {
      // Privacy: never show custom title/body that might contain PHI.
      await _notifications.show(
        notificationId,
        medicationReminderPrivacyTitle,
        medicationReminderPrivacyBody,
        _instantMedicationDetails(medicationReminderPrivacyBody),
        payload: payload,
      );
      print(
        '[NotificationService] showInstantNotification SUCCESS id=$notificationId',
      );
      debugPrint('[NotificationService] showInstantNotification SUCCESS id=$notificationId');
    } catch (e, st) {
      print(
        '[NotificationService] showInstantNotification FAILED id=$notificationId: $e',
      );
      debugPrint('[NotificationService] showInstantNotification FAILED id=$notificationId: '
          '$e\n$st');
    }
  }

  String? _fcmToken;

  Future<String?> getFcmToken() async {
    if (_fcmToken != null) return _fcmToken;

    try {
      await _ensureFcmMessagingPermission();
      _fcmToken = await _fcm.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> onTokenRefresh(
      FutureOr<void> Function(String token) handler) async {
    _fcm.onTokenRefresh.listen((token) async {
      await handler(token);
    });
  }

  /// Remove this device's token from the backend while the user is still signed in.
  Future<void> unregisterBackendFcmToken() async {
    try {
      final token = await _authService.getAccessToken();
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
      await _fcm.deleteToken();
      _fcmToken = null;
    } catch (e) {
      debugPrint('Error clearing local FCM registration: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
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

  Future<void> scheduleFromReminderData({
    required String reminderId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    bool isRecurring = false,
    String recurrencePattern = 'once',
    String? notificationBody,
  }) async {
    debugPrint('[NotificationService] scheduleFromReminderData start reminderId=$reminderId '
        'recurring=$isRecurring pattern=$recurrencePattern at=$scheduledTime '
        'initialized=$_isInitialized');
    if (!_isInitialized) await initialize();
    await _debugLogAndroidChannelState('scheduleFromReminderData(pre-schedule)');
    // medicationName, dosage, notificationBody intentionally ignored for on-device text (privacy).
    final notificationId = reminderId.hashCode;

    final bool ok;
    if (isRecurring) {
      ok = await scheduleRecurringReminder(
        notificationId: notificationId,
        firstReminderTime: scheduledTime,
        medicationId: reminderId,
        recurrencePattern: recurrencePattern,
      );
    } else {
      ok = await scheduleMedicationReminder(
        notificationId: notificationId,
        scheduledTime: scheduledTime,
        medicationId: reminderId,
      );
    }
    if (ok) {
      print(
        '[NotificationService] scheduleFromReminderData SUCCESS '
        'reminderId=$reminderId notificationId=$notificationId',
      );
      debugPrint('[NotificationService] scheduleFromReminderData SUCCESS '
          'reminderId=$reminderId notificationId=$notificationId');
    } else {
      print(
        '[NotificationService] scheduleFromReminderData FAILED '
        'reminderId=$reminderId notificationId=$notificationId',
      );
      debugPrint('[NotificationService] scheduleFromReminderData FAILED '
          '(zonedSchedule returned false / threw) reminderId=$reminderId '
          'notificationId=$notificationId');
    }
  }

  Future<void> cancelFromReminderId(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await cancelReminder(notificationId);
  }

  Future<void> snoozeFromReminderId(String reminderId,
      {int minutes = 10}) async {
    final notificationId = reminderId.hashCode;
    final newScheduledTime = DateTime.now().add(Duration(minutes: minutes));

    final ok = await scheduleMedicationReminder(
      notificationId: notificationId + 1000000, // Different ID for snooze
      scheduledTime: newScheduledTime,
      medicationId: reminderId,
    );
    debugPrint('[NotificationService] snoozeFromReminderId reminderId=$reminderId '
        'success=$ok at=$newScheduledTime');
  }
}
