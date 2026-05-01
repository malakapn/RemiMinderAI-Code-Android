import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'google_sign_in_config.dart';
import 'token_manager.dart';
import 'secure_storage.dart';

/// Firebase Authentication service for Email/Password and Google authentication
class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _injectedGoogleSignIn;
  GoogleSignIn? _cachedGoogleSignIn;
  final TokenManager _tokenManager;
  final SecureStorage _secureStorage;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    TokenManager? tokenManager,
    SecureStorage? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _injectedGoogleSignIn = googleSignIn,
        _tokenManager = tokenManager ?? TokenManager(SecureStorage()),
        _secureStorage = secureStorage ?? SecureStorage();

  Future<GoogleSignIn> _googleSignIn() async {
    if (_injectedGoogleSignIn != null) return _injectedGoogleSignIn!;
    _cachedGoogleSignIn ??= GoogleSignIn(
      scopes: const <String>['email', 'profile', 'openid'],
      serverClientId: await resolveGoogleWebClientId(),
    );
    return _cachedGoogleSignIn!;
  }

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
      );

      if (userCredential.user == null) {
        throw Exception('Firebase sign up failed - no user returned');
      }

      await userCredential.user!.reload();

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

      final dn = fullName?.trim();
      final display = (dn != null && dn.isNotEmpty) ? dn : 'User';

      // Create User object
      final user = User(
        id: userCredential.user!.uid, // Firebase UID
        email: email,
        role: role,
        fullName: fullName?.trim().isEmpty == true ? null : fullName?.trim(),
        displayName: display, // Temporary, will be replaced by backend
        authUid: userCredential.user!.uid,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception('Firebase sign up failed: ${e.toString()}'),
        st,
      );
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
      );

      if (userCredential.user == null) {
        throw Exception('Firebase sign in failed - no user returned');
      }

      final signedInUser = userCredential.user!;
      await signedInUser.reload();

      // Get Firebase ID token
      final idToken = await signedInUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Store Firebase token securely
      await _tokenManager.saveTokens(
          idToken, ''); // Firebase doesn't provide refresh tokens
      await _secureStorage.write('firebase_uid', signedInUser.uid);
      await _secureStorage.write('auth_provider', 'firebase');

      // Create User object
      final user = User(
        id: signedInUser.uid, // Firebase UID
        email: email,
        role: selectedRole ?? UserRole.patient, // Default role
        fullName: signedInUser.displayName,
        displayName: signedInUser.displayName ??
            "User", // Temporary, will be replaced by backend
        authUid: signedInUser.uid,
      );

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception('Firebase sign in failed: ${e.toString()}'),
        st,
      );
    }
  }

  /// Sign in with Google OAuth
  Future<User> signInWithGoogle({UserRole? selectedRole}) async {
    try {
      final googleSignIn = await _googleSignIn();

      // Start Google Sign-In process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception(
          'Missing Google ID token. Ensure Web client ID matches this Firebase project '
          '(Android: default_web_client_id from google-services.json; see ENV_SETUP.md).',
        );
      }

      // Create Firebase credential
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sign in to Firebase with Google credential
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

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
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        Exception(
          'Google Sign-In PlatformException: ${e.toString()} '
          '(code=${e.code}, message=${e.message ?? ""}, details=${e.details})',
        ),
        st,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception('Google sign-in failed: ${e.toString()}'),
        st,
      );
    }
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (_injectedGoogleSignIn != null) {
        await _injectedGoogleSignIn!.signOut();
      } else {
        final g = _cachedGoogleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile', 'openid'],
              serverClientId: await resolveGoogleWebClientId(),
            );
        await g.signOut();
      }
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

      // Sync stored JWT with Firebase — if missing/expired, refresh so
      // getCurrentUser() does not return null while a session still exists.
      var hasToken = await _tokenManager.isTokenValid();
      if (!hasToken) {
        try {
          final idToken = await firebaseUser.getIdToken(true);
          if (idToken != null) {
            await _tokenManager.saveTokens(idToken, '');
            await _secureStorage.write('firebase_uid', firebaseUser.uid);
            await _secureStorage.write('auth_provider', 'firebase');
            hasToken = true;
          }
        } catch (e) {
          print('🔥 FirebaseAuthService: Token refresh failed: $e');
        }
      }
      if (!hasToken) {
        print('🔥 FirebaseAuthService: Token is not valid after refresh');
        return null;
      }
      print('🔥 FirebaseAuthService: Token is valid, creating User object');

      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: UserRole.patient, // Default role
        fullName: firebaseUser.displayName,
        displayName: firebaseUser.displayName ??
            "User", // Temporary, will be replaced by backend
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

      final token = await firebaseUser.getIdToken();
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
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception(
          'Failed to update password. You may need to re-authenticate. '
          'Underlying error: ${e.toString()}',
        ),
        st,
      );
    }
  }

  Exception _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    final buf = StringBuffer('FirebaseAuthException: ')
      ..write(e.toString())
      ..write(', code=${e.code}')
      ..write(', message=${e.message ?? ''}');
    if (e.email != null) buf.write(', email=${e.email}');
    return Exception(buf.toString());
  }
}
