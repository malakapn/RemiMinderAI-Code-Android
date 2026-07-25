import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/models/user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/services/subscription_api_service.dart';
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

final _subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  final authService = ref.watch(_authServiceProvider);
  return SubscriptionApiService(authService: authService);
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
    _subscriptionApiService = ref.watch(_subscriptionApiServiceProvider);
    _checkAuthStatus();
    return AuthState.initial();
  }

  late final AuthRepository _authRepository;
  late final BackendApiService _backendApiService;
  late final SubscriptionApiService _subscriptionApiService;
  final NotificationService _notificationService = NotificationService();
  bool _tokenRefreshListenerAttached = false;

  /// Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    if (kDebugMode) {
      print("🔥 AuthNotifier._checkAuthStatus() started");
    }
    state = AuthState.loading();

    try {
      // Check if authentication services are available with timeout
      final user = await _authRepository
          .getCurrentUser()
          .timeout(const Duration(seconds: 10));
      if (user != null) {
        // Set authenticated with saved role - don't load profile here
        // Profile is loaded during sign-in flow
        state = AuthState.authenticated(user);
        await _syncSubscriptionStatus(user);
        await _syncFcmTokenAndAttachRefreshListener();
        await _syncReminderNotifications(user);
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
    if (kDebugMode) {
      print("🔥 AuthNotifier.initialize() called (status: ${state.status})");
    }
    if (state.status == AuthStatus.initial) {
      await _checkAuthStatus();
    }
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
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
      );

      try {
        await _backendApiService.bootstrapUser(fullName: fullName);
        await _saveUserToFirestore(user);
        final profile = await _backendApiService.getMyProfile();

        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile));
        await _syncSubscriptionStatus(user);
        await AnalyticsService.instance.trialStarted();
        await _syncFcmTokenAndAttachRefreshListener();
        await _syncReminderNotifications(user);
      } catch (_) {
        await _authRepository.signOut();
        const msg =
            'Account created, but we could not finish setup. Please sign in with your email and password.';
        state = AuthState.error(msg);
        throw Exception(msg);
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
      final user = await _authRepository.signIn(email, password,
          selectedRole: selectedRole);

      try {
        await _backendApiService.bootstrapUser();
        await _saveUserToFirestore(user);
        final profile = await _backendApiService.getMyProfile();
        final resolvedRole = selectedRole != null
            ? (selectedRole == UserRole.caregiver ? 'caregiver' : 'patient')
            : profile.role;
        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile).copyWith(role: resolvedRole));
        await _syncSubscriptionStatus(user);
      } catch (e, st) {
        debugPrint('🔴 signIn: backend profile load failed (non-fatal): $e');
        state = AuthState.authenticated(user);
      }
      await _syncFcmTokenAndAttachRefreshListener();
      await _syncReminderNotifications(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle({UserRole? selectedRole}) async {
    state = AuthState.loading();

    try {
      // Ensure SHA-1 debug fingerprint is registered in Firebase Console for this to work
      final user =
          await _authRepository.signInWithGoogle(selectedRole: selectedRole);

      // Bootstrap user in backend
      await _backendApiService.bootstrapUser();
      await _saveUserToFirestore(user);

      // Fetch user profile from backend
      final profile = await _backendApiService.getMyProfile();

      // Always honour the role the user selected — never let backend override it
      final resolvedRole = selectedRole != null
          ? (selectedRole == UserRole.caregiver ? 'caregiver' : 'patient')
          : profile.role;

      state = AuthState.authenticated(user,
          profile: AuthProfile.fromUserProfile(profile).copyWith(role: resolvedRole));
      await _syncSubscriptionStatus(user);
      await _syncFcmTokenAndAttachRefreshListener();
      await _syncReminderNotifications(user);
    } catch (e, st) {
      debugPrint('🔴 signInWithGoogle: backend profile load failed: $e');
      debugPrint('$st');
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


  /// Sign in with Apple
  Future<void> signInWithApple({UserRole? selectedRole}) async {
    state = AuthState.loading();
    try {
      final user = await _authRepository.signInWithApple(selectedRole: selectedRole);
      try {
        await _backendApiService.bootstrapUser();
        await _saveUserToFirestore(user);
        final profile = await _backendApiService.getMyProfile();
        // Preserve selected role — backend may default to 'patient' for new users
        final resolvedRole = selectedRole != null
            ? (selectedRole == UserRole.caregiver ? 'caregiver' : 'patient')
            : profile.role;
        state = AuthState.authenticated(user,
            profile: AuthProfile.fromUserProfile(profile).copyWith(role: resolvedRole));
        await _syncSubscriptionStatus(user);
      } catch (backendError) {
        debugPrint('Apple SignIn: backend non-fatal: \$backendError');
        state = AuthState.authenticated(user);
      }
      await _syncFcmTokenAndAttachRefreshListener();
      await _syncReminderNotifications(user);
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        state = AuthState.unauthenticated();
      } else {
        state = AuthState.error(e.toString());
      }
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (kDebugMode) {
      print('🔐 AuthNotifier: signOut() called');
    }

    try {
      if (kDebugMode) {
        print('🔐 AuthNotifier: calling _authRepository.signOut()');
      }
      await _authRepository.signOut();
      await RevenueCatService.instance.logOut();
      if (kDebugMode) {
        print(
            '🔐 AuthNotifier: Firebase signOut completed, setting unauthenticated');
      }
      state = AuthState.unauthenticated();
      if (kDebugMode) {
        print('🔐 AuthNotifier: AuthState set to unauthenticated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔐 AuthNotifier: signOut failed: $e');
      }
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

  /// Save user profile to Firestore so Cloud Functions can look up name/email
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final data = <String, dynamic>{};
      final email = user.email ?? '';
      final name = (user.displayName != null && user.displayName!.isNotEmpty && user.displayName != 'User')
          ? user.displayName!
          : '';
      // Always save email
      if (email.isNotEmpty) data['email'] = email;
      // Save display name — fall back to email prefix if no real name
      final effectiveName = name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@').first : '');
      if (effectiveName.isNotEmpty) {
        data['displayName'] = effectiveName;
        data['fullName'] = effectiveName;
      }
      if (data.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Non-fatal: failed to save user to Firestore: \$e');
    }
  }

  Future<void> _syncReminderNotifications(User user) async {
    try {
      final authService = ref.read(_authServiceProvider);
      await ReminderNotificationSync.syncAfterAuth(authService, user);
    } catch (e) {
      debugPrint('Reminder notification sync failed (non-fatal): $e');
    }
  }

  Future<void> _syncFcmTokenAndAttachRefreshListener() async {
    try {
      final token = await _notificationService.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _backendApiService.registerFcmToken(
          fcmToken: token,
          deviceType: Platform.isIOS ? 'ios' : 'android',
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
            deviceType: Platform.isIOS ? 'ios' : 'android',
          );
        }
      } catch (_) {
        // Do not fail app flow on background token refresh errors.
      }
    });
  }

  Future<void> _syncSubscriptionStatus(User user) async {
    try {
      final firebaseUid = user.authUid ?? user.id;
      if (firebaseUid.isEmpty) return;

      final customerInfo = await RevenueCatService.instance.logIn(firebaseUid);
      final premium = RevenueCatService.instance.hasPremium(customerInfo);
      final productId = RevenueCatService.instance.activeProductId(customerInfo);
      final status = await _subscriptionApiService.syncRevenueCatStatus(
        premium: premium,
        appUserId: firebaseUid,
        productId: productId,
        source: Platform.isIOS ? 'app_store' : 'play_store',
      );

      final profile = state.profile;
      final currentUser = state.user;
      if (profile == null || currentUser == null) return;

      state = AuthState.authenticated(
        currentUser,
        profile: profile.copyWith(
          plan: status.plan.apiValue,
          trialStartDate: status.trialStartDate,
          trialEndDate: status.trialEndDate,
          trialDaysRemaining: status.trialDaysRemaining,
          summaryCount: status.summaryCount,
          remivoxInteractionCount: status.remivoxInteractionCount,
          subscriptionSource: status.subscriptionSource,
        ),
      );
    } catch (e) {
      debugPrint('Subscription sync failed (non-fatal): $e');
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

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).profile?.isPremium ?? false;
});

final userPlanProvider = Provider<String>((ref) {
  return ref.watch(authNotifierProvider).profile?.normalizedPlan ?? 'FREE';
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
