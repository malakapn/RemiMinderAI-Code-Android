import 'package:jwt_decoder/jwt_decoder.dart';
import 'secure_storage.dart';

/// JWT token management service
class TokenManager {
  final SecureStorage _storage;

  TokenManager(this._storage);

  /// Save tokens after successful authentication
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.saveTokens(accessToken, refreshToken);
  }

  /// Get the current access token
  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  /// Get the current refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.getRefreshToken();
  }

  /// Check if the current access token is valid (not expired)
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null) {
      return false;
    }

    try {
      final isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  /// Get decoded token payload
  Future<Map<String, dynamic>?> getTokenPayload() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Check if token will expire soon (within specified minutes)
  Future<bool> willExpireSoon({int minutes = 5}) async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final timeUntilExpiry = expiryDate.difference(now);

      return timeUntilExpiry.inMinutes < minutes;
    } catch (e) {
      return true;
    }
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _storage.clearTokens();
  }

  /// Get user ID from token payload
  Future<String?> getUserId() async {
    final payload = await getTokenPayload();
    if (payload == null) return null;

    return payload['sub'] as String?;
  }
}
