import 'package:flutter_test/flutter_test.dart';
import 'package:RemiMinder/core/models/user.dart';

void main() {
  group('UserRole', () {
    test('normalizes caregiver role values from backend and Firestore shapes',
        () {
      expect(UserRole.tryFromString('caregiver'), UserRole.caregiver);
      expect(UserRole.tryFromString('Caregiver'), UserRole.caregiver);
      expect(UserRole.tryFromString('care giver'), UserRole.caregiver);
      expect(UserRole.tryFromString('care-giver'), UserRole.caregiver);
    });

    test('maps patient aliases to patient', () {
      expect(UserRole.tryFromString('patient'), UserRole.patient);
      expect(UserRole.tryFromString('user'), UserRole.patient);
      expect(UserRole.tryFromString('Patient'), UserRole.patient);
    });

    test('resolves role field from user profile json', () {
      final profile = UserProfile.fromJson({
        'full_name': 'Tina Caregiver',
        'email': 'tina@example.com',
        'phone': null,
        'role': 'Caregiver',
      });

      expect(profile.role, 'caregiver');
    });

    test('resolves userType field from Firestore-shaped profile json', () {
      expect(
        UserRole.fromProfileJson({
          'email': 'tina@example.com',
          'userType': 'Caregiver',
        }),
        UserRole.caregiver,
      );
    });

    test('resolves boolean caregiver marker from Firestore-shaped profile json',
        () {
      expect(
        UserRole.fromProfileJson({
          'email': 'tina@example.com',
          'isCaregiver': true,
        }),
        UserRole.caregiver,
      );
    });
  });
}
