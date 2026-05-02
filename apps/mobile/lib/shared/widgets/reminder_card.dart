// Reminder Card Widget - Adapted from Phase 1 PatientReminders.js card rendering
// Original: JSX card rendering in PatientReminders.js (lines 450-550)
//
// Changes from Phase 1:
// - JSX → Flutter widgets
// - CSS classes → Flutter styling
// - React event handlers → Flutter onPressed callbacks
// - Inline styles → Flutter theme-based styling

import 'package:flutter/material.dart';
import 'package:mediminder_shared/models/reminder.dart';

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
    // Adapted from Phase 1 card structure (lines 450-500)
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status row (adapted from Phase 1 header)
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

            // Message (adapted from Phase 1 description)
            Text(
              reminder.message,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 12),

            // Time and type row (adapted from Phase 1 metadata)
            Row(
              children: [
                Icon(
                  _getReminderIcon(),
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  reminder.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Actions row (adapted from Phase 1 action buttons)
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
    // Adapted from Phase 1 status indicators (lines 480-490)
    Color color;
    String text;

    switch (reminder.status) {
      case ReminderStatus.completed:
        color = Colors.green;
        text = 'Done';
        break;
      case ReminderStatus.snoozed:
        color = Colors.orange;
        text = 'Snoozed';
        break;
      case ReminderStatus.pending:
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
        text = reminder.status.name;
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
    // Adapted from Phase 1 icon logic (lines 460-470)
    switch (reminder.type) {
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.appointment:
        return Icons.calendar_today;
      case ReminderType.task:
        return Icons.task;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime() {
    // Adapted from Phase 1 time formatting (lines 490-510)
    final now = DateTime.now();
    final difference = reminder.scheduledTime.difference(now);

    if (reminder.isOverdue) {
      final hours = difference.inHours.abs();
      if (hours < 1) return 'Just now';
      if (hours < 24) return '$hours hours ago';
      return '${difference.inDays.abs()} days ago';
    }

    if (reminder.isToday) {
      return '${reminder.scheduledTime.hour}:${reminder.scheduledTime.minute.toString().padLeft(2, '0')}';
    }

    if (difference.inDays == 1) return 'Tomorrow';
    if (difference.inDays < 7) return 'In ${difference.inDays} days';

    return '${reminder.scheduledTime.month}/${reminder.scheduledTime.day}';
  }
}