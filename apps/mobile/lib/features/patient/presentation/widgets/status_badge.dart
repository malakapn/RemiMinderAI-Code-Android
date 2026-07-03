import 'package:flutter/material.dart';

enum StatusType {
  reminder,
  caregiver,
  appointment,
  medication,
}

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusType type;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    required this.type,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: fontSize,
            color: statusInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            statusInfo.text,
            style: TextStyle(
              fontSize: fontSize,
              color: statusInfo.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status, StatusType type) {
    switch (type) {
      case StatusType.reminder:
        return _getReminderStatusInfo(status);
      case StatusType.caregiver:
        return _getCaregiverStatusInfo(status);
      case StatusType.appointment:
        return _getAppointmentStatusInfo(status);
      case StatusType.medication:
        return _getMedicationStatusInfo(status);
    }
  }

  _StatusInfo _getReminderStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return _StatusInfo('Done', Colors.green, Icons.check_circle);
      case 'pending':
      case 'active':
        return _StatusInfo('Pending', Colors.blue, Icons.schedule);
      case 'due now':
        return _StatusInfo('Due Now', Colors.red, Icons.alarm);
      case 'upcoming':
        return _StatusInfo('Upcoming', Colors.blue, Icons.schedule);
      case 'missed':
        return _StatusInfo('Missed', Colors.red, Icons.warning_amber);
      case 'snoozed':
        return _StatusInfo('Snoozed', Colors.orange, Icons.snooze);
      case 'skipped':
        return _StatusInfo('Skipped', Colors.grey, Icons.skip_next);
      default:
        if (status.isNotEmpty) {
          return _StatusInfo(status, Colors.blue, Icons.schedule);
        }
        return _StatusInfo('Pending', Colors.blue, Icons.schedule);
    }
  }

  _StatusInfo _getCaregiverStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return _StatusInfo('Active', Colors.green, Icons.check_circle);
      case 'pending':
        return _StatusInfo('Pending', Colors.orange, Icons.schedule);
      case 'declined':
        return _StatusInfo('Declined', Colors.red, Icons.cancel);
      default:
        return _StatusInfo('Unknown', Colors.grey, Icons.help);
    }
  }

  _StatusInfo _getAppointmentStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return _StatusInfo('Scheduled', Colors.blue, Icons.calendar_today);
      case 'confirmed':
        return _StatusInfo('Confirmed', Colors.green, Icons.check_circle);
      case 'completed':
        return _StatusInfo('Completed', Colors.grey, Icons.done_all);
      case 'cancelled':
        return _StatusInfo('Cancelled', Colors.red, Icons.cancel);
      case 'rescheduled':
        return _StatusInfo('Rescheduled', Colors.orange, Icons.update);
      default:
        return _StatusInfo('Unknown', Colors.grey, Icons.help);
    }
  }

  _StatusInfo _getMedicationStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _StatusInfo('Active', Colors.green, Icons.check_circle);
      case 'completed':
        return _StatusInfo('Completed', Colors.blue, Icons.done);
      case 'paused':
        return _StatusInfo('Paused', Colors.orange, Icons.pause);
      case 'discontinued':
        return _StatusInfo('Discontinued', Colors.red, Icons.stop);
      default:
        return _StatusInfo('Unknown', Colors.grey, Icons.help);
    }
  }
}

class _StatusInfo {
  final String text;
  final Color color;
  final IconData icon;

  _StatusInfo(this.text, this.color, this.icon);
}
