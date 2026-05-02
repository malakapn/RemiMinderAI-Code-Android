import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../models/user.dart';
import 'token_manager.dart';
import 'secure_storage.dart';

/// Firebase Authentication service for Email/Password and Google authentication
class FirebaseAuthService {
  static const Duration _firebaseAuthTimeout = Duration(seconds: 15);

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final TokenManager _tokenManager;
  final SecureStorage _secureStorage;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    TokenManager? tokenManager,
    SecureStorage? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard(),
        _tokenManager = tokenManager ?? TokenManager(SecureStorage()),
        _secureStorage = secureStorage ?? SecureStorage();

  /// Sign up a new user with Firebase Email/Password
  Future<User> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? fullName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(_firebaseAuthTimeout);

      if (userCredential.user == null) {
        throw Exception('Firebase sign up failed - no user returned');
      }

      // Get Firebase ID token
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Store Firebase token securely
      await _tokenManager.saveTokens(
          idToken, ''); // Firebase doesn't provide refresh tokens
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'firebase');

      // Create User object
      final user = User(
        id: userCredential.user!.uid, // Firebase UID
        email: email,
        role: role,
        fullName: fullName,
        displayName:
            fullName ?? "User", // Temporary, will be replaced by backend
        authUid: userCredential.user!.uid,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase signUp: $e\n$st');
      }
      throw _wrapNonFirebaseSignInError(e, 'sign up');
    }
  }

  /// Sign in with Firebase Email/Password
  Future<User> signIn(String email, String password,
      {UserRole? selectedRole}) async {
    try {
      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(_firebaseAuthTimeout);

      if (userCredential.user == null) {
        throw Exception('Firebase sign in failed - no user returned');
      }

      // Get Firebase ID token
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Store Firebase token securely
      await _tokenManager.saveTokens(
          idToken, ''); // Firebase doesn't provide refresh tokens
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'firebase');

      // Create User object
      final user = User(
        id: userCredential.user!.uid, // Firebase UID
        email: email,
        role: selectedRole ?? UserRole.patient, // Default role
        fullName: userCredential.user!.displayName,
        displayName: userCredential.user!.displayName ??
            "User", // Temporary, will be replaced by backend
        authUid: userCredential.user!.uid,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
            'Firebase signIn: FirebaseAuthException code=${e.code} message=${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Firebase signIn: $e\n$st');
      }
      throw _wrapNonFirebaseSignInError(e, 'sign in');
    }
  }

  /// Sign in with Google OAuth
  Future<User> signInWithGoogle({UserRole? selectedRole}) async {
    try {
      // Start Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Missing Google ID token');
      }

      // Create Firebase credential
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth
              .signInWithCredential(credential)
              .timeout(_firebaseAuthTimeout);

      if (userCredential.user == null) {
        throw Exception('Firebase sign-in with Google failed');
      }

      // Get Firebase ID token
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Store Firebase token securely
      await _tokenManager.saveTokens(
          idToken, ''); // Firebase doesn't provide refresh tokens
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'firebase');

      // Create User object
      final user = User(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        role: selectedRole ??
            UserRole.patient, // Use selected role or default to patient
        fullName: userCredential.user!.displayName,
        displayName: userCredential.user!.displayName ??
            "User", // Temporary, will be replaced by backend
        authUid: userCredential.user!.uid,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut(); // Also sign out from Google
      await _tokenManager.clearTokens();
      await _secureStorage.delete('firebase_uid');
      await _secureStorage.delete('auth_provider');
    } catch (e) {
      // Clear local tokens even if sign out calls fail
      await _tokenManager.clearTokens();
      await _secureStorage.delete('firebase_uid');
      await _secureStorage.delete('auth_provider');
      rethrow;
    }
  }

  /// Get current Firebase user
  Future<User?> getCurrentUser() async {
    try {
      print('🔥 FirebaseAuthService: Checking current Firebase user...');
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        print('🔥 FirebaseAuthService: No Firebase current user found');

        // Check if we have stored tokens - if so, Firebase session might not be restored yet
        final hasToken = await _tokenManager.isTokenValid();
        if (hasToken) {
          print(
              '🔥 FirebaseAuthService: Valid token found but no Firebase user - session not restored yet');
          // Try to wait a bit for Firebase to restore the session
          await Future.delayed(const Duration(milliseconds: 500));

          final firebaseUserRetry = _firebaseAuth.currentUser;
          if (firebaseUserRetry != null) {
            print(
                '🔥 FirebaseAuthService: Firebase user found after retry: ${firebaseUserRetry.email ?? firebaseUserRetry.uid}');
            return User(
              id: firebaseUserRetry.uid,
              email: firebaseUserRetry.email ?? '',
              role: UserRole.patient, // Default role
              fullName: firebaseUserRetry.displayName,
              displayName: firebaseUserRetry.displayName ??
                  "User", // Temporary, will be replaced by backend
              authUid: firebaseUserRetry.uid,
            );
          }
        }

        print(
            '🔥 FirebaseAuthService: No Firebase user and no valid token recovery');
        return null;
      }
      print(
          '🔥 FirebaseAuthService: Firebase user found: ${firebaseUser.email ?? firebaseUser.uid}');

      // Refresh the token from Firebase (auto-refreshes if expired)
      final freshToken = await firebaseUser.getIdToken();
      if (freshToken == null) {
        print('🔥 FirebaseAuthService: Could not refresh token');
        return null;
      }
      await _tokenManager.saveTokens(freshToken, '');
      print('🔥 FirebaseAuthService: Token refreshed, creating User object');

      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: UserRole.patient,
        fullName: firebaseUser.displayName,
        displayName: firebaseUser.displayName ?? "User",
        authUid: firebaseUser.uid,
      );
    } catch (e) {
      print('🔥 FirebaseAuthService: Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated with Firebase
  Future<bool> isAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Get Firebase ID token
  Future<String?> getIdToken() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final token = await firebaseUser.getIdToken().timeout(
            const Duration(seconds: 6),
          );
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Reset password via Firebase
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update password (requires recent authentication)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception(
          'Failed to update password. You may need to re-authenticate.');
    }
  }

  Exception _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('An account with this email already exists');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'user-not-found':
        return Exception('No account found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return Exception('Invalid email or password');
      case 'user-disabled':
        return Exception('This account has been disabled');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later');
      case 'network-request-failed':
        return Exception(
            'No connection to Firebase (reCAPTCHA / Google services). Check internet, turn off VPN or system HTTP proxy, and try another network.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }

  /// Maps platform-level failures (e.g. RecaptchaCallWrapper) to a clear error.
  Exception _wrapNonFirebaseSignInError(Object e, String action) {
    final msg = e.toString().toLowerCase();
    final isLikelyNetworkOrRecaptcha = msg.contains('network error') ||
        msg.contains('unreachable') ||
        msg.contains('failed to connect') ||
        msg.contains('timeout') ||
        msg.contains('recaptcha') ||
        msg.contains('internal error has occurred');
    if (isLikelyNetworkOrRecaptcha) {
      return Exception(
          'Firebase could not complete $action (reCAPTCHA / device network to Google). '
          'On emulator: use an image with Google Play, clear Settings → network proxy, '
          'or run: adb shell settings delete global http_proxy. '
          'Then retry on Wi-Fi without VPN, or a physical device with updated Play services. '
          'Original: $e');
    }
    return Exception('Firebase $action failed: $e');
  }
}
