import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/user.dart';
import '../../features/care_team/data/services/care_team_api_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Reschedules local medication notifications from API state (patient or caregiver).
///
/// Logout calls [NotificationService.cancelAllReminders]; this service restores
/// future alarms after login or when screens load fresh reminder data.
class ReminderNotificationSync {
  ReminderNotificationSync._();

  /// After auth: fetch from API and rebuild all local reminder alarms for this role.
  static Future<void> syncAfterAuth(AuthService auth, User user) async {
    try {
      await NotificationService().initialize();
      if (user.isCaregiver) {
        await _syncCaregiverFromServer(auth);
      } else {
        await _syncPatientFromServer(auth);
      }
    } catch (e, st) {
      debugPrint('ReminderNotificationSync.syncAfterAuth failed: $e\n$st');
    }
  }

  /// Patient reminders screen: rebuild locals from already-fetched rows (no extra GET).
  static Future<void> syncPatientFromMapped(List<Map<String, dynamic>> mapped) async {
    try {
      await NotificationService().initialize();
      await NotificationService().cancelAllReminders();
      final now = DateTime.now();
      final svc = NotificationService();
      for (final r in mapped) {
        await _scheduleOnePatientRow(svc, r, now);
      }
    } catch (e, st) {
      debugPrint('ReminderNotificationSync.syncPatientFromMapped failed: $e\n$st');
    }
  }

  /// Caregiver home: rebuild locals from merged patient reminder rows.
  static Future<void> syncCaregiverFromMergedList(
      List<Map<String, dynamic>> merged) async {
    try {
      await NotificationService().initialize();
      await NotificationService().cancelAllReminders();
      final now = DateTime.now();
      final svc = NotificationService();
      for (final r in merged) {
        final scheduledTime =
            DateTime.tryParse(r['scheduled_time']?.toString() ?? '')?.toLocal();
        if (scheduledTime == null || scheduledTime.isBefore(now)) continue;

        final reminderId = r['id']?.toString() ?? '';
        if (reminderId.isEmpty) continue;

        final st =
            (r['display_status'] ?? r['status'])?.toString().toLowerCase() ?? '';
        if (st == 'completed' || st == 'skipped' || st == 'missed') continue;

        final patientName =
            (r['_patient_name'] as String?)?.trim() ?? 'Patient';
        final title = (r['title'] as String?)?.trim() ?? 'Reminder';
        final notifId = 'caregiver_$reminderId';

        try {
          await svc.scheduleFromReminderData(
            reminderId: notifId,
            medicationName: '$patientName — $title',
            dosage: '',
            scheduledTime: scheduledTime,
            notificationBody:
                '$patientName has a reminder due at ${_formatShortTime(scheduledTime)}',
          );
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint(
          'ReminderNotificationSync.syncCaregiverFromMergedList failed: $e\n$st');
    }
  }

  static String _formatShortTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:$m $ap';
  }

  static Future<void> _syncPatientFromServer(AuthService auth) async {
    final token = await auth.getAccessToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/api/reminders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) return;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final merged = <dynamic>[
      ...(data['today'] as List<dynamic>? ?? []),
      ...(data['upcoming'] as List<dynamic>? ?? []),
      ...(data['past'] as List<dynamic>? ?? []),
    ];
    final mapped = merged.whereType<Map<String, dynamic>>().map((r) {
      return {
        'id': r['id']?.toString() ?? '',
        'title': r['title']?.toString() ?? 'Reminder',
        'description': r['message']?.toString() ?? '',
        'scheduledTime':
            (DateTime.tryParse(r['scheduled_time']?.toString() ?? '') ??
                    DateTime.now())
                .toLocal(),
        'status':
            (r['display_status'] ?? r['status'])?.toString() ?? 'pending',
        'type': r['reminder_type']?.toString() ?? 'task',
        'dosage': null,
        'recurrence': r['recurrence']?.toString() ?? 'once',
      };
    }).toList();

    await syncPatientFromMapped(mapped);
  }

  /// Skips only reminders clearly in the past; allows a 1-minute buffer so a
  /// row just created (or clock/API skew) is not dropped from the rebuild.
  static Future<void> _scheduleOnePatientRow(
    NotificationService svc,
    Map<String, dynamic> r,
    DateTime now,
  ) async {
    final scheduledTime = r['scheduledTime'] as DateTime?;
    final skipIfBefore = now.subtract(const Duration(minutes: 1));
    if (scheduledTime == null || scheduledTime.isBefore(skipIfBefore)) return;

    final status = r['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed' ||
        status == 'skipped' ||
        status == 'missed') {
      return;
    }

    final id = r['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final recurrence = (r['recurrence']?.toString() ?? 'once').trim();
    final isRecurring = recurrence != 'once';
    final title = r['title']?.toString() ?? 'Reminder';
    final dosage = r['dosage']?.toString() ?? '';
    final description = r['description']?.toString() ?? '';
    final dosageLine = dosage.isNotEmpty
        ? dosage
        : (description.isNotEmpty
            ? description
            : 'Take your medication as prescribed');

    try {
      await svc.scheduleFromReminderData(
        reminderId: id,
        medicationName: title,
        dosage: dosageLine,
        scheduledTime: scheduledTime,
        isRecurring: isRecurring,
        recurrencePattern: recurrence.isEmpty ? 'once' : recurrence,
        notificationBody:
            description.isNotEmpty ? description : null,
      );
    } catch (_) {}
  }

  static Future<void> _syncCaregiverFromServer(AuthService auth) async {
    final api = CareTeamApiService(authService: auth);
    List<Map<String, dynamic>> patients;
    try {
      patients = await api.getMyPatients();
    } catch (_) {
      return;
    }

    final merged = <Map<String, dynamic>>[];
    for (final p in patients) {
      final pid = p['patient_id']?.toString() ?? '';
      if (pid.isEmpty) continue;
      final pname = (p['full_name'] as String?)?.trim().isNotEmpty == true
          ? (p['full_name'] as String).trim()
          : ((p['email'] as String?)?.trim() ?? 'Patient');
      try {
        final data = await api.getPatientReminderList(pid);
        _appendBucket(data['today'], pid, pname, merged);
        _appendBucket(data['upcoming'], pid, pname, merged);
      } catch (_) {}
    }

    await syncCaregiverFromMergedList(merged);
  }

  static void _appendBucket(
    dynamic bucket,
    String patientId,
    String patientName,
    List<Map<String, dynamic>> out,
  ) {
    if (bucket is! List) return;
    for (final item in bucket) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        m['_patient_id'] = patientId;
        m['_patient_name'] = patientName;
        out.add(m);
      }
    }
  }
}
