import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connected_patient.dart';
import '../services/my_patients_repository.dart';

final myPatientsRepositoryProvider = Provider<MyPatientsRepository>((ref) {
  return MyPatientsRepository();
});

final myPatientsProvider =
    StreamProvider.autoDispose<List<ConnectedPatient>>((ref) {
  final repo = ref.watch(myPatientsRepositoryProvider);
  return repo.watchMyPatients();
});
