import '../models/user.dart';
import 'token_manager.dart';
import 'secure_storage.dart';
import 'firebase_auth_service.dart';
import '../../features/patient/data/services/local_storage_service.dart';
import 'audio_service.dart';
import 'video_service.dart';
import 'visit_context.dart';

/// Firebase authentication service with API integration
class AuthService {
  final FirebaseAuthService _firebaseAuth;
  final TokenManager _tokenManager;
  final LocalStorageService _localStorage;
  final AudioService _audioService;
  final VideoService _videoService;

  AuthService({
    FirebaseAuthService? firebaseAuth,
    TokenManager? tokenManager,
    LocalStorageService? localStorage,
    AudioService? audioService,
    VideoService? videoService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuthService(),
        _tokenManager = tokenManager ?? TokenManager(SecureStorage()),
        _localStorage = localStorage ?? LocalStorageService(),
        _audioService = audioService ?? AudioService(),
        _videoService = videoService ?? VideoService();

  /// Sign up a new user
  Future<User> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? fullName,
  }) async {
    return await _firebaseAuth.signUp(
      email: email,
      password: password,
      role: role,
      fullName: fullName,
    );
  }

  /// Sign in with email and password
  Future<User> signIn(String email, String password,
      {UserRole? selectedRole}) async {
    return await _firebaseAuth.signIn(email, password,
        selectedRole: selectedRole);
  }

  /// Sign in with Google OAuth using Firebase
  Future<User> signInWithGoogle({UserRole? selectedRole}) async {
    return await _firebaseAuth.signInWithGoogle(selectedRole: selectedRole);
  }


  /// Sign in with Apple (iOS only)
  Future<User> signInWithApple({UserRole? selectedRole}) async {
    return await _firebaseAuth.signInWithApple(selectedRole: selectedRole);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _localStorage.clearAllData();
    await _tokenManager.clearTokens();

    // Clean up any remaining audio recordings
    final savedRecordings = await _audioService.getSavedRecordings();
    for (final file in savedRecordings) {
      await _audioService.deleteRecording(file.path);
    }

    // Clean up any remaining video recordings
    final savedVideos = await _videoService.getSavedVideos();
    for (final file in savedVideos) {
      await _videoService.deleteVideo(file.path);
    }

    // Clear visit context on logout
    VisitContext().clearVisit();
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    return await _firebaseAuth.getCurrentUser();
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return await _firebaseAuth.isAuthenticated();
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.resetPassword(email);
  }

  /// Update password (requires recent authentication)
  Future<void> updatePassword(String newPassword) async {
    await _firebaseAuth.updatePassword(newPassword);
  }

  /// Get access token for API calls
  Future<String?> getAccessToken() async {
    final token = await _firebaseAuth.getIdToken();
    return token;
  }

  /// Get authenticated headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    return headers;
  }

  /// Check if authentication services are available
  bool get isAvailable => true;
}
