import 'secure_storage.dart';

/// Persists SQL care-team invite token from email deep links until the caregiver
/// signs in and [POST /api/care-team/accept] runs successfully.
class PendingCareInviteToken {
  PendingCareInviteToken._();

  static const _key = 'pending_care_team_sql_invite_token';

  static Future<void> save(String? token) async {
    final s = SecureStorage();
    final t = token?.trim();
    if (t == null || t.isEmpty) {
      await s.delete(_key);
      return;
    }
    await s.write(_key, t);
  }

  static Future<String?> peek() => SecureStorage().read(_key);

  static Future<void> clear() => SecureStorage().delete(_key);
}
