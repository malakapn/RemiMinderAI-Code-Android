// Reminder Card Widget - Adapted from Phase 1 PatientReminders.js card rendering
// Original: JSX card rendering in PatientReminders.js (lines 450-550)
//
// Changes from Phase 1:
// - JSX → Flutter widgets
// - CSS classes → Flutter styling
// - React event handlers → Flutter onPressed callbacks
// - Inline styles → Flutter theme-based styling

import 'package:flutter/material.dart';

import '../../core/utils/locale_format.dart';
import '../../l10n/app_localizations.dart';
import '../models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final bool showActions;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onSnooze,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reminder.description,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getReminderIcon(),
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  reminder.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (showActions && (onComplete != null || onSnooze != null)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onSnooze != null)
                    TextButton(
                      onPressed: onSnooze,
                      child: const Text('Snooze'),
                    ),
                  if (onComplete != null)
                    ElevatedButton(
                      onPressed: onComplete,
                      child: const Text('Complete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (reminder.status) {
      case 'completed':
        color = Colors.green;
        text = 'Done';
        break;
      case 'snoozed':
        color = Colors.orange;
        text = 'Snoozed';
        break;
      case 'pending':
        if (reminder.isOverdue) {
          color = Colors.red;
          text = 'Overdue';
        } else {
          color = Colors.blue;
          text = 'Pending';
        }
        break;
      default:
        color = Colors.grey;
        text = reminder.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getReminderIcon() {
    switch (reminder.type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'measurement':
        return Icons.monitor_heart;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheduled = reminder.scheduledTime.toLocal();

    if (reminder.isToday && !reminder.isOverdue) {
      return LocaleFormat.time(context, scheduled);
    }

    final delta = scheduled.difference(DateTime.now());
    if (reminder.isOverdue || delta.inDays.abs() < 7) {
      return LocaleFormat.reminderRelativeTime(context, scheduled, l10n);
    }

    return LocaleFormat.dateMd(context, scheduled);
  }
}
