import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../models/care_team_invitation.dart';
import '../models/care_team_member.dart';

/// Care team: Firestore-backed invitations + caregiver roster, with REST proxies
/// for caregiver dashboard / reminders / PHI reads (backend Cloud SQL API).
class CareTeamApiService {
  CareTeamApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  // In-memory cache (per app process)
  static CacheEntry<List<CareTeamMember>>? _membersCache;
  static CacheEntry<List<CareTeamInvitation>>? _pendingInvitesCache;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Caregiver patient roster (`get_my_patients_for_caregiver` rows).
  Future<List<Map<String, dynamic>>> getMyPatients() async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/my-patients');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('getMyPatients failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is List) {
      return decoded
          .whereType<Object?>()
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw Exception('Unexpected getMyPatients response');
  }

  /// Flat list of reminders for one patient (each row includes `_bucket`:
  /// `today` | `upcoming` | `past` from API response).
  Future<List<Map<String, dynamic>>> getPatientReminderList(
      String patientId) async {
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/patient/$patientId');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getPatientReminderList failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    final map =
        decoded is Map<String, dynamic> ? decoded : Map<String, dynamic>.from(decoded as Map);

    final out = <Map<String, dynamic>>[];
    for (final bucket in ['today', 'upcoming', 'past']) {
      final list = map[bucket];
      if (list is! List) continue;
      for (final item in list) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          m['_bucket'] = bucket;
          out.add(m);
        }
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getPatientScannedDocs(String patientId) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/caregiver/patients/$patientId/scanned-docs');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getPatientScannedDocs failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Symptom journal (`entries`, `filters_applied`). Query fields in [data]:
  /// `date_from`, `date_to` (ISO strings), `severity_contains`.
  Future<Map<String, dynamic>> getPatientSymptomJournal(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    final qp = <String, String>{};
    final df = data['date_from'];
    final dt = data['date_to'];
    final sev = data['severity_contains']?.toString();
    if (df != null && df.toString().trim().isNotEmpty) {
      qp['date_from'] = df.toString().trim();
    }
    if (dt != null && dt.toString().trim().isNotEmpty) {
      qp['date_to'] = dt.toString().trim();
    }
    if (sev != null && sev.trim().isNotEmpty) {
      qp['severity_contains'] = sev.trim();
    }
    final base =
        '${Environment.apiBaseUrl}/api/caregiver/patients/$patientId/symptom-journal';
    final uri =
        qp.isEmpty ? Uri.parse(base) : Uri.parse(base).replace(queryParameters: qp);
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getPatientSymptomJournal failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> createPatientReminder(
      String patientId, Map<String, dynamic> payload) async {
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/patient/$patientId');
    final resp = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode(payload),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
          'createPatientReminder failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<Map<String, dynamic>> getPatientReminder(
      String patientId, String reminderId) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getPatientReminder failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> updatePatientReminder(
      String patientId, String reminderId, Map<String, dynamic> updates) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId');
    final resp = await http.put(
      uri,
      headers: await _headers(),
      body: json.encode(updates),
    );
    if (resp.statusCode != 200) {
      throw Exception(
          'updatePatientReminder failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> deletePatientReminder(
      String patientId, String reminderId) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/reminders/patient/$patientId/$reminderId');
    final resp = await http.delete(uri, headers: await _headers());
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(
          'deletePatientReminder failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Pre-registration check (`email`, optional `token`).
  Future<Map<String, dynamic>> validateCaregiverSignup(
      Map<String, dynamic> data,) async {
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/validate-caregiver-signup');
    final body = <String, dynamic>{
      'email': data['email']?.toString().trim() ?? '',
      if (data['token'] != null && data['token'].toString().trim().isNotEmpty)
        'token': data['token'].toString().trim(),
    };
    final resp = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (resp.statusCode != 200) {
      return {'ok': false, 'reason': 'network_${resp.statusCode}'};
    }
    final decoded = json.decode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

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

  String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not authenticated');
    }
    return uid;
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  CareTeamMember _memberFromApiMap(Map<String, dynamic> m) {
    return CareTeamMember.fromJson({
      'id': m['id']?.toString() ?? '',
      'patient_id': m['patient_id']?.toString() ?? '',
      'member_user_id': m['member_user_id']?.toString() ?? '',
      'full_name': m['full_name'] as String?,
      'email': m['email'] as String?,
      'role': m['role']?.toString() ?? '',
      'permission': m['permission']?.toString() ?? 'view',
      'status': m['status']?.toString() ?? 'active',
    });
  }

  CareTeamInvitation _invitationFromApiMap(Map<String, dynamic> m) {
    return CareTeamInvitation.fromJson({
      'id': m['id']?.toString() ?? '',
      'patient_id': m['patient_id']?.toString(),
      'patient_name': m['patient_name'] as String?,
      'invited_by_name': m['invited_by_name'] as String?,
      'invitee_email': m['invitee_email']?.toString() ?? '',
      'role': m['role']?.toString() ?? '',
      'permission': m['permission']?.toString() ?? 'view',
      'status': m['status']?.toString() ?? 'pending',
      'token': m['token'] as String?,
      'created_at': m['created_at']?.toString(),
      'expires_at': m['expires_at']?.toString(),
    });
  }

  /// Active care team members for the signed-in **patient** (Cloud SQL API).
  Future<List<CareTeamMember>> getCareTeam() async {
    _requireUid();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getCareTeam failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => _memberFromApiMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Patient sends email invite (Brevo + `care_team_invitations` row).
  Future<void> inviteCaregiver({
    required String email,
    required String role,
    required String permission,
  }) async {
    _requireUid();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/invite');
    final resp = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode({
        'email': email,
        'role': role,
        'permission': permission,
      }),
    );
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
          'Failed to invite caregiver: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Completes SQL-backed invite after caregiver is signed in (JWT).
  Future<void> acceptBackendCareTeamInvite({required String token}) async {
    _requireUid();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/accept');
    final resp = await http.post(
      uri,
      headers: await _headers(),
      body: json.encode({'token': token.trim()}),
    );
    if (resp.statusCode != 200) {
      throw Exception(
          'Accept invite failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> acceptInvitation({required String token}) async {
    await acceptBackendCareTeamInvite(token: token);
  }

  /// Invitations for the signed-in caregiver's **email** (Cloud SQL).
  Future<List<CareTeamInvitation>> getMyInvitations() async {
    _requireUid();
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/my-invitations');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getMyInvitations failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => _invitationFromApiMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Pending invites created by the signed-in **patient**.
  Future<List<CareTeamInvitation>> getPendingInvitations() async {
    _requireUid();
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/care-team/pending');
    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'getPendingInvitations failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = json.decode(resp.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => _invitationFromApiMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> cancelPendingInvitation({required String invitationId}) async {
    _requireUid();
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/pending/$invitationId');
    final resp = await http.delete(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'cancelPendingInvitation failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> resendPendingInvitation(String invitationId) async {
    _requireUid();
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/care-team/pending/$invitationId/resend');
    final resp = await http.post(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception(
          'resendPendingInvitation failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> updatePermission({
    required String memberId,
    required String permission,
  }) async {
    _requireUid();
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/$memberId');
    final resp = await http.patch(
      uri,
      headers: await _headers(),
      body: json.encode({'permission': permission}),
    );
    if (resp.statusCode != 200) {
      throw Exception(
          'updatePermission failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> removeMember({required String memberId}) async {
    _requireUid();
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/care-team/$memberId');
    final resp = await http.delete(uri, headers: await _headers());
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(
          'removeMember failed: ${resp.statusCode} ${resp.body}');
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
