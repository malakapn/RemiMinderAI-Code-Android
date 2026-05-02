/// Thrown when the user picks Patient vs Caregiver on the login path but
/// `/api/users/me` reports a different account type.
class RoleMismatchException implements Exception {
  RoleMismatchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when `/api/users/me` reports caregiver but there is no pending
/// invitation and no active care-team membership for this account.
class CaregiverInviteRequiredException implements Exception {
  CaregiverInviteRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}
