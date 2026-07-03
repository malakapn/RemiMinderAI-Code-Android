class CareTeamInvitation {
  final String id;
  final String? patientId;
  final String? patientName;
  final String inviteeEmail;
  final String role;
  final String permission;
  final String status;
  final String? token;
  final String? createdAt;

  const CareTeamInvitation({
    required this.id,
    this.patientId,
    this.patientName,
    required this.inviteeEmail,
    required this.role,
    required this.permission,
    required this.status,
    this.token,
    this.createdAt,
  });

  factory CareTeamInvitation.fromJson(Map<String, dynamic> json) {
    return CareTeamInvitation(
      id: json['id'] as String,
      patientId: json['patient_id'] as String?,
      patientName: json['patient_name'] as String?,
      inviteeEmail: json['invitee_email'] as String,
      role: json['role'] as String,
      permission: json['permission'] as String,
      status: json['status'] as String,
      token: json['token'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'invitee_email': inviteeEmail,
      'role': role,
      'permission': permission,
      'status': status,
      'token': token,
      'created_at': createdAt,
    };
  }
}
