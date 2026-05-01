import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/connected_patient.dart';

/// Firestore: caregiver's `connectedPatients` + optional `patients` profile.
class MyPatientsRepository {
  MyPatientsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<ConnectedPatient>> watchMyPatients() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<ConnectedPatient>>.value([]);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('connectedPatients')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .asyncMap(_mergeWithPatientProfiles);
  }

  Future<List<ConnectedPatient>> _mergeWithPatientProfiles(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final futures = snapshot.docs.map((linkDoc) async {
      final data = linkDoc.data();
      final patientId = data['patientId'] as String? ?? linkDoc.id;
      try {
        final patientSnap =
            await _firestore.collection('patients').doc(patientId).get();
        if (patientSnap.exists) {
          return ConnectedPatient.fromFirestore(linkDoc, patientSnap);
        }
      } catch (_) {
        // Permission denied or network — fall back to link doc only.
      }
      return ConnectedPatient.fromFirestore(linkDoc, null);
    });
    return Future.wait(futures);
  }
}
