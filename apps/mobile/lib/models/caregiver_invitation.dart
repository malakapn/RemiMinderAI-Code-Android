import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed invitation received by a caregiver (`invitations` collection).
class CaregiverInvitation {
  final String invitationId;
  final String patientId;
  final String patientName;
  final String invitedBy;
  final String inviteeId;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;

  const CaregiverInvitation({
    required this.invitationId,
    required this.patientId,
    required this.patientName,
    required this.invitedBy,
    required this.inviteeId,
    required this.role,
    required this.status,
    this.createdAt,
    this.viewedAt,
    this.acceptedAt,
    this.declinedAt,
  });

  factory CaregiverInvitation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CaregiverInvitation(
      invitationId: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? 'Patient',
      invitedBy: data['invitedBy'] as String? ?? '',
      inviteeId: data['inviteeId'] as String? ?? '',
      role: (data['relationship'] as String?) ??
          (data['role'] as String?) ??
          '',
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: _readDate(data['createdAt']),
      viewedAt: _readDate(data['viewedAt']),
      acceptedAt: _readDate(data['acceptedAt']),
      declinedAt: _readDate(data['declinedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  /// `true` when [createdAt] is within the last 3 days.
  bool get isNew {
    final c = createdAt;
    if (c == null) return false;
    return DateTime.now().difference(c) <= const Duration(days: 3);
  }

  /// Short relative time label from [createdAt].
  String get timeAgoLabel {
    final c = createdAt;
    if (c == null) return '';

    final diff = DateTime.now().difference(c);
    final minutes = diff.inMinutes;
    if (minutes < 60) {
      final m = minutes < 1 ? 1 : minutes;
      return '${m}m ago';
    }
    final hours = diff.inHours;
    if (hours < 24) {
      return '${hours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
