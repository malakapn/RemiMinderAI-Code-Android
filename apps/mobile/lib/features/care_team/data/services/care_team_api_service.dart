import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../services/invitation_service.dart';
import '../../care_team_permission.dart';
import '../models/care_team_invitation.dart';
import '../models/care_team_member.dart';

/// Care team + invitations backed by Firestore (replacing legacy REST API).
class CareTeamApiService {
  CareTeamApiService();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache (per app process)
  static CacheEntry<List<CareTeamMember>>? _membersCache;
  static CacheEntry<List<CareTeamInvitation>>? _pendingInvitesCache;

  static List<CareTeamMember>? getCachedMembers() {
    return _membersCache?.data;
  }

  static List<CareTeamInvitation>? getCachedPendingInvites() {
    return _pendingInvitesCache?.data;
  }

  static void setCachedMembers(List<CareTeamMember> members) {
    _membersCache = CacheEntry(members, DateTime.now());
  }

  static void setCachedPendingInvites(List<CareTeamInvitation> invites) {
    _pendingInvitesCache = CacheEntry(invites, DateTime.now());
  }

  static void invalidateCaches() {
    _membersCache = null;
    _pendingInvitesCache = null;
  }

  String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not authenticated');
    }
    return uid;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String? _timestampToIsoString(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is String) {
      return value;
    }
    return null;
  }

  String _permissionToString(dynamic permission, dynamic permissions) {
    if (permission is String && permission.isNotEmpty) {
      return CareTeamPermission.normalize(permission);
    }
    if (permissions is List && permissions.isNotEmpty) {
      return CareTeamPermission.normalize(permissions.first.toString());
    }
    return 'view';
  }

  /// Maps a `users/{patientId}/careTeam/{docId}` document to [CareTeamMember.fromJson] shape.
  CareTeamMember _careTeamDocToMember(
    String docId,
    Map<String, dynamic> data,
    String patientId,
  ) {
    final json = <String, dynamic>{
      'id': data['id'] as String? ?? docId,
      'patient_id': patientId,
      'member_user_id': data['memberUserId'] ??
          data['caregiverUid'] ??
          data['caregiver_uid'] ??
          '',
      'full_name': data['name'] as String?,
      'email': (data['email'] ?? data['caregiverEmail']) as String?,
      'role': (data['relationship'] ?? data['role'] ?? '') as String,
      'permission': _permissionToString(data['permission'], data['permissions']),
      'status': (data['status'] ?? 'accepted') as String,
    };
    return CareTeamMember.fromJson(json);
  }

  /// Maps invitation or pending careTeam doc to [CareTeamInvitation.fromJson] shape.
  CareTeamInvitation _toInvitation(String docId, Map<String, dynamic> data) {
    final json = <String, dynamic>{
      'id': data['id'] as String? ?? docId,
      'patient_id': data['patientId'] as String?,
      'patient_name': data['patientName'] as String?,
      'invitee_email': (data['caregiverEmail'] ?? data['email'] ?? '') as String,
      'role': (data['relationship'] ?? data['role'] ?? '') as String,
      'permission': _permissionToString(data['permission'], data['permissions']),
      'status': (data['status'] ?? 'pending') as String,
      'token': data['inviteId'] as String? ?? docId,
      'created_at': _timestampToIsoString(data['createdAt']),
    };
    return CareTeamInvitation.fromJson(json);
  }

  CareTeamMember _invitationAcceptedToMember(
    String inviteId,
    Map<String, dynamic> data,
    String caregiverUid,
  ) {
    final patientId = data['patientId'] as String? ?? '';
    final json = <String, dynamic>{
      'id': inviteId,
      'patient_id': patientId,
      'member_user_id': caregiverUid,
      'full_name': data['patientName'] as String?,
      'email': data['patientEmail'] as String?,
      'role': (data['relationship'] ?? 'Caregiver') as String,
      'permission': _permissionToString(data['permission'], data['permissions']),
      'status': 'accepted',
    };
    return CareTeamMember.fromJson(json);
  }

  /// Accepted caregivers on `users/{userId}/careTeam`, plus patients this user
  /// cares for (`invitations` where `caregiverUid` matches and `status` is accepted).
  Future<List<CareTeamMember>> getCareTeam() async {
    final uid = _requireUid();
    final out = <CareTeamMember>[];

    final patientSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .where('status', isEqualTo: 'accepted')
        .get();
    final seenMemberIds = <String>{};
    for (final d in patientSnap.docs) {
      final data = d.data();
      // Check both memberUserId and caregiverUid for deduplication
      final rawId = (data['memberUserId'] ?? data['caregiverUid'] ?? '').toString();
      if (rawId.isNotEmpty && seenMemberIds.contains(rawId)) continue;
      if (rawId.isNotEmpty) seenMemberIds.add(rawId);
      final member = _careTeamDocToMember(d.id, data, uid);
      out.add(member);
    }

    final invSnap = await _db
        .collection('invitations')
        .where('caregiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (final d in invSnap.docs) {
      out.add(_invitationAcceptedToMember(d.id, d.data(), uid));
    }

    return out;
  }

  /// Creates `invitations/{inviteId}` and mirrors to `users/{userId}/careTeam/{inviteId}`.
  Future<void> inviteCaregiver({
    required String email,
    required String role,
    required String permission,
  }) async {
    final uid = _requireUid();
    final inviteRef = _db.collection('invitations').doc();
    final inviteId = inviteRef.id;
    final emailNorm = _normalizeEmail(email);
    final patient = FirebaseAuth.instance.currentUser;
    final patientName =
        patient?.displayName ?? patient?.email ?? 'Patient';
    final patientEmail = patient?.email;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(inviteRef, {
      'inviteId': inviteId,
      'patientId': uid,
      'patientName': patientName,
      if (patientEmail != null) 'patientEmail': patientEmail,
      'caregiverEmail': emailNorm,
      'inviteeId': null, // TODO: populate inviteeId when caregiver accepts so watchReceivedInvitations stream works.
      'relationship': role,
      'permission': permission,
      'permissions': [permission],
      'status': 'pending',
      'createdAt': now,
    });

    final careTeamRef =
        _db.collection('users').doc(uid).collection('careTeam').doc(inviteId);

    batch.set(careTeamRef, {
      'id': inviteId,
      'inviteId': inviteId,
      'patientId': uid,
      'patientName': patientName,
      'name': emailNorm,
      'email': emailNorm,
      'caregiverEmail': emailNorm,
      'relationship': role,
      'permission': permission,
      'permissions': [permission],
      'status': 'pending',
      'activityCount': 0,
      'createdAt': now,
    });

    await batch.commit();
  }

  /// Accept invite via unified caregiver invitation flow.
  Future<void> acceptInvitation({required String token}) async {
    _requireUid();
    await InvitationService().acceptInvitationByToken(token);
  }

  /// Invitations where `caregiverEmail` matches the signed-in user's email.
  Future<List<CareTeamInvitation>> getMyInvitations() async {
    _requireUid();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      return [];
    }
    final emailNorm = _normalizeEmail(email);

    final snap = await _db
        .collection('invitations')
        .where('caregiverEmail', isEqualTo: emailNorm)
        .get();

    return snap.docs.map((d) => _toInvitation(d.id, d.data())).toList();
  }

  /// Pending rows on `users/{userId}/careTeam`.
  Future<List<CareTeamInvitation>> getPendingInvitations() async {
    final uid = _requireUid();
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .where('status', isEqualTo: 'pending')
        .get();

    return snap.docs.map((d) => _toInvitation(d.id, d.data())).toList();
  }

  Future<void> cancelPendingInvitation({required String invitationId}) async {
    final uid = _requireUid();
    final batch = _db.batch();

    batch.delete(
      _db.collection('users').doc(uid).collection('careTeam').doc(invitationId),
    );

    batch.update(_db.collection('invitations').doc(invitationId), {
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> resendPendingInvitation(String invitationId) async {
    _requireUid();
    await _db.collection('invitations').doc(invitationId).update({
      'resendRequestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePermission({
    required String memberId,
    required String permission,
    String? memberEmail,
  }) async {
    final uid = _requireUid();
    final payload = {
      'permission': CareTeamPermission.normalize(permission),
      'permissions': [CareTeamPermission.normalize(permission)],
    };

    // Firestore is the primary store for mobile care-team data.
    await _db
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .doc(memberId)
        .set(payload, SetOptions(merge: true));

    final inviteRef = _db.collection('invitations').doc(memberId);
    final inviteSnap = await inviteRef.get();
    if (inviteSnap.exists) {
      await inviteRef.set(payload, SetOptions(merge: true));
    }

    _membersCache = null;

    // Best-effort SQL sync when the caregiver also exists in the backend DB.
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    final sqlMemberId =
        await _resolveSqlMemberId(token, memberId, memberEmail);
    if (sqlMemberId == null) return;

    try {
      final response = await http.patch(
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/$sqlMemberId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'permission': CareTeamPermission.normalize(permission)}),
      );
      if (response.statusCode != 200) {
        // Firestore already updated; backend may not have this member yet.
        return;
      }
    } catch (_) {
      return;
    }
  }

  Future<String?> _resolveSqlMemberId(
    String token,
    String memberId,
    String? memberEmail,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/care-team'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is! List) return null;

      final normalizedEmail = memberEmail?.trim().toLowerCase();
      for (final raw in decoded) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final id = m['id']?.toString();
        if (id == null || id.isEmpty) continue;
        if (id == memberId) return id;
        final email = (m['email'] as String?)?.trim().toLowerCase();
        if (normalizedEmail != null &&
            normalizedEmail.isNotEmpty &&
            email == normalizedEmail) {
          return id;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> removeMember({required String memberId}) async {
    final uid = _requireUid();
    await _db
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .doc(memberId)
        .delete();
  }

  /// Patients linked to the signed-in caregiver (`connectedPatients` subcollection).
  Future<List<Map<String, dynamic>>> getMyPatients() async {
    final uid = _requireUid();
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('connectedPatients')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return <String, dynamic>{
        'patient_id': data['patientId'] ?? doc.id,
        'full_name': data['fullName'] ?? data['name'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }

  /// Reminder rows for a patient (caregiver roster API).
  Future<List<Map<String, dynamic>>> getPatientReminderList(
    String patientId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.get(
      Uri.parse(
        '${Environment.apiBaseUrl}/api/caregivers/patients/$patientId/reminders',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load patient reminders: ${response.statusCode}',
      );
    }
    final decoded = json.decode(response.body);
    return _flattenReminderResponse(decoded);
  }

  List<Map<String, dynamic>> _flattenReminderResponse(dynamic decoded) {
    final rows = <Map<String, dynamic>>[];
    void addItem(dynamic item) {
      if (item is! Map) return;
      final map = Map<String, dynamic>.from(item);
      final scheduled = map['scheduled_time'] ??
          map['scheduledTime'] ??
          map['scheduled_at'];
      if (scheduled != null) {
        map['scheduled_time'] = scheduled.toString();
      }
      map['reminder_type'] ??=
          map['type'] ?? map['reminderType'] ?? 'task';
      rows.add(map);
    }

    if (decoded is List) {
      for (final item in decoded) {
        addItem(item);
      }
      return rows;
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['today', 'upcoming', 'past', 'reminders', 'data']) {
        final bucket = map[key];
        if (bucket is List) {
          for (final item in bucket) {
            addItem(item);
          }
        }
      }
      if (rows.isEmpty) {
        addItem(map);
      }
    }
    return rows;
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
