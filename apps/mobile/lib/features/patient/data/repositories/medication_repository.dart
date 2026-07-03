import '../models/models.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getMedications();
  Future<Medication?> getMedication(String id);
  Future<Medication> createMedication(Medication medication);
  Future<Medication> updateMedication(Medication medication);
  Future<void> deleteMedication(String id);
  Future<List<Medication>> getMedicationsForToday();
  Future<List<Medication>> getActiveMedications();
  Stream<List<Medication>> watchMedications();
  Stream<List<Medication>> watchTodaysMedications();
}
