import 'package:equatable/equatable.dart';

/// User roles in the MediMinder system
enum UserRole {
  patient,
  caregiver;

  /// Convert string to enum
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'patient':
      case 'user': // Database uses 'user' but we map it to patient
        return UserRole.patient;
      case 'caregiver':
        return UserRole.caregiver;
      default:
        throw ArgumentError('Invalid user role: $value');
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.caregiver:
        return 'Caregiver';
    }
  }

  /// Description for UI
  String get description {
    switch (this) {
      case UserRole.patient:
        return 'Manage your own medications, appointments, and health records';
      case UserRole.caregiver:
        return 'Help manage medications and care for family members or patients';
    }
  }
}

/// User model representing authenticated users
class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String _displayName; // Backend-resolved display name
  final UserRole role;
  final DateTime? createdAt;
  final String? authUid;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    required String displayName,
    required this.role,
    this.createdAt,
    this.authUid,
  }) : _displayName = displayName;

  /// Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      authUid: json['auth_uid'] as String?,
    );
  }

  /// Convert User to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'created_at': createdAt?.toIso8601String(),
      'auth_uid': authUid,
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    String? authUid,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      authUid: authUid ?? this.authUid,
    );
  }

  /// Get display name for UI (from backend)
  String get displayName => _displayName;

  /// Check if user is a patient
  bool get isPatient => role == UserRole.patient;

  /// Check if user is a caregiver
  bool get isCaregiver => role == UserRole.caregiver;

  @override
  List<Object?> get props =>
      [id, email, fullName, _displayName, role, createdAt, authUid];

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: ${role.displayName}, fullName: $fullName)';
  }
}

/// Profile model for /api/users/me response
class UserProfile {
  final String? fullName;
  final String email;
  final String? phone;
  final String role; // "patient" | "caregiver"

  const UserProfile({
    this.fullName,
    required this.email,
    this.phone,
    required this.role,
  });

  /// Create UserProfile from JSON (API response)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
    );
  }

  @override
  String toString() {
    return 'UserProfile(email: $email, fullName: $fullName, role: $role, phone: $phone)';
  }
}
