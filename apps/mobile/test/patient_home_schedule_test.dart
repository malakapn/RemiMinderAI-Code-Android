import 'package:flutter_test/flutter_test.dart';

/// Mirrors the home-screen merge/dedupe behavior for quick pre-push checks.
List<Map<String, dynamic>> mergeScheduleReminders({
  required List<Map<String, dynamic>> today,
  required List<Map<String, dynamic>> upcoming,
  List<Map<String, dynamic>> past = const [],
}) {
  bool isActive(Map<String, dynamic> reminder) {
    final status =
        (reminder['display_status'] ?? reminder['status'] ?? 'pending')
            .toString()
            .toLowerCase();
    return status != 'completed' &&
        status != 'complete' &&
        status != 'skipped' &&
        status != 'cancelled';
  }

  bool isSchedule(Map<String, dynamic> reminder) {
    final type = (reminder['reminder_type'] ?? reminder['type'] ?? '')
        .toString()
        .toLowerCase();
    return type.isEmpty || type == 'medication' || type == 'appointment';
  }

  int sortKey(Map<String, dynamic> reminder) {
    final scheduled = DateTime.tryParse(
          reminder['scheduled_time']?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return scheduled.millisecondsSinceEpoch;
  }

  final seen = <String>{};
  final merged = <Map<String, dynamic>>[];
  for (final reminder in [...today, ...upcoming, ...past]) {
    if (!isSchedule(reminder) || !isActive(reminder)) continue;
    final id = reminder['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      if (seen.contains(id)) continue;
      seen.add(id);
    }
    merged.add(reminder);
  }
  merged.sort((a, b) => sortKey(a).compareTo(sortKey(b)));
  return merged;
}

void main() {
  test('merges today and upcoming reminders in scheduled order', () {
    final today = [
      {
        'id': 'today-1',
        'status': 'pending',
        'scheduled_time': '2026-06-14T18:00:00Z',
      },
    ];
    final upcoming = [
      {
        'id': 'future-1',
        'status': 'pending',
        'scheduled_time': '2026-06-16T09:00:00Z',
      },
    ];

    final merged = mergeScheduleReminders(today: today, upcoming: upcoming);

    expect(merged.map((r) => r['id']).toList(), ['today-1', 'future-1']);
  });

  test('drops completed reminders from schedule list', () {
    final today = [
      {
        'id': 'done-1',
        'status': 'completed',
        'scheduled_time': '2026-06-14T10:00:00Z',
      },
    ];
    final upcoming = [
      {
        'id': 'future-1',
        'status': 'pending',
        'scheduled_time': '2026-06-16T09:00:00Z',
      },
    ];

    final merged = mergeScheduleReminders(today: today, upcoming: upcoming);

    expect(merged.map((r) => r['id']).toList(), ['future-1']);
  });

  test('includes active medication reminders from past bucket', () {
    final past = [
      {
        'id': 'missed-1',
        'status': 'pending',
        'display_status': 'Missed',
        'reminder_type': 'medication',
        'scheduled_time': '2026-06-14T10:00:00Z',
      },
    ];

    final merged = mergeScheduleReminders(
      today: const [],
      upcoming: const [],
      past: past,
    );

    expect(merged.map((r) => r['id']).toList(), ['missed-1']);
  });

  test('dedupes reminders that appear in both buckets', () {
    final reminder = {
      'id': 'shared-1',
      'status': 'pending',
      'scheduled_time': '2026-06-14T18:00:00Z',
    };

    final merged = mergeScheduleReminders(
      today: [reminder],
      upcoming: [reminder],
    );

    expect(merged.length, 1);
    expect(merged.first['id'], 'shared-1');
  });
}
