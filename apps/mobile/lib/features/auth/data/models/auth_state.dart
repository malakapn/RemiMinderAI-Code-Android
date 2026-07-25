import 'package:equatable/equatable.dart';
import '../../../../core/models/user.dart';

/// User profile information from backend
class AuthProfile {
  final String? fullName;
  final String email;
  final String? phone;
  final String role; // "patient" | "caregiver"
  final String plan; // "TRIAL" | "FREE" | "PREMIUM" | "EXPIRED"
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final int trialDaysRemaining;
  final int summaryCount;
  final int remivoxInteractionCount;
  final String? subscriptionSource;

  const AuthProfile({
    this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.plan = "FREE",
    this.trialStartDate,
    this.trialEndDate,
    this.trialDaysRemaining = 0,
    this.summaryCount = 0,
    this.remivoxInteractionCount = 0,
    this.subscriptionSource,
  });

  factory AuthProfile.fromUserProfile(UserProfile profile) {
    return AuthProfile(
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      role: profile.role,
      plan: profile.plan,
      trialStartDate: profile.trialStartDate,
      trialEndDate: profile.trialEndDate,
      trialDaysRemaining: profile.trialDaysRemaining,
      summaryCount: profile.summaryCount,
      remivoxInteractionCount: profile.remivoxInteractionCount,
      subscriptionSource: profile.subscriptionSource,
    );
  }

  AuthProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? plan,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    int? trialDaysRemaining,
    int? summaryCount,
    int? remivoxInteractionCount,
    String? subscriptionSource,
  }) {
    return AuthProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      summaryCount: summaryCount ?? this.summaryCount,
      remivoxInteractionCount:
          remivoxInteractionCount ?? this.remivoxInteractionCount,
      subscriptionSource: subscriptionSource ?? this.subscriptionSource,
    );
  }

  String get normalizedPlan => plan.trim().toUpperCase();
  bool get isTrial => normalizedPlan == 'TRIAL';
  bool get isFree => normalizedPlan == 'FREE';
  bool get isPremium => normalizedPlan == 'PREMIUM';
  bool get isExpired => normalizedPlan == 'EXPIRED';
}

/// Authentication status enum
enum AuthStatus {
  initial, // App starting up
  loading, // Authentication operation in progress
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
  error, // Authentication error occurred
}

/// Authentication state for the app
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final AuthProfile? profile; // Backend profile data
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
  });

  /// Create initial state
  factory AuthState.initial() => const AuthState();

  /// Create loading state
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  /// Create authenticated state
  factory AuthState.authenticated(User user, {AuthProfile? profile}) =>
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
        profile: profile,
      );

  /// Create unauthenticated state
  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  /// Create error state
  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  /// Check if user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Check if operation is loading
  bool get isLoading => status == AuthStatus.loading;

  /// Check if there's an error
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  /// Create a copy with updated fields
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    AuthProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, profile, errorMessage];

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.email}, profile: ${profile?.email}, error: $errorMessage)';
  }
}
