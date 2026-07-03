import 'package:flutter_test/flutter_test.dart';
import 'package:RemiMinder/core/models/user.dart';

void main() {
  group('UserRole', () {
    test('maps caregiver and patient strings', () {
      expect(UserRole.fromString('caregiver'), UserRole.caregiver);
      expect(UserRole.fromString('Caregiver'), UserRole.caregiver);
      expect(UserRole.fromString('patient'), UserRole.patient);
      expect(UserRole.fromString('user'), UserRole.patient);
      expect(UserRole.fromString('Patient'), UserRole.patient);
    });

    test('throws on invalid role', () {
      expect(() => UserRole.fromString('invalid'), throwsArgumentError);
    });
  });
}
