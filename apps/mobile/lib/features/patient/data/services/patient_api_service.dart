import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/summary_item.dart';
import 'visit_summary_gemini_prompt.dart';
// import '../../models/models.dart'; // TODO: Re-enable when patient domain models are implemented

class PatientApiService {
  final String baseUrl;
  final String authToken;

  PatientApiService({
    required this.baseUrl,
    required this.authToken,
  });

  // In-memory cache (per app process)
  static CacheEntry<List<SummaryItem>>? _summariesCache;
  static CacheEntry<Map<String, dynamic>>? _latestStatusCache;

  static List<SummaryItem>? getCachedSummaries() {
    return _summariesCache?.data;
  }

  static Map<String, dynamic>? getCachedLatestVisitStatus() {
    return _latestStatusCache?.data;
  }

  static void setCachedSummaries(List<SummaryItem> summaries) {
    _summariesCache = CacheEntry(summaries, DateTime.now());
  }

  static void invalidateSummariesCache() {
    _summariesCache = null;
  }

  static void setCachedLatestVisitStatus(Map<String, dynamic> status) {
    _latestStatusCache = CacheEntry(status, DateTime.now());
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  // TODO: Re-enable when patient domain models are implemented
  /*
  // Medications
  Future<List<Medication>> getMedications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/medications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Medication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load medications');
    }
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient/medications'),
      headers: _headers,
      body: json.encode(medication.toJson()),
    );

    if (response.statusCode == 201) {
      return Medication.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create medication');
    }
  }
  */

  // TODO: Re-enable when patient domain models are implemented
  /*
  // Reminders
  Future<List<Reminder>> getReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/reminders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient/reminders'),
      headers: _headers,
      body: json.encode(reminder.toJson()),
    );

    if (response.statusCode == 201) {
      return Reminder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create reminder');
    }
  }

  Future<void> markReminderCompleted(String reminderId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/patient/reminders/$reminderId/complete'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark reminder as completed');
    }
  }
  */

  // TODO: Re-enable when patient domain models are implemented
  /*
  // Appointments
  Future<List<Appointment>> getAppointments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/appointments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient/appointments'),
      headers: _headers,
      body: json.encode(appointment.toJson()),
    );

    if (response.statusCode == 201) {
      return Appointment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create appointment');
    }
  }
  */

  // TODO: Re-enable when patient domain models are implemented
  /*
  // Visits
  Future<List<Visit>> getVisits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/visits'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Visit.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load visits');
    }
  }

  Future<Visit> createVisit(Visit visit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient/visits'),
      headers: _headers,
      body: json.encode(visit.toJson()),
    );

    if (response.statusCode == 201) {
      return Visit.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create visit');
    }
  }
  */

  // Visit Summary (AI-generated)
  Future<Map<String, dynamic>> getVisitSummary(
    String visitId, {
    String? patientId,
  }) async {
    final uri = _visitUri('/api/visits/$visitId/summary', patientId: patientId);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch visit summary: ${response.statusCode}');
    }
  }

  // Visit Structured Summary (AI-generated)
  Future<Map<String, dynamic>> getVisitSummaryStructured(
    String visitId, {
    String? patientId,
  }) async {
    final uri =
        _visitUri('/api/visits/$visitId/summary-structured', patientId: patientId);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch structured visit summary: ${response.statusCode}');
    }
  }

  Uri _visitUri(String path, {String? patientId}) {
    final uri = Uri.parse('$baseUrl$path');
    if (patientId == null || patientId.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {'patient_id': patientId});
  }

  // Summaries List
  Future<List<SummaryItem>> getSummaries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/summaries'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SummaryItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch summaries: ${response.statusCode}');
    }
  }

  /// Re-queue STT + summary for a visit (e.g. after a failed or stuck job).
  Future<void> triggerVisitAudioProcessing(String visitId) async {
    final preferredLanguage = await readPreferredLanguageCodeForVisitSummary();
    final geminiLanguageInstruction =
        geminiLanguageInstructionForCode(preferredLanguage);

    final response = await http.post(
      Uri.parse('$baseUrl/api/visits/$visitId/process-audio'),
      headers: _headers,
      body: jsonEncode({
        'preferred_language': preferredLanguage,
        'gemini_language_instruction': geminiLanguageInstruction,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to trigger audio processing: ${response.statusCode}',
      );
    }
  }

  // Latest visit processing status
  Future<Map<String, dynamic>> getLatestVisitStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits/latest/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch latest visit status: ${response.statusCode}');
    }
  }

  Future<void> deleteSummary(String summaryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/summaries/$summaryId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete summary: ${response.statusCode}');
    }

    // API returns {"status": "ok"} on success
    final responseData = json.decode(response.body);
    if (responseData['status'] != 'ok') {
      throw Exception('Unexpected response from delete API');
    }
  }

  // TODO: Re-enable when patient domain models are implemented
  /*
  // Caregivers
  Future<List<Caregiver>> getCaregivers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/caregivers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Caregiver.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load caregivers');
    }
  }

  Future<Caregiver> inviteCaregiver(Caregiver caregiver) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient/caregivers/invite'),
      headers: _headers,
      body: json.encode(caregiver.toJson()),
    );

    if (response.statusCode == 201) {
      return Caregiver.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to invite caregiver');
    }
  }

  Future<void> updateCaregiverPermissions(
      String caregiverId, List<Permission> permissions) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/patient/caregivers/$caregiverId/permissions'),
      headers: _headers,
      body: json.encode({
        'permissions': permissions.map((p) => p.index).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update caregiver permissions');
    }
  }
  */

  /// Language Preferences
  Future<Map<String, String>> getLanguagePreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/language-preferences'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return {
        'app_language': data['app_language'] as String,
        'visit_language': data['visit_language'] as String,
      };
    } else {
      throw Exception('Failed to load language preferences');
    }
  }

  Future<void> updateLanguagePreferences({
    required String appLanguage,
    required String visitLanguage,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/language-preferences'),
      headers: _headers,
      body: json.encode({
        'app_language': appLanguage,
        'visit_language': visitLanguage,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update language preferences');
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
