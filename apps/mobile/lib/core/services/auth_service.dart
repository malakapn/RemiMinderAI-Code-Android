import '../models/user.dart';
import 'token_manager.dart';
import 'secure_storage.dart';
import 'firebase_auth_service.dart';
import '../../features/patient/data/services/local_storage_service.dart';
import 'audio_service.dart';
import 'notification_service.dart';
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

  /// Sign out current user
  Future<void> signOut() async {
    // Backend FCM row must be cleared while we still have a Firebase ID token.
    try {
      await NotificationService()
          .unregisterBackendFcmToken()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Continue local sign-out even if backend is unreachable.
    }

    try {
      await _firebaseAuth.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Continue cleanup even if Firebase sign-out hangs/fails.
    }
    await _localStorage.clearAllData().timeout(const Duration(seconds: 3));
    await _tokenManager.clearTokens().timeout(const Duration(seconds: 3));

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

    // Cancel all local scheduled notifications (patient + caregiver mirrors)
    await NotificationService().cancelAllReminders();

    // Invalidate installation token after auth session is gone
    await NotificationService()
        .clearLocalFcmRegistration()
        .timeout(const Duration(seconds: 3));

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
    final firebaseToken = await _firebaseAuth.getIdToken();
    if (firebaseToken != null && firebaseToken.trim().isNotEmpty) {
      return firebaseToken;
    }

    // Fallback: Firebase currentUser can be temporarily null right after login
    // or app resume. We persist the same ID token in secure storage at sign-in.
    final storedToken = await _tokenManager.getAccessToken();
    if (storedToken != null && storedToken.trim().isNotEmpty) {
      return storedToken;
    }
    return null;
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
