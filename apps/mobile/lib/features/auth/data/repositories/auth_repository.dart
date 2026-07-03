import '../../../../core/models/user.dart';
import '../../../../core/services/auth_service.dart';

/// Repository for authentication operations
/// Provides a clean interface between business logic and data sources
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  /// Sign up a new user
  Future<User> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? fullName,
  }) async {
    return await _authService.signUp(
      email: email,
      password: password,
      role: role,
      fullName: fullName,
    );
  }

  /// Sign in with email and password
  Future<User> signIn(String email, String password,
      {UserRole? selectedRole}) async {
    return await _authService.signIn(email, password,
        selectedRole: selectedRole);
  }

  /// Sign in with Google OAuth
  Future<User> signInWithGoogle({UserRole? selectedRole}) async {
    return await _authService.signInWithGoogle(selectedRole: selectedRole);
  }


  /// Sign in with Apple
  Future<User> signInWithApple({UserRole? selectedRole}) async {
    return await _authService.signInWithApple(selectedRole: selectedRole);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    // Early return if authentication service is unavailable
    if (!_authService.isAvailable) {
      return null;
    }
    return await _authService.getCurrentUser();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  /// Get access token for API calls
  Future<String?> getAccessToken() async {
    return await _authService.getAccessToken();
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  /// Get authenticated headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    return await _authService.getAuthHeaders();
  }
}
