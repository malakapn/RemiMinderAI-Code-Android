// Shared Reminder Model for MediMinder
// Used by both Flutter mobile and FastAPI backend

enum ReminderType {
  medication,
  appointment,
  task,
}

enum ReminderStatus {
  pending,
  completed,
  snoozed,
  skipped,
}

enum RecurrenceType {
  once,
  daily,
  weekly,
  monthly,
  annually,
}

class Reminder {
  final String id;
  final String userId;
  final String? visitId;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final String timezone;
  final RecurrenceType recurrence;
  final ReminderStatus status;
  final DateTime? completedAt;
  final int snoozeCount;
  final DateTime? snoozeUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? contextData;

  const Reminder({
    required this.id,
    required this.userId,
    this.visitId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.timezone,
    required this.recurrence,
    required this.status,
    this.completedAt,
    required this.snoozeCount,
    this.snoozeUntil,
    required this.createdAt,
    required this.updatedAt,
    this.contextData,
  });

  // JSON serialization
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      visitId: json['visit_id'] as String?,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['reminder_type'],
        orElse: () => ReminderType.task,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => RecurrenceType.once,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReminderStatus.pending,
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      snoozeCount:
          (json['snoozed_count'] as int?) ?? (json['snooze_count'] as int? ?? 0),
      snoozeUntil: json['snooze_until'] != null
          ? DateTime.parse(json['snooze_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contextData: json['context_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'visit_id': visitId,
      'reminder_type': type.name,
      'title': title,
      'message': message,
      'scheduled_time': scheduledTime.toIso8601String(),
      'timezone': timezone,
      'recurrence': recurrence.name,
      'status': status.name,
      'completed_at': completedAt?.toIso8601String(),
      'snoozed_count': snoozeCount,
      'snooze_until': snoozeUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'context_data': contextData,
    };
  }

  // Helper methods
  bool get isOverdue => scheduledTime.isBefore(DateTime.now()) && status == ReminderStatus.pending;
  bool get isToday => scheduledTime.day == DateTime.now().day &&
                      scheduledTime.month == DateTime.now().month &&
                      scheduledTime.year == DateTime.now().year;
  bool get isUpcoming => scheduledTime.isAfter(DateTime.now());

  Reminder copyWith({
    String? id,
    String? userId,
    String? visitId,
    ReminderType? type,
    String? title,
    String? message,
    DateTime? scheduledTime,
    String? timezone,
    RecurrenceType? recurrence,
    ReminderStatus? status,
    DateTime? completedAt,
    int? snoozeCount,
    DateTime? snoozeUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? contextData,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      visitId: visitId ?? this.visitId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timezone: timezone ?? this.timezone,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contextData: contextData ?? this.contextData,
    );
  }
}

// Request/Response models
class CreateReminderRequest {
  final String title;
  final ReminderType type;
  final DateTime scheduledTime;
  final String timezone;
  final RecurrenceType recurrence;
  final Map<String, dynamic>? contextData;

  const CreateReminderRequest({
    required this.title,
    required this.type,
    required this.scheduledTime,
    required this.timezone,
    required this.recurrence,
    this.contextData,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reminder_type': type.name,
      'scheduled_time': scheduledTime.toIso8601String(),
      'timezone': timezone,
      'recurrence': recurrence.name,
      'context_data': contextData,
    };
  }
}

class ReminderListResponse {
  final Map<String, dynamic> overview;
  final List<Reminder> today;
  final List<Reminder> upcoming;
  final List<Reminder> past;

  const ReminderListResponse({
    required this.overview,
    required this.today,
    required this.upcoming,
    required this.past,
  });

  factory ReminderListResponse.fromJson(Map<String, dynamic> json) {
    return ReminderListResponse(
      overview: json['overview'] as Map<String, dynamic>,
      today: (json['today'] as List<dynamic>?)
          ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      upcoming: (json['upcoming'] as List<dynamic>?)
          ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      past: (json['past'] as List<dynamic>?)
          ?.map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}