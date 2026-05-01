import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static const _activeStatuses = ['pending', 'viewed', 'expired'];

  /// Invitations for the signed-in caregiver, newest first.
  Stream<List<CaregiverInvitation>> watchReceivedInvitations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<CaregiverInvitation>>.value([]);
    }

    return _firestore
        .collection('invitations')
        .where('inviteeId', isEqualTo: uid)
        .where('status', whereIn: _activeStatuses)
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(CaregiverInvitation.fromFirestore)
              .toList(growable: false),
        );
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

  /// Accept: atomic batch updating invitation + both relationship docs.
  Future<void> acceptInvitation(CaregiverInvitation invitation) async {
    final caregiverId = _auth.currentUser?.uid;
    if (caregiverId == null) {
      throw StateError('Not signed in');
    }

    final batch = _firestore.batch();
    final invRef =
        _firestore.collection('invitations').doc(invitation.invitationId);

    batch.update(invRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    final connectedRef = _firestore
        .collection('users')
        .doc(caregiverId)
        .collection('connectedPatients')
        .doc(invitation.patientId);

    batch.set(connectedRef, {
      'patientId': invitation.patientId,
      'patientName': invitation.patientName,
      'role': invitation.role,
      'invitationId': invitation.invitationId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final careTeamRef = _firestore
        .collection('patients')
        .doc(invitation.patientId)
        .collection('careTeam')
        .doc(caregiverId);

    batch.set(careTeamRef, {
      'caregiverId': caregiverId,
      'role': invitation.role,
      'invitationId': invitation.invitationId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
    });
  }
}
