import 'package:equatable/equatable.dart';

enum ReminderType {
  medication,
  appointment,
  measurement,
  exercise,
  other,
}

enum ReminderStatus {
  pending,
  completed,
  snoozed,
  cancelled,
}

class Reminder extends Equatable {
  final String id;
  final String title;
  final String description;
  final ReminderType type;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final String? medicationId;
  final String? appointmentId;
  final int snoozeCount;
  final DateTime? snoozeUntil;
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.scheduledTime,
    this.status = ReminderStatus.pending,
    this.medicationId,
    this.appointmentId,
    this.snoozeCount = 0,
    this.snoozeUntil,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    ReminderType? type,
    DateTime? scheduledTime,
    ReminderStatus? status,
    String? medicationId,
    String? appointmentId,
    int? snoozeCount,
    DateTime? snoozeUntil,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      medicationId: medicationId ?? this.medicationId,
      appointmentId: appointmentId ?? this.appointmentId,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ReminderType.values[json['type'] as int? ?? 0],
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      status: ReminderStatus.values[json['status'] as int? ?? 0],
      medicationId: json['medicationId'] as String?,
      appointmentId: json['appointmentId'] as String?,
      snoozeCount: json['snoozeCount'] as int? ?? 0,
      snoozeUntil: json['snoozeUntil'] != null
          ? DateTime.parse(json['snoozeUntil'] as String)
          : null,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status.index,
      'medicationId': medicationId,
      'appointmentId': appointmentId,
      'snoozeCount': snoozeCount,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        scheduledTime,
        status,
        medicationId,
        appointmentId,
        snoozeCount,
        snoozeUntil,
        isRecurring,
        recurrencePattern,
        createdAt,
        updatedAt,
      ];
}
