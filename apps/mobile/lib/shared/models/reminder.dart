import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Reminder type — string [Reminder.type] uses [name] for Firestore / API compatibility.
enum ReminderType {
  medication,
  appointment,
  measurement,
  exercise,
  other,
  task;

  static ReminderType fromString(String? value) {
    if (value == null || value.isEmpty) return ReminderType.medication;
    final normalized = value.toLowerCase();
    for (final t in ReminderType.values) {
      if (t.name == normalized) return t;
    }
    return ReminderType.medication;
  }
}

/// Reminder status — string [Reminder.status] uses [name] for Firestore / API compatibility.
enum ReminderStatus {
  pending,
  completed,
  snoozed,
  skipped,
  cancelled;

  static ReminderStatus fromString(String? value) {
    if (value == null || value.isEmpty) return ReminderStatus.pending;
    final normalized = value.toLowerCase();
    for (final s in ReminderStatus.values) {
      if (s.name == normalized) return s;
    }
    return ReminderStatus.pending;
  }
}

/// Canonical reminder model (Firestore, local cache, and REST API shapes).
class Reminder extends Equatable {
  final String id;
  final String title;
  final String description;
  /// One of: `medication`, `appointment`, `measurement`, `task`, `exercise`, `other`.
  final String type;
  final DateTime scheduledTime;
  /// One of: `pending`, `completed`, `snoozed`, `skipped`, `cancelled`.
  final String status;
  final String? dosage;
  final String? frequency;
  final String? message;
  final String? userId;
  final String? visitId;
  final String? timezone;
  final String? recurrence;
  final String? medicationId;
  final String? appointmentId;
  final int snoozeCount;
  final DateTime? snoozeUntil;
  final DateTime? completedAt;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? contextData;

  const Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.scheduledTime,
    this.status = 'pending',
    this.dosage,
    this.frequency,
    this.message,
    this.userId,
    this.visitId,
    this.timezone,
    this.recurrence,
    this.medicationId,
    this.appointmentId,
    this.snoozeCount = 0,
    this.snoozeUntil,
    this.completedAt,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
    this.updatedAt,
    this.contextData,
  });

  ReminderType get typeEnum => ReminderType.fromString(type);

  ReminderStatus get statusEnum => ReminderStatus.fromString(status);

  bool get isOverdue =>
      (status == 'pending' || status == 'snoozed') &&
      scheduledTime.isBefore(DateTime.now());

  bool get isToday {
    final n = DateTime.now();
    return scheduledTime.year == n.year &&
        scheduledTime.month == n.month &&
        scheduledTime.day == n.day;
  }

  bool get isUpcoming => scheduledTime.isAfter(DateTime.now());

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: _readString(map, 'id') ?? '',
      title: _readString(map, 'title') ?? '',
      description: _readDescription(map),
      type: _readType(map),
      scheduledTime: _readDateTime(map['scheduledTime'] ??
          map['scheduled_time']) ??
          DateTime.now(),
      status: _readStatus(map),
      dosage: _readString(map, 'dosage'),
      frequency: _readString(map, 'frequency'),
      message: _readString(map, 'message'),
      userId: _readString(map, 'user_id') ?? _readString(map, 'userId'),
      visitId: _readString(map, 'visit_id') ?? _readString(map, 'visitId'),
      timezone: _readString(map, 'timezone'),
      recurrence: _readString(map, 'recurrence') ??
          _readString(map, 'recurrencePattern'),
      medicationId:
          _readString(map, 'medicationId') ?? _readString(map, 'medication_id'),
      appointmentId: _readString(map, 'appointmentId') ??
          _readString(map, 'appointment_id'),
      snoozeCount: _readInt(map, 'snoozeCount') ?? _readInt(map, 'snooze_count') ?? 0,
      snoozeUntil: _readOptionalDateTime(map['snoozeUntil'] ?? map['snooze_until']),
      completedAt:
          _readOptionalDateTime(map['completedAt'] ?? map['completed_at']),
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrencePattern: _readString(map, 'recurrencePattern'),
      createdAt: _readDateTime(map['createdAt'] ?? map['created_at']) ??
          _readDateTime(map['scheduledTime'] ?? map['scheduled_time']) ??
          DateTime.now(),
      updatedAt: _readOptionalDateTime(map['updatedAt'] ?? map['updated_at']),
      contextData: map['context_data'] as Map<String, dynamic>? ??
          map['contextData'] as Map<String, dynamic>?,
    );
  }

  /// Alias for [fromMap] (legacy call sites).
  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (message != null) 'message': message,
      if (userId != null) 'userId': userId,
      if (visitId != null) 'visitId': visitId,
      if (timezone != null) 'timezone': timezone,
      if (recurrence != null) 'recurrence': recurrence,
      if (medicationId != null) 'medicationId': medicationId,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'snoozeCount': snoozeCount,
      if (snoozeUntil != null) 'snoozeUntil': snoozeUntil!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'isRecurring': isRecurring,
      if (recurrencePattern != null) 'recurrencePattern': recurrencePattern,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (contextData != null) 'contextData': contextData,
    };
  }

  /// Alias for [toMap] (legacy call sites).
  Map<String, dynamic> toJson() => toMap();

  /// Firestore document payload (Timestamps for date fields).
  Map<String, dynamic> toFirestoreMap() {
    final map = Map<String, dynamic>.from(toMap());
    for (final key in [
      'scheduledTime',
      'snoozeUntil',
      'createdAt',
      'updatedAt',
      'completedAt',
    ]) {
      final value = map[key];
      if (value is String) {
        map[key] = Timestamp.fromDate(DateTime.parse(value));
      } else if (value is DateTime) {
        map[key] = Timestamp.fromDate(value);
      }
    }
    return map;
  }

  /// REST API body (snake_case).
  Map<String, dynamic> toApiMap() {
    return {
      'id': id,
      'user_id': userId,
      'visit_id': visitId,
      'reminder_type': type,
      'title': title,
      'message': message ?? description,
      'scheduled_time': scheduledTime.toUtc().toIso8601String(),
      if (timezone != null) 'timezone': timezone,
      if (recurrence != null) 'recurrence': recurrence,
      'status': status,
      if (completedAt != null) 'completed_at': completedAt!.toUtc().toIso8601String(),
      'snooze_count': snoozeCount,
      if (snoozeUntil != null) 'snooze_until': snoozeUntil!.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
      if (contextData != null) 'context_data': contextData,
    };
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
    String? message,
    String? userId,
    String? visitId,
    String? timezone,
    String? recurrence,
    String? medicationId,
    String? appointmentId,
    int? snoozeCount,
    DateTime? snoozeUntil,
    DateTime? completedAt,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? contextData,
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
      message: message ?? this.message,
      userId: userId ?? this.userId,
      visitId: visitId ?? this.visitId,
      timezone: timezone ?? this.timezone,
      recurrence: recurrence ?? this.recurrence,
      medicationId: medicationId ?? this.medicationId,
      appointmentId: appointmentId ?? this.appointmentId,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      completedAt: completedAt ?? this.completedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contextData: contextData ?? this.contextData,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        scheduledTime,
        status,
        dosage,
        frequency,
        message,
        userId,
        visitId,
        timezone,
        recurrence,
        medicationId,
        appointmentId,
        snoozeCount,
        snoozeUntil,
        completedAt,
        isRecurring,
        recurrencePattern,
        createdAt,
        updatedAt,
        contextData,
      ];

  static String? _readString(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    return v.toString();
  }

  static int? _readInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    return null;
  }

  static DateTime? _readOptionalDateTime(dynamic value) {
    if (value == null) return null;
    return _readDateTime(value);
  }

  static String _readDescription(Map<String, dynamic> map) {
    final d = _readString(map, 'description');
    if (d != null && d.isNotEmpty) return d;
    final msg = _readString(map, 'message');
    if (msg != null && msg.isNotEmpty) return msg;
    final legacy = _readString(map, 'medicationName');
    return legacy ?? '';
  }

  static String _readType(Map<String, dynamic> map) {
    final t = map['type'];
    if (t is int) {
      final values = ReminderType.values;
      if (t >= 0 && t < values.length) return values[t].name;
    }
    final reminderType = _readString(map, 'reminder_type');
    if (reminderType != null && reminderType.isNotEmpty) return reminderType;
    final asString = _readString(map, 'type');
    if (asString != null && asString.isNotEmpty) return asString;
    return 'medication';
  }

  static String _readStatus(Map<String, dynamic> map) {
    final s = map['status'];
    if (s is int) {
      final values = ReminderStatus.values;
      if (s >= 0 && s < values.length) return values[s].name;
    }
    final asString = _readString(map, 'status');
    if (asString != null && asString.isNotEmpty) {
      return asString.toLowerCase();
    }
    final completed = map['isCompleted'] as bool?;
    if (completed == true) return 'completed';
    return 'pending';
  }
}
