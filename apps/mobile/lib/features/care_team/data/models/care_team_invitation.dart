class CareTeamInvitation {
  final String id;
  final String? patientId;
  final String? patientName;
  final String? invitedByName;
  final String inviteeEmail;
  final String role;
  final String permission;
  final String status;
  final String? token;
  final String? createdAt;
  final String? expiresAt;

  const CareTeamInvitation({
    required this.id,
    this.patientId,
    this.patientName,
    this.invitedByName,
    required this.inviteeEmail,
    required this.role,
    required this.permission,
    required this.status,
    this.token,
    this.createdAt,
    this.expiresAt,
  });

  factory CareTeamInvitation.fromJson(Map<String, dynamic> json) {
    return CareTeamInvitation(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString(),
      patientName: json['patient_name'] as String?,
      invitedByName: json['invited_by_name'] as String?,
      inviteeEmail: json['invitee_email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      permission: json['permission']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      token: json['token'] as String?,
      createdAt: json['created_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'invited_by_name': invitedByName,
      'invitee_email': inviteeEmail,
      'role': role,
      'permission': permission,
      'status': status,
      'token': token,
      'created_at': createdAt,
      'expires_at': expiresAt,
    };
  }
}
