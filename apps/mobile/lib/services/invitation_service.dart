import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/config/environment.dart';
import '../features/caregiver/data/services/caregiver_api_service.dart';
import '../models/caregiver_invitation.dart';

/// Firestore access for caregiver-received invitations.
class InvitationService {
  InvitationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _activeStatuses = {'pending', 'viewed', 'expired', 'accepted'};

  String? _normalizedEmail(User? user) {
    final email = user?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  /// Invitations for the signed-in caregiver, newest first.
  Stream<List<CaregiverInvitation>> watchReceivedInvitations() {
    final email = _normalizedEmail(_auth.currentUser);
    if (email == null) {
      return Stream<List<CaregiverInvitation>>.value([]);
    }

    return _firestore
        .collection('invitations')
        .where('caregiverEmail', isEqualTo: email)
        .snapshots()
        .map((snap) => _mapAndFilterDocs(snap.docs));
  }

  /// One-shot fetch (same rules as [watchReceivedInvitations]).
  Future<List<CaregiverInvitation>> fetchReceivedInvitations() async {
    final user = _auth.currentUser;
    final email = _normalizedEmail(user);
    if (email == null) return [];

    final snap = await _firestore
        .collection('invitations')
        .where('caregiverEmail', isEqualTo: email)
        .get();

    return _mapAndFilterDocs(snap.docs);
  }

  List<CaregiverInvitation> _mapAndFilterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final all = docs
        .map(CaregiverInvitation.fromFirestore)
        .where((inv) => _activeStatuses.contains(inv.status))
        .toList();

    all.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });

    return _dedupeByPatient(all);
  }

  /// Keep the most actionable invite per patient (pending beats viewed).
  List<CaregiverInvitation> _dedupeByPatient(List<CaregiverInvitation> all) {
    int priority(String status) {
      switch (status) {
        case 'pending':
          return 0;
        case 'viewed':
          return 1;
        case 'expired':
          return 2;
        case 'accepted':
          return 3;
        default:
          return 4;
      }
    }

    final bestByPatient = <String, CaregiverInvitation>{};
    for (final inv in all) {
      final key = inv.patientId.isNotEmpty ? inv.patientId : inv.invitationId;
      final existing = bestByPatient[key];
      if (existing == null ||
          priority(inv.status) < priority(existing.status)) {
        bestByPatient[key] = inv;
      }
    }

    final deduped = bestByPatient.values.toList()
      ..sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

    return deduped;
  }

  /// Marks a pending invitation as viewed (idempotent).
  Future<void> markAsViewed(String invitationId) async {
    final ref = _firestore.collection('invitations').doc(invitationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final status = (snap.data()?['status'] as String?)?.toLowerCase();
      if (status != 'pending') return;
      tx.update(ref, {
        'status': 'viewed',
        'viewedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Accept by deep-link or email token (invitation doc id).
  Future<void> acceptInvitationByToken(String token) async {
    final invSnap =
        await _firestore.collection('invitations').doc(token).get();
    if (!invSnap.exists) {
      throw StateError('Invitation not found');
    }

    final invData = invSnap.data() ?? {};
    final user = _auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    final isRelayEmail =
        email != null && email.contains('privaterelay.appleid.com');
    if (!isRelayEmail && email != null && email.isNotEmpty) {
      final inviteEmail =
          (invData['caregiverEmail'] as String?)?.trim().toLowerCase() ?? '';
      if (inviteEmail.isNotEmpty && inviteEmail != email) {
        throw StateError('This invitation is for a different email address');
      }
    }

    final invitation = CaregiverInvitation.fromFirestore(invSnap);
    await acceptInvitation(invitation);
  }

  /// Accept: atomic batch updating invitation + both relationship docs.
  Future<void> acceptInvitation(CaregiverInvitation invitation) async {
    final caregiverId = _auth.currentUser?.uid;
    if (caregiverId == null) {
      throw StateError('Not signed in');
    }

    final invSnap = await _firestore
        .collection('invitations')
        .doc(invitation.invitationId)
        .get();
    final invData = invSnap.data() ?? {};
    final permission = (invData['permission'] as String?)?.trim();
    final resolvedPermission =
        (permission != null && permission.isNotEmpty) ? permission : 'view';
    final relationship = (invData['relationship'] as String?) ??
        (invData['role'] as String?) ??
        invitation.role;

    final batch = _firestore.batch();
    final invRef =
        _firestore.collection('invitations').doc(invitation.invitationId);

    batch.update(invRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'caregiverUid': caregiverId,
    });

    final connectedRef = _firestore
        .collection('users')
        .doc(caregiverId)
        .collection('connectedPatients')
        .doc(invitation.patientId);

    batch.set(connectedRef, {
      'patientId': invitation.patientId,
      'patientName': invitation.patientName,
      'role': relationship,
      'invitationId': invitation.invitationId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final careTeamRef = _firestore
        .collection('users')
        .doc(invitation.patientId)
        .collection('careTeam')
        .doc(invitation.invitationId);

    String caregiverName = _auth.currentUser?.displayName ?? '';
    String caregiverEmail = _auth.currentUser?.email ?? '';
    try {
      final userDoc =
          await _firestore.collection('users').doc(caregiverId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        caregiverName =
            (data['displayName'] ?? data['fullName'] ?? caregiverName)
                .toString();
        caregiverEmail = (data['email'] ?? caregiverEmail).toString();
      }
    } catch (_) {}

    batch.set(careTeamRef, {
      'id': invitation.invitationId,
      'memberUserId': caregiverId,
      'caregiverUid': caregiverId,
      'name': caregiverName.isNotEmpty ? caregiverName : caregiverEmail,
      'email': caregiverEmail,
      'relationship': relationship,
      'permission': resolvedPermission,
      'permissions': [resolvedPermission],
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    await _syncBackendAccess(invitation.patientId);
  }

  Future<void> _syncBackendAccess(String patientId) async {
    if (patientId.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken(true);
      if (token == null) return;
      await CaregiverApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: token,
      ).syncPatientAccess(patientId);
    } catch (e) {
      debugPrint('Backend access sync failed: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }
}
