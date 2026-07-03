import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/services/notification_service.dart';

/// Debug entry point for simulator notification smoke test.
/// Run: flutter run -t lib/debug/notification_simulator_test_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init (test harness): $e');
  }
  runApp(const _NotificationTestApp());
}

class _NotificationTestApp extends StatefulWidget {
  const _NotificationTestApp();

  @override
  State<_NotificationTestApp> createState() => _NotificationTestAppState();
}

class _NotificationTestAppState extends State<_NotificationTestApp> {
  final List<String> _log = [];
  bool _busy = false;

  void _add(String line) {
    debugPrint('[NotifTest] $line');
    setState(() => _log.insert(0, '${DateTime.now().toIso8601String()}: $line'));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTests());
  }

  Future<void> _runTests() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _add('Initializing NotificationService...');
      await NotificationService().initialize();
      _add('Initialized.');

      final pending = await FlutterLocalNotificationsPlugin().pendingNotificationRequests();
      _add('Pending notifications before test: ${pending.length}');

      _add('Firing instant notification...');
      await NotificationService().showInstantNotification(
        notificationId: 999001,
        title: 'RemiMinder test (now)',
        body: 'Instant local notification — simulator smoke test',
        payload: 'test_instant',
      );
      _add('Instant notification scheduled.');

      final in90s = DateTime.now().add(const Duration(seconds: 90));
      _add('Scheduling reminder for ${in90s.toLocal()} (90s)...');
      await NotificationService().scheduleFromReminderData(
        reminderId: 'sim_test_${DateTime.now().millisecondsSinceEpoch}',
        medicationName: 'Simulator Test Reminder',
        dosage: '',
        scheduledTime: in90s,
        reminderType: 'medication',
        notificationBody: 'Scheduled local notification — fires in 90 seconds',
      );
      _add('Scheduled notification set. Background the app and wait ~90s.');

      final pendingAfter =
          await FlutterLocalNotificationsPlugin().pendingNotificationRequests();
      _add('Pending notifications after test: ${pendingAfter.length}');
      for (final p in pendingAfter.take(5)) {
        _add('  • id=${p.id} title=${p.title}');
      }
    } catch (e, st) {
      _add('ERROR: $e');
      debugPrint('$st');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Notification Simulator Test')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _busy ? null : _runTests,
                child: Text(_busy ? 'Running...' : 'Run notification test'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '1. Tap Run\n'
                '2. Allow notifications if prompted\n'
                '3. You should see an instant banner\n'
                '4. Background the app — another in ~90s',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _log
                    .map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(l, style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
