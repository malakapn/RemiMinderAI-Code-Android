import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/models/user.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/services/secure_storage.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

// Service providers
final _secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final _tokenManagerProvider = Provider<TokenManager>((ref) {
  final storage = ref.watch(_secureStorageProvider);
  return TokenManager(storage);
});

final _authServiceProvider = Provider<AuthService>((ref) {
  final tokenManager = ref.watch(_tokenManagerProvider);
  return AuthService(tokenManager: tokenManager);
});

final _backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final authService = ref.watch(_authServiceProvider);
  return BackendApiService(authService: authService);
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(_authServiceProvider);
  return AuthRepository(authService);
});

// =============================================================================
// STATE NOTIFIER PROVIDER
// =============================================================================

/// Authentication state notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _backendApiService = ref.watch(_backendApiServiceProvider);
    _checkAuthStatus();
    return AuthState.initial();
  }

  late final AuthRepository _authRepository;
  late final BackendApiService _backendApiService;

  /// Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    print("🔥 AuthNotifier._checkAuthStatus() started");
    state = AuthState.loading();

    try {
      // Check if authentication services are available with timeout
      final user = await _authRepository
          .getCurrentUser()
          .timeout(const Duration(seconds: 10));
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      // On ANY error or timeout, fallback to unauthenticated
      // This ensures app never gets stuck in loading state
      state = AuthState.unauthenticated();
    }
  }

  /// Explicit initialization trigger (called from LoadingScreen)
  Future<void> initialize() async {
    print("🔥 AuthNotifier.initialize() called");
    await _checkAuthStatus();
  }

  /// Sign up a new user
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? fullName,
  }) async {
    state = AuthState.loading();

    try {
      // createUserWithEmailAndPassword() already signs the user into Firebase;
      // tokens are saved in FirebaseAuthService. Backend bootstrap/profile is optional.
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
      );

      try {
        await _backendApiService.bootstrapUser(fullName: fullName);
        final profile = await _backendApiService.getMyProfile();

        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile));
      } catch (_) {
        // Backend profile load failed but Firebase account is valid
        // Do NOT sign out — authenticate with Firebase user only
        state = AuthState.authenticated(user);
      }
    } catch (e) {
      if (!state.hasError) {
        state = AuthState.error(e.toString());
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password,
      {UserRole? selectedRole}) async {
    state = AuthState.loading();

    try {
      // Repository → FirebaseAuthService.signIn →
      // FirebaseAuth.instance.signInWithEmailAndPassword(); tokens persisted there.
      final user = await _authRepository.signIn(email, password,
          selectedRole: selectedRole);

      try {
        await _backendApiService.bootstrapUser();
        final profile = await _backendApiService.getMyProfile();

        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile));
      } catch (_) {
        // Backend profile load failed; Firebase session is still valid
        // Do NOT sign out — authenticate with Firebase user only
        state = AuthState.authenticated(user);
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  // REQUIRED SETUP:
  // 1. Register SHA-1 debug fingerprint in Firebase Console → Project Settings → Android app
  // 2. Set GOOGLE_WEB_CLIENT_ID in apps/mobile/.env to the Web OAuth client ID from Firebase
  // Without these two steps, Google Sign-In will always fail with sign_in_failed
  /// Sign in with Google OAuth
  Future<void> signInWithGoogle({UserRole? selectedRole}) async {
    final webClientId = Environment.googleWebClientId;
    if (webClientId == null || webClientId.isEmpty) {
      state = AuthState.error(
        'Google Sign-In is not configured. Please contact support.',
      );
      return;
    }

    state = AuthState.loading();

    try {
      final user =
          await _authRepository.signInWithGoogle(selectedRole: selectedRole);

      // Bootstrap user in backend
      await _backendApiService.bootstrapUser();

      // Fetch user profile from backend
      final profile = await _backendApiService.getMyProfile();

      state = AuthState.authenticated(user,
          profile: AuthProfile.fromUserProfile(profile));
    } catch (e) {
      const googleConfigureMsg =
          'Google Sign-In failed. Please ensure your Google account is configured correctly.';

      if (e is PlatformException) {
        final code = e.code;
        if (code == 'sign_in_failed' || code == 'SIGN_IN_FAILED') {
          state = AuthState.error(googleConfigureMsg);
        } else if (code == 'sign_in_canceled' ||
            code == 'SIGN_IN_CANCELED' ||
            code == 'sign_in_cancelled') {
          state = AuthState.error('Google sign-in was cancelled.');
        } else {
          state = AuthState.error(googleConfigureMsg);
        }
        return;
      }

      final msg = e.toString();
      if (msg.contains(googleConfigureMsg) ||
          msg.contains('sign_in_failed') ||
          msg.contains('SIGN_IN_FAILED')) {
        state = AuthState.error(googleConfigureMsg);
      } else if (msg.contains('cancelled')) {
        state = AuthState.error('Google sign-in was cancelled.');
      } else {
        state = AuthState.error(e.toString());
      }
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    print('🔐 AuthNotifier: signOut() called - setting loading state');
    state = AuthState.loading();

    try {
      print('🔐 AuthNotifier: calling _authRepository.signOut()');
      await _authRepository.signOut();
      print(
          '🔐 AuthNotifier: Firebase signOut completed, setting unauthenticated');
      state = AuthState.unauthenticated();
      print('🔐 AuthNotifier: AuthState set to unauthenticated');
    } catch (e) {
      print('🔐 AuthNotifier: signOut failed: $e');
      state = AuthState.error(e.toString());
    }
  }

  /// Reset password for email
  Future<void> resetPassword(String email) async {
    state = AuthState.loading();

    try {
      await _authRepository.resetPassword(email);
      state = AuthState.unauthenticated(); // Go back to login
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    if (!state.isAuthenticated) return;

    state = AuthState.loading();

    try {
      await _authRepository.updatePassword(newPassword);
      // Stay authenticated with same user
      state = AuthState.authenticated(state.user!);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Clear any error messages
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Retry authentication check
  Future<void> retryAuthCheck() async {
    await _checkAuthStatus();
  }

  /// Update user profile in state
  void updateProfile(AuthProfile? profile) {
    if (state.user != null) {
      state = AuthState.authenticated(state.user!, profile: profile);
    }
  }
}

// =============================================================================
// MAIN AUTH PROVIDER
// =============================================================================

/// Main authentication provider
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Current authenticated user (null if not authenticated)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});

/// Authentication status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authNotifierProvider).status;
});

/// Whether user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Whether authentication operation is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

/// Current authentication error message
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.errorMessage;
});

/// Whether user is a patient
final isPatientProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isPatient ?? false;
});

/// Whether user is a caregiver
final isCaregiverProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isCaregiver ?? false;
});

// =============================================================================
// ROLE SELECTION PROVIDER
// =============================================================================

/// Selected user role during onboarding
final selectedRoleProvider =
    NotifierProvider<SelectedRoleNotifier, UserRole?>(() {
  return SelectedRoleNotifier();
});

class SelectedRoleNotifier extends Notifier<UserRole?> {
  @override
  UserRole? build() => null;

  void selectRole(UserRole role) {
    state = role;
  }

  void clearRole() {
    state = null;
  }
}
