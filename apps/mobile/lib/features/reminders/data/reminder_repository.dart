// =============================================================================
// MOBILE REMINDER DATA — FIRESTORE (source of truth for this repository)
// =============================================================================
//
// Collection path: `users/{firebaseUid}/reminders/{reminderId}`
//
// All reads and writes in this file go to Cloud Firestore only. Consumers:
//   - [reminderRepositoryProvider] / [ReminderRepository]
//   - [remindersStreamProvider] in presentation/providers/reminder_provider.dart
//   - [ReminderListScreen] (legacy route; not registered in app_router)
//
// Document fields (see [Reminder.toMap]): title, description, type, scheduledTime,
// status, dosage, frequency, snoozeCount, snoozeUntil, createdAt.
// Legacy Firestore fields `isCompleted` and `medicationName` are read in [Reminder.fromMap].
//
// DIVERGENCE — other mobile paths do NOT use this repository:
//   - [RemindersScreen] and [patient_home_screen] use REST `GET/POST/PUT/DELETE
//     /api/reminders` → backend Cloud SQL (`reminders` table), not Firestore.
//   - [ReminderNotificationSync] after login also reads Cloud SQL for local alarms.
//   - [LocalStorageService] can mirror `users/{uid}/reminders` via [Reminder] (unused for CRUD).
//
// Backend canonical store: Google Cloud SQL PostgreSQL (`reminders`, `reminder_logs`,
// `caregiver_alerts`). No sync exists between Firestore and Cloud SQL.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/reminder.dart';

/// Firestore-backed reminders at `users/{userId}/reminders/{reminderId}`.
class ReminderRepository {
  ReminderRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _remindersCol(String userId) {
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Live list of reminders, sorted by [scheduledTime] ascending.
  Stream<List<Reminder>> getReminders(String userId) {
    return _remindersCol(userId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Reminder.fromMap(data);
      }).toList();
      list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      return list;
    });
  }

  Future<Reminder> createReminder(String userId, Reminder reminder) async {
    try {
      final doc =
          reminder.id.isEmpty ? _remindersCol(userId).doc() : _remindersCol(userId).doc(reminder.id);
      final toWrite = reminder.id.isEmpty ? reminder.copyWith(id: doc.id) : reminder;
      await doc.set(toWrite.toFirestoreMap());
      return toWrite;
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  Future<void> completeReminder(String userId, String reminderId) async {
    try {
      await _remindersCol(userId).doc(reminderId).update({
        'status': 'completed',
        'snoozeUntil': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to complete reminder: $e');
    }
  }

  Future<void> snoozeReminder(
    String userId,
    String reminderId, {
    int minutes = 30,
  }) async {
    try {
      final until = DateTime.now().add(Duration(minutes: minutes));
      await _remindersCol(userId).doc(reminderId).update({
        'status': 'snoozed',
        'snoozeUntil': Timestamp.fromDate(until),
        'snoozeCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to snooze reminder: $e');
    }
  }

  Future<void> deleteReminder(String userId, String reminderId) async {
    try {
      await _remindersCol(userId).doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  Future<void> updateReminder(
    String userId,
    String reminderId,
    Map<String, dynamic> data,
  ) async {
    try {
      final patch = Map<String, dynamic>.from(data);
      if (patch['scheduledTime'] is DateTime) {
        patch['scheduledTime'] = Timestamp.fromDate(patch['scheduledTime'] as DateTime);
      }
      if (patch['createdAt'] is DateTime) {
        patch['createdAt'] = Timestamp.fromDate(patch['createdAt'] as DateTime);
      }
      if (patch.containsKey('snoozeUntil')) {
        final v = patch['snoozeUntil'];
        if (v is DateTime) {
          patch['snoozeUntil'] = Timestamp.fromDate(v);
        } else if (v == null) {
          patch['snoozeUntil'] = null;
        }
      }
      await _remindersCol(userId).doc(reminderId).update(patch);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});
