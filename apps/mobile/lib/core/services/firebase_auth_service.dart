import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../config/environment.dart';
import '../models/user.dart';
import 'google_sign_in_config.dart';
import 'token_manager.dart';
import 'secure_storage.dart';

class FirebaseAuthService {
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
        // serverClientId is required on Android so Google returns an ID token
        // that Firebase Auth can exchange. Without it, Indian (and other)
        // Android users often see Missing Google ID token / sign_in_failed.
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: Environment.googleWebClientId.isNotEmpty
                  ? Environment.googleWebClientId
                  : null,
            ),
        _tokenManager = tokenManager ?? TokenManager(SecureStorage()),
        _secureStorage = secureStorage ?? SecureStorage();

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
      if (userCredential.user == null) throw Exception('Firebase sign up failed');
      await userCredential.user!.reload();
      await userCredential.user!.sendEmailVerification();
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      await _tokenManager.saveTokens(idToken, '');
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'firebase');
      return User(
        id: userCredential.user!.uid,
        email: email,
        role: role,
        fullName: fullName,
        displayName: fullName ?? "",
        authUid: userCredential.user!.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw Exception('Firebase sign up failed: $e');
    }
  }

  Future<User> signIn(String email, String password, {UserRole? selectedRole}) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      if (userCredential.user == null) throw Exception('Firebase sign in failed');
      final signedInUser = userCredential.user!;
      await signedInUser.reload();
      // Only enforce email verification for accounts created after Jul 29, 2026
      final createdAt = signedInUser.metadata.creationTime;
      final verificationCutoff = DateTime(2026, 7, 29);
      if (!signedInUser.emailVerified && createdAt != null && createdAt.isAfter(verificationCutoff)) {
        throw Exception("EMAIL_NOT_VERIFIED");
      }
      final idToken = await signedInUser.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      await _tokenManager.saveTokens(idToken, '');
      await _secureStorage.write('firebase_uid', signedInUser.uid);
      await _secureStorage.write('auth_provider', 'firebase');
      final emailRole = selectedRole ?? UserRole.patient;
      final roleStr = emailRole == UserRole.caregiver ? 'caregiver' : 'patient';
      await _secureStorage.write('user_role', roleStr);
      if (kDebugMode) {
        print('🔐 FirebaseAuthService: saved user_role=$roleStr to SecureStorage');
      }
      return User(
        id: signedInUser.uid,
        email: email,
        role: emailRole,
        fullName: signedInUser.displayName,
        displayName: signedInUser.displayName ?? "",
        authUid: signedInUser.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw Exception('Firebase sign in failed: $e');
    }
  }

  Future<User> signInWithGoogle({UserRole? selectedRole}) async {
    try {
      // Prefer native default_web_client_id on Android when available.
      final webClientId = await resolveGoogleWebClientId();
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw Exception('Missing Google ID token');
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) throw Exception('Firebase sign-in with Google failed');
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      await _tokenManager.saveTokens(idToken, '');
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'firebase');
      final role = selectedRole ?? UserRole.patient;
      await _secureStorage.write('user_role', role == UserRole.caregiver ? 'caregiver' : 'patient');
      return User(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        role: role,
        fullName: userCredential.user!.displayName,
        displayName: userCredential.user!.displayName ?? "",
        authUid: userCredential.user!.uid,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == 'SIGN_IN_CANCELED' || e.code == 'sign_in_cancelled') {
        throw Exception('Google sign-in cancelled');
      }
      throw Exception('Google Sign-In failed. Please ensure your Google account is configured correctly.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<User> signInWithApple({UserRole? selectedRole}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oAuthProvider = firebase_auth.OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) throw Exception('Firebase sign-in with Apple failed');
      final fullName = appleCredential.givenName != null
          ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim()
          : userCredential.user!.displayName;
      if (fullName != null && fullName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(fullName);
      }
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) throw Exception('Failed to get Firebase ID token');
      await _tokenManager.saveTokens(idToken, '');
      await _secureStorage.write('firebase_uid', userCredential.user!.uid);
      await _secureStorage.write('auth_provider', 'apple');
      final appleRole = selectedRole ?? UserRole.patient;
      await _secureStorage.write('user_role', appleRole == UserRole.caregiver ? 'caregiver' : 'patient');
      // FIX: Apple only sends email on first sign-in — persist it now
      final appleEmail = (userCredential.user!.email != null && userCredential.user!.email!.isNotEmpty)
          ? userCredential.user!.email!
          : (appleCredential.email ?? '');
      if (appleEmail.isNotEmpty) {
        await _secureStorage.write('apple_user_email', appleEmail);
      }
      final storedEmail = appleEmail.isNotEmpty
          ? appleEmail
          : (await _secureStorage.read('apple_user_email') ?? '');
      return User(
        id: userCredential.user!.uid,
        email: storedEmail,
        role: selectedRole ?? UserRole.patient,
        fullName: fullName,
        displayName: (fullName != null && fullName.isNotEmpty) ? fullName : storedEmail,
        authUid: userCredential.user!.uid,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple sign-in cancelled');
      }
      throw Exception('Apple Sign-In failed: ${e.message}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _tokenManager.clearTokens();
      await _secureStorage.delete('firebase_uid');
      await _secureStorage.delete('auth_provider');
      await _secureStorage.delete('apple_user_email');
    } catch (e) {
      await _tokenManager.clearTokens();
      await _secureStorage.delete('firebase_uid');
      await _secureStorage.delete('auth_provider');
      await _secureStorage.delete('apple_user_email');
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      if (kDebugMode) {
        print('🔥 FirebaseAuthService: Checking current Firebase user...');
      }
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseAuthService: No Firebase current user found');
        }
        final hasToken = await _tokenManager.isTokenValid();
        if (hasToken) {
          await Future.delayed(const Duration(milliseconds: 500));
          final firebaseUserRetry = _firebaseAuth.currentUser;
          if (firebaseUserRetry != null) {
            final retryStoredEmail = (firebaseUserRetry.email != null && firebaseUserRetry.email!.isNotEmpty)
                ? firebaseUserRetry.email!
                : (await _secureStorage.read('apple_user_email') ?? '');
            final retrySavedRole = await _secureStorage.read('user_role');
            return User(
              id: firebaseUserRetry.uid,
              email: retryStoredEmail,
              role: retrySavedRole == 'caregiver' ? UserRole.caregiver : UserRole.patient,
              fullName: firebaseUserRetry.displayName,
              displayName: firebaseUserRetry.displayName ?? "",
              authUid: firebaseUserRetry.uid,
            );
          }
        }
        if (kDebugMode) {
          print('🔥 FirebaseAuthService: No Firebase user and no valid token recovery');
        }
        return null;
      }
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
          if (kDebugMode) {
            print('🔥 FirebaseAuthService: Token refresh failed: $e');
          }
        }
      }
      if (!hasToken) return null;
      // FIX: fall back to stored Apple email if Firebase email is empty
      final savedRole = await _secureStorage.read('user_role');
      if (kDebugMode) {
        print('🔐 FirebaseAuthService: getCurrentUser read user_role=$savedRole');
      }
      final mainStoredEmail = (firebaseUser.email != null && firebaseUser.email!.isNotEmpty)
          ? firebaseUser.email!
          : (await _secureStorage.read('apple_user_email') ?? '');
      return User(
        id: firebaseUser.uid,
        email: mainStoredEmail,
        role: savedRole == 'caregiver' ? UserRole.caregiver : UserRole.patient,
        fullName: firebaseUser.displayName,
        displayName: firebaseUser.displayName ?? "",
        authUid: firebaseUser.uid,
      );
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseAuthService: Error getting current user: $e');
      }
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getIdToken() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      // Force refresh to avoid sending expired tokens
      return await firebaseUser.getIdToken(true);
    } catch (e) {
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _firebaseAuth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password. You may need to re-authenticate.');
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
      case 'invalid-credential':
        return Exception('Invalid email or password. Please check your credentials and try again.');
      case 'user-not-found':
        return Exception('No account found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'user-disabled':
        return Exception('This account has been disabled');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please try again later');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
