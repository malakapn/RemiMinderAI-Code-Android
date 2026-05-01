import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reminder document at `users/{userId}/reminders/{reminderId}`.
class Reminder {
  final String id;
  final String title;
  final String description;
  /// One of: `medication`, `appointment`, `measurement`.
  final String type;
  final DateTime scheduledTime;
  /// One of: `pending`, `completed`, `snoozed`.
  final String status;
  final String? dosage;
  final String? frequency;
  final int snoozeCount;
  final DateTime? snoozeUntil;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.scheduledTime,
    required this.status,
    this.dosage,
    this.frequency,
    this.snoozeCount = 0,
    this.snoozeUntil,
    required this.createdAt,
  });

  bool get isOverdue =>
      (status == 'pending' || status == 'snoozed') &&
      scheduledTime.isBefore(DateTime.now());

  bool get isToday {
    final n = DateTime.now();
    return scheduledTime.year == n.year &&
        scheduledTime.month == n.month &&
        scheduledTime.day == n.day;
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    DateTime? scheduledTime,
    String? status,
    String? dosage,
    String? frequency,
    int? snoozeCount,
    DateTime? snoozeUntil,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    DateTime readDateTime(dynamic v) {
      if (v == null) throw FormatException('Missing datetime');
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw FormatException('Invalid datetime: $v');
    }

    DateTime? readOptionalDateTime(dynamic v) {
      if (v == null) return null;
      return readDateTime(v);
    }

    String readStatus(Map<String, dynamic> m) {
      final s = m['status'] as String?;
      if (s != null && s.isNotEmpty) return s;
      // Legacy: bool isCompleted
      final completed = m['isCompleted'] as bool?;
      if (completed == true) return 'completed';
      return 'pending';
    }

    String readDescription(Map<String, dynamic> m) {
      final d = m['description'] as String?;
      if (d != null && d.isNotEmpty) return d;
      final legacy = m['medicationName'] as String?;
      return legacy ?? '';
    }

    String readType(Map<String, dynamic> m) {
      final t = m['type'] as String?;
      if (t != null && t.isNotEmpty) return t;
      return 'medication';
    }

    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: readDescription(json),
      type: readType(json),
      scheduledTime: readDateTime(json['scheduledTime']),
      status: readStatus(json),
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      snoozeCount: (json['snoozeCount'] as num?)?.toInt() ?? 0,
      snoozeUntil: readOptionalDateTime(json['snoozeUntil']),
      createdAt: json['createdAt'] != null
          ? readDateTime(json['createdAt'])
          : readDateTime(json['scheduledTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status,
      'dosage': dosage,
      'frequency': frequency,
      'snoozeCount': snoozeCount,
      'snoozeUntil': snoozeUntil != null ? Timestamp.fromDate(snoozeUntil!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

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
        return Reminder.fromJson(data);
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
      await doc.set(toWrite.toJson());
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
