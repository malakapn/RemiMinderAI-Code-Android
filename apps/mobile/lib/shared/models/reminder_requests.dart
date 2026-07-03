import 'package:equatable/equatable.dart';

import 'reminder.dart';

class SnoozeReminderRequest extends Equatable {
  final int snoozeMinutes;

  const SnoozeReminderRequest({
    this.snoozeMinutes = 30,
  });

  Map<String, dynamic> toJson() {
    return {
      'snooze_minutes': snoozeMinutes,
    };
  }

  @override
  List<Object?> get props => [snoozeMinutes];
}

class UpdateReminderRequest extends Equatable {
  final String? title;
  final String? description;
  final ReminderType? type;
  final DateTime? scheduledTime;
  final bool? isRecurring;
  final String? recurrencePattern;

  const UpdateReminderRequest({
    this.title,
    this.description,
    this.type,
    this.scheduledTime,
    this.isRecurring,
    this.recurrencePattern,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type!.index,
      if (scheduledTime != null)
        'scheduledTime': scheduledTime!.toIso8601String(),
      if (isRecurring != null) 'isRecurring': isRecurring,
      if (recurrencePattern != null) 'recurrencePattern': recurrencePattern,
    };
  }

  @override
  List<Object?> get props => [
        title,
        description,
        type,
        scheduledTime,
        isRecurring,
        recurrencePattern,
      ];
}
