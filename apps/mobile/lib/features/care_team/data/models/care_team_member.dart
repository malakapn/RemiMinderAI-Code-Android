class CareTeamMember {
  final String id;
  final String patientId;
  final String memberUserId;
  final String? fullName;
  final String? email;
  final String role;
  final String permission;
  final String status;

  const CareTeamMember({
    required this.id,
    required this.patientId,
    required this.memberUserId,
    this.fullName,
    this.email,
    required this.role,
    required this.permission,
    required this.status,
  });

  factory CareTeamMember.fromJson(Map<String, dynamic> json) {
    return CareTeamMember(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      memberUserId: json['member_user_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
      permission: json['permission'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'member_user_id': memberUserId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'permission': permission,
      'status': status,
    };
  }

  CareTeamMember copyWith({
    String? permission,
    String? fullName,
    String? role,
    String? status,
  }) {
    return CareTeamMember(
      id: id,
      patientId: patientId,
      memberUserId: memberUserId,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role ?? this.role,
      permission: permission ?? this.permission,
      status: status ?? this.status,
    );
  }
}
