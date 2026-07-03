import '../models/models.dart';

abstract class CaregiverRepository {
  Future<List<Caregiver>> getCaregivers();
  Future<Caregiver?> getCaregiver(String id);
  Future<Caregiver> inviteCaregiver(Caregiver caregiver);
  Future<Caregiver> updateCaregiver(Caregiver caregiver);
  Future<void> removeCaregiver(String id);
  Future<List<Caregiver>> getActiveCaregivers();
  Future<List<Caregiver>> getPendingInvitations();
  Future<void> resendInvitation(String caregiverId);
  Future<void> updateCaregiverPermissions(String caregiverId, List<Permission> permissions);
  Stream<List<Caregiver>> watchCaregivers();
  Stream<List<Caregiver>> watchActiveCaregivers();
}
