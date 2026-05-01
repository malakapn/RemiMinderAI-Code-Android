import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Merged view of `users/{caregiverId}/connectedPatients/{id}` and optional
/// `patients/{patientId}` profile.
class ConnectedPatient {
  final String patientId;
  final String displayName;
  final String role;
  final String invitationId;
  final DateTime? joinedAt;

  final String? profileName;
  final String? dob;
  final String? gender;
  final String? primaryCondition;
  final String? allergies;
  final List<String> medications;
  final List<String> alerts;
  final DateTime? lastSyncedAt;

  const ConnectedPatient({
    required this.patientId,
    required this.displayName,
    required this.role,
    required this.invitationId,
    this.joinedAt,
    this.profileName,
    this.dob,
    this.gender,
    this.primaryCondition,
    this.allergies,
    this.medications = const [],
    this.alerts = const [],
    this.lastSyncedAt,
  });

  factory ConnectedPatient.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> linkDoc,
    DocumentSnapshot<Map<String, dynamic>>? patientDoc,
  ) {
    final link = linkDoc.data() ?? {};
    final patientId = link['patientId'] as String? ?? linkDoc.id;
    final linkName = (link['patientName'] as String?)?.trim() ?? '';
    final role = (link['role'] as String?)?.trim() ?? '';
    final invitationId = (link['invitationId'] as String?)?.trim() ?? '';
    final joinedAt = _readTimestamp(link['joinedAt']);

    Map<String, dynamic>? p;
    if (patientDoc != null && patientDoc.exists) {
      p = patientDoc.data();
    }

    final profileName = p != null ? (p['name'] as String?)?.trim() : null;
    final displayName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (linkName.isNotEmpty ? linkName : 'Patient');

    return ConnectedPatient(
      patientId: patientId,
      displayName: displayName,
      role: role,
      invitationId: invitationId,
      joinedAt: joinedAt,
      profileName: profileName,
      dob: p != null ? (p['dob'] as String?)?.trim() : null,
      gender: p != null ? (p['gender'] as String?)?.trim() : null,
      primaryCondition:
          p != null ? (p['primaryCondition'] as String?)?.trim() : null,
      allergies: p != null ? (p['allergies'] as String?)?.trim() : null,
      medications: p != null ? _stringList(p['medications']) : const [],
      alerts: p != null ? _stringList(p['alerts']) : const [],
      lastSyncedAt:
          p != null ? _readTimestamp(p['lastSyncedAt']) : null,
    );
  }

  static DateTime? _readTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static List<String> _stringList(dynamic v) {
    if (v == null) return [];
    if (v is! List) return [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static const _avatarPalettes = [
    (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    (Color(0xFFE6F1FB), Color(0xFF185FA5)),
    (Color(0xFFEEEDFE), Color(0xFF534AB7)),
    (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  ];

  (Color bg, Color fg) get avatarColors {
    final i = patientId.hashCode.abs() % 4;
    return _avatarPalettes[i];
  }

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2
          ? s.substring(0, 2).toUpperCase()
          : s.toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get lastSyncLabel {
    final t = lastSyncedAt;
    if (t == null) return 'Never synced';
    final diff = DateTime.now().difference(t);
    final minutes = diff.inMinutes;
    if (minutes < 60) {
      final m = minutes < 1 ? 1 : minutes;
      return '${m}m ago';
    }
    final hours = diff.inHours;
    if (hours < 24) return '${hours}h ago';
    return '${diff.inDays}d ago';
  }

  String get joinedLabel {
    final j = joinedAt;
    if (j == null) return '';
    return 'Joined ${DateFormat('MMM d').format(j)}';
  }

  bool get isNew {
    final j = joinedAt;
    if (j == null) return false;
    return DateTime.now().difference(j) <= const Duration(days: 3);
  }
}
