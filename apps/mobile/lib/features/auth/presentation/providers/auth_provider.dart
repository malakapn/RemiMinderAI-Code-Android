import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/errors/role_mismatch_exception.dart';
import '../../../../core/models/user.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_notification_sync.dart';

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
  static const Duration _authOperationTimeout = Duration(seconds: 20);

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _backendApiService = ref.watch(_backendApiServiceProvider);
    _checkAuthStatus();
    return AuthState.initial();
  }

  late final AuthRepository _authRepository;
  late final BackendApiService _backendApiService;
  final NotificationService _notificationService = NotificationService();
  bool _tokenRefreshListenerAttached = false;

  /// Check authentication status on app start or resume.
  ///
  /// STRICT RULE: Never route to a role screen unless that role is
  /// explicitly confirmed (from cache OR backend). If role cannot be
  /// determined → force unauthenticated so user must re-login.
  Future<void> _checkAuthStatus() async {
    print("🔥 AuthNotifier._checkAuthStatus() started");
    state = AuthState.loading();

    try {
      final user = await _authRepository
          .getCurrentUser()
          .timeout(const Duration(seconds: 10));

      if (user == null) {
        state = AuthState.unauthenticated();
        return;
      }

      final storage = SecureStorage();
      final cachedRole = await storage.getUserRole();
      final cachedName = await storage.getFullName();

      // Step 1: Try to get role from backend (source of truth)
      AuthProfile? profile;
      String? confirmedRole;
      String? confirmedName;

      try {
        final backendProfile = await _backendApiService
            .getMyProfile()
            .timeout(const Duration(seconds: 8));
        profile = AuthProfile.fromUserProfile(backendProfile);
        confirmedRole = backendProfile.role; // normalized: 'caregiver' | 'patient'
        confirmedName = backendProfile.fullName;

        if (UserRole.tryFromString(confirmedRole) == UserRole.caregiver) {
          await _ensureCaregiverHasInviteOrTeam(backendProfile);
        }

        // Persist to cache for next cold start
        await storage.saveUserRole(confirmedRole);
        if (confirmedName != null && confirmedName.isNotEmpty) {
          await storage.saveFullName(confirmedName);
        }
        print('🔐 AuthNotifier: role confirmed from backend: $confirmedRole');
      } catch (e) {
        print('🔐 AuthNotifier: backend unreachable, trying cache: $e');

        // Step 2: Backend unavailable — use persisted cache
        if (cachedRole != null && cachedRole.isNotEmpty) {
          confirmedRole = cachedRole;
          confirmedName = cachedName;
          print('🔐 AuthNotifier: using cached role: $confirmedRole');
        }
      }

      // Step 3: If role still unknown → force re-login
      // This prevents wrong-role auto-login which is worse than showing login screen
      if (confirmedRole == null || confirmedRole.isEmpty) {
        print('🔐 AuthNotifier: role unknown — forcing re-login for safety');
        await storage.saveUserRole('');
        state = AuthState.unauthenticated();
        return;
      }

      // Map confirmed role string → enum.
      // Backend stores "user" for patients (legacy), "caregiver" for caregivers.
      final userRole =
          UserRole.tryFromString(confirmedRole) ?? UserRole.patient;

      final resolvedUser = user.copyWith(
        role: userRole,
        fullName: confirmedName ?? user.fullName,
      );

      state = AuthState.authenticated(resolvedUser, profile: profile);
      await _syncFcmTokenAndAttachRefreshListener();
      await _syncLocalReminderNotifications(resolvedUser);
    } catch (e) {
      print('🔐 AuthNotifier: _checkAuthStatus failed: $e');
      state = AuthState.unauthenticated();
    }
  }

  /// Re-runs auth resolution (e.g. pull-to-refresh on profile). The app starts at
  /// `/welcome`; there is no separate splash route.
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
      ).timeout(_authOperationTimeout);

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
          selectedRole: selectedRole).timeout(_authOperationTimeout);

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
      rethrow;
    }
  }

  /// Sign in with Google OAuth (Firebase + Web client ID; see ENV_SETUP.md).
  Future<void> signInWithGoogle({UserRole? selectedRole}) async {
    try {
      state = AuthState.loading();

      final user =
          await _authRepository
              .signInWithGoogle(selectedRole: selectedRole)
              .timeout(_authOperationTimeout);

      try {
        await _backendApiService.bootstrapUser();
        final profile = await _backendApiService.getMyProfile();
        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile));
      } catch (_) {
        // Same as email sign-in: backend optional when Firebase session is valid
        state = AuthState.authenticated(user);
      }
    } catch (e, st) {
      // Catches all errors including PlatformException from Google Sign-In.
      print('signInWithGoogle error: $e\n$st');
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _authRepository.signOut().timeout(const Duration(seconds: 8));
    } catch (e) {
      print('🔐 AuthNotifier: signOut failed: $e');
    } finally {
      // Clear cached role so next login starts fresh
      try {
        final s = SecureStorage();
        await s.saveUserRole('');
        await s.saveFullName('');
      } catch (_) {}
      // Unauthenticated — [GoRouter] sends users off protected routes to `/role-selection`.
      state = AuthState.unauthenticated();
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
      rethrow;
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
      rethrow;
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

  Future<void> _syncLocalReminderNotifications(User user) async {
    final auth = ref.read(_authServiceProvider);
    await ReminderNotificationSync.syncAfterAuth(auth, user);
  }

  Future<void> _syncFcmTokenAndAttachRefreshListener() async {
    try {
      final token = await _notificationService.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _backendApiService.registerFcmToken(
          fcmToken: token,
          deviceType: 'android',
        );
      }
    } catch (_) {
      // Keep auth flow non-blocking if FCM sync fails.
    }

    if (_tokenRefreshListenerAttached) {
      return;
    }

    _tokenRefreshListenerAttached = true;
    await _notificationService.onTokenRefresh((token) async {
      try {
        if (token.isNotEmpty) {
          await _backendApiService.registerFcmToken(
            fcmToken: token,
            deviceType: 'android',
          );
        }
      } catch (_) {
        // Do not fail app flow on background token refresh errors.
      }
    });
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
