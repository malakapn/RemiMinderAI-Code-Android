import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/visit_summary.dart';
import '../../../../shared/validators/visit_summary_validator.dart';

/// Firestore persistence for visit summaries at `users/{uid}/visits/{visitId}`.
class VisitRepositoryFirestore {
  VisitRepositoryFirestore({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User must be signed in to access visit summaries');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _visitDoc(String visitId) {
    final uid = _requireUid();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('visits')
        .doc(visitId);
  }

  Future<void> saveVisitSummary(String visitId, VisitSummary summary) async {
    await _visitDoc(visitId).set(
      {'summary': summary.toMap()},
      SetOptions(merge: true),
    );
  }

  Future<VisitSummary?> loadVisitSummary(String visitId) async {
    final doc = await _visitDoc(visitId).get();
    final data = doc.data();
    if (data == null || data['summary'] == null) return null;

    final json = Map<String, dynamic>.from(data['summary'] as Map);
    final error = VisitSummaryValidator.validate(json);
    if (error != null) {
      AppLogger.warn('Stored visit summary failed schema: $error');
      return null;
    }
    return VisitSummary.fromMap(json);
  }
}
