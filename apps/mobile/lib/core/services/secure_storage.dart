import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like JWT tokens
class SecureStorage {
  static const SecureStorage _instance = SecureStorage._internal();
  const SecureStorage._internal();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // User preference keys
  static const String _rememberMeKey = 'remember_me';
  static const String _cachedRoleKey = 'cached_user_role';
  static const String _cachedFullNameKey = 'cached_full_name';

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _cachedRoleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _cachedRoleKey);
  }

  Future<void> saveFullName(String name) async {
    await _storage.write(key: _cachedFullNameKey, value: name);
  }

  Future<String?> getFullName() async {
    return await _storage.read(key: _cachedFullNameKey);
  }

  /// Save authentication tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    print(
        '🔐 SecureStorage: Saving access token (length: ${accessToken.length})');
    await _storage.write(key: _accessTokenKey, value: accessToken);
    print(
        '🔐 SecureStorage: Saving refresh token (length: ${refreshToken.length})');
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    print('🔐 SecureStorage: Tokens saved to secure storage');
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    print('🔐 SecureStorage: Reading access token from storage');
    final token = await _storage.read(key: _accessTokenKey);
    print(
        '🔐 SecureStorage: Access token read result: ${token != null ? "found (length: ${token.length})" : "null"}');
    return token;
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Clear all stored tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Save remember me preference
  Future<void> saveRememberMe(bool rememberMe) async {
    await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
    print('🔐 SecureStorage: Remember me preference saved: $rememberMe');
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    final rememberMe = value == 'true';
    print('🔐 SecureStorage: Remember me preference read: $rememberMe');
    return rememberMe;
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Generic storage methods for other data
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
