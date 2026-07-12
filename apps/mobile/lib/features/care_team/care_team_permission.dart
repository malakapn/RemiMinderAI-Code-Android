/// Normalizes caregiver access levels from Firestore / API into `full` or `view`.
class CareTeamPermission {
  CareTeamPermission._();

  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return 'view';

    if (value == 'full' ||
        value == 'full_access' ||
        value == 'full access' ||
        value == 'write' ||
        value == 'edit') {
      return 'full';
    }

    if (value.contains('full')) {
      return 'full';
    }

    return 'view';
  }

  static bool isFullAccess(String? raw) => normalize(raw) == 'full';
}
