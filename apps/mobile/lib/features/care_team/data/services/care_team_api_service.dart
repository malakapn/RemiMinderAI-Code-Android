import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../models/care_team_invitation.dart';
import '../models/care_team_member.dart';

class CareTeamApiService {
  final AuthService _authService;
  static const Duration _requestTimeout = Duration(seconds: 8);

  CareTeamApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  // In-memory cache (per app process)
  static CacheEntry<List<CareTeamMember>>? _membersCache;
  static CacheEntry<List<CareTeamInvitation>>? _pendingInvitesCache;

  static List<CareTeamMember>? getCachedMembers() {
    return _membersCache?.data;
  }

  static List<CareTeamInvitation>? getCachedPendingInvites() {
    return _pendingInvitesCache?.data;
  }

  static void setCachedMembers(List<CareTeamMember> members) {
    _membersCache = CacheEntry(members, DateTime.now());
  }

  static void setCachedPendingInvites(List<CareTeamInvitation> invites) {
    _pendingInvitesCache = CacheEntry(invites, DateTime.now());
  }

  Future<String> _getAccessToken() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }
    return accessToken;
  }

  Future<List<CareTeamMember>> getCareTeam() async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => CareTeamMember.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
        'Failed to load care team: ${response.statusCode} - ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getMyPatients() async {
    final accessToken = await _getAccessToken();
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/my-patients');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception(
        'Failed to load patients: ${response.statusCode} - ${response.body}');
  }

  /// Caregiver read-only symptom lines from visit AI summaries (newest first).
  Future<Map<String, dynamic>> getPatientSymptomJournal(
    String patientId, {
    DateTime? dateFrom,
    DateTime? dateTo,
    String? severityContains,
    int limit = 200,
  }) async {
    final accessToken = await _getAccessToken();
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final q = <String, String>{'limit': '$limit'};
    if (dateFrom != null) {
      q['date_from'] = ymd(dateFrom);
    }
    if (dateTo != null) {
      q['date_to'] = ymd(dateTo);
    }
    if (severityContains != null && severityContains.trim().isNotEmpty) {
      q['severity'] = severityContains.trim();
    }
    final uri = Uri.parse(
            '${Environment.apiBaseUrl}/api/care-team/patients/$patientId/symptoms')
        .replace(queryParameters: q);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);
    if (response.statusCode == 200) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      final returned = map['patient_id']?.toString();
      if (returned != null &&
          returned.isNotEmpty &&
          returned != patientId &&
          returned.toLowerCase() != patientId.toLowerCase()) {
        throw Exception(
          'Symptom journal response patient_id does not match request '
          '(integrity check).',
        );
      }
      return map;
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Not authorized to view this patient’s symptom log. '
        'They must be on your care team.',
      );
    }
    if (response.statusCode == 401) {
      throw Exception('Authentication required to load symptom journal.');
    }
    throw Exception(
        'Failed to load symptom journal: ${response.statusCode} - ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getPatientScannedDocs(
    String patientId,
  ) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/caregiver/patients/$patientId/scanned-docs',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.whereType<Map<String, dynamic>>().toList();
    }

    throw Exception(
      'Failed to load patient scanned docs: ${response.statusCode} - ${response.body}',
    );
  }

  /// Caregiver: patient reminders grouped like the patient app (`today`, `upcoming`, `past`).
  Future<Map<String, dynamic>> getPatientReminderList(String patientId) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/reminders/patient/$patientId');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'Failed to load reminders: ${response.statusCode} - ${response.body}');
  }

  /// Caregiver: single reminder for a patient (roster-scoped).
  Future<Map<String, dynamic>> getPatientReminder(
    String patientId,
    String reminderId,
  ) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to load reminder: ${response.statusCode} - ${response.body}',
    );
  }

  /// Caregiver: update fields on a patient's reminder (see backend ReminderUpdate).
  Future<Map<String, dynamic>> updatePatientReminder(
    String patientId,
    String reminderId,
    Map<String, dynamic> body,
  ) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId',
    );
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to update reminder: ${response.statusCode} - ${response.body}',
    );
  }

  /// Caregiver: create a reminder for a patient (same body as POST /reminders for patient).
  Future<Map<String, dynamic>> createPatientReminder(
    String patientId,
    Map<String, dynamic> body,
  ) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/reminders/patient/$patientId',
    );
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      'Failed to create reminder: ${response.statusCode} - ${response.body}',
    );
  }

  /// Caregiver: delete a patient's reminder.
  Future<void> deletePatientReminder(String patientId, String reminderId) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId',
    );
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 204) return;
    throw Exception(
      'Failed to delete reminder: ${response.statusCode} - ${response.body}',
    );
  }

  Future<void> inviteCaregiver({
    required String email,
    required String role,
    required String permission,
  }) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/invite');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'role': role,
        'permission': permission,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to invite caregiver: ${response.statusCode} - ${response.body}');
    }
  }

  /// Unauthenticated: caregiver signup gate (pending invite for email).
  Future<Map<String, dynamic>> validateCaregiverSignup({
    required String email,
    String? token,
  }) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/public/validate-caregiver-signup');
    final body = <String, dynamic>{'email': email};
    if (token != null && token.trim().isNotEmpty) {
      body['token'] = token.trim();
    }
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return {
        'ok': data['ok'] == true,
        'reason': data['reason']?.toString() ?? 'unknown',
      };
    }
    return {'ok': false, 'reason': 'http_${response.statusCode}'};
  }

  Future<void> acceptInvitation({
    required String token,
    String consentVersion = 'phase1-v1',
  }) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/accept');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
        'consent_version': consentVersion,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to accept invitation: ${response.statusCode} - ${response.body}');
    }
  }

  /// Caregiver declines an invitation they received (not patient cancel).
  Future<void> declineMyInvitation(String invitationId) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/care-team/my-invitations/$invitationId/decline',
    );
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to decline invitation: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<CareTeamInvitation>> getMyInvitations() async {
    final accessToken = await _getAccessToken();
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/my-invitations');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) =>
              CareTeamInvitation.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
        'Failed to load invitations: ${response.statusCode} - ${response.body}');
  }

  Future<List<CareTeamInvitation>> getPendingInvitations() async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/pending');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) =>
              CareTeamInvitation.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
        'Failed to load pending invitations: ${response.statusCode} - ${response.body}');
  }

  Future<void> cancelPendingInvitation({required String invitationId}) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/pending/$invitationId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to cancel invitation: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> resendPendingInvitation(String invitationId) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/pending/$invitationId/resend');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to resend invitation: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updatePermission({
    required String memberId,
    required String permission,
  }) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/$memberId');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'permission': permission}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to update permission: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> removeMember({required String memberId}) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/$memberId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to remove member: ${response.statusCode} - ${response.body}');
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
