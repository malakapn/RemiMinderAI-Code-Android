import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      return permission;
    }
    if (permissions is List && permissions.isNotEmpty) {
      return permissions.first.toString();
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
    for (final d in patientSnap.docs) {
      out.add(_careTeamDocToMember(d.id, d.data(), uid));
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

  /// Accept invite: `invitations/{token}` + patient's `careTeam/{token}`.
  Future<void> acceptInvitation({required String token}) async {
    final uid = _requireUid();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Account email required to accept invitation');
    }
    final emailNorm = _normalizeEmail(email);

    final invRef = _db.collection('invitations').doc(token);

    await _db.runTransaction((txn) async {
      final invSnap = await txn.get(invRef);
      if (!invSnap.exists) {
        throw Exception('Invitation not found');
      }
      final inv = invSnap.data()!;
      final inviteEmail =
          _normalizeEmail((inv['caregiverEmail'] as String?) ?? '');
      if (inviteEmail != emailNorm) {
        throw Exception('This invitation is for a different email address');
      }

      final patientId = inv['patientId'] as String?;
      if (patientId == null || patientId.isEmpty) {
        throw Exception('Invitation missing patientId');
      }

      final now = FieldValue.serverTimestamp();
      txn.update(invRef, {
        'status': 'accepted',
        'acceptedAt': now,
        'caregiverUid': uid,
      });

      final ctRef = _db
          .collection('users')
          .doc(patientId)
          .collection('careTeam')
          .doc(token);

      txn.set(
        ctRef,
        {
          'status': 'accepted',
          'acceptedAt': now,
          'caregiverUid': uid,
          'memberUserId': uid,
        },
        SetOptions(merge: true),
      );
    });
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
  }) async {
    final uid = _requireUid();
    await _db
        .collection('users')
        .doc(uid)
        .collection('careTeam')
        .doc(memberId)
        .update({
      'permission': permission,
      'permissions': [permission],
    });
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
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
