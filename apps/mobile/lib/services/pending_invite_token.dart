import 'package:shared_preferences/shared_preferences.dart';

/// Persists a care-team invite token until the user signs in.
class PendingInviteToken {
  static const _key = 'pending_invite_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns an accept-invitation route if a token was stored, then clears it.
  static Future<String?> consumeRoute() async {
    final token = await read();
    if (token == null || token.isEmpty) return null;
    await clear();
    return '/accept-invitation?token=$token';
  }
}
