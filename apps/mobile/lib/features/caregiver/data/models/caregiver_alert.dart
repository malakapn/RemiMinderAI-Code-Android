class CaregiverAlert {
  final String id;
  final String caregiverId;
  final String userId;
  final String reminderId;
  final String alertType;
  final String message;
  final DateTime sentAt;
  final bool read;

  const CaregiverAlert({
    required this.id,
    required this.caregiverId,
    required this.userId,
    required this.reminderId,
    required this.alertType,
    required this.message,
    required this.sentAt,
    required this.read,
  });

  factory CaregiverAlert.fromJson(Map<String, dynamic> json) {
    return CaregiverAlert(
      id: json['id']?.toString() ?? '',
      caregiverId: json['caregiver_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      reminderId: json['reminder_id']?.toString() ?? '',
      alertType: json['alert_type']?.toString() ?? 'alert',
      message: json['message']?.toString() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }
}
