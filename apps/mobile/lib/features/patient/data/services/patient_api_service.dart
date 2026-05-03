import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/summary_item.dart';
import '../models/models.dart';
import '../../../../core/config/environment.dart';


class PatientApiService {
  final String baseUrl;
  final String _authToken;
  static const Duration _requestTimeout = Duration(seconds: 8);

  PatientApiService({
    String? baseUrl,
    String? authToken,
  })  : baseUrl = baseUrl ?? Environment.apiBaseUrl,
        _authToken = authToken ?? '';

  static String? _staticToken;

  /// Resolved auth header: explicit per-instance token beats process-wide cache.
  String get _token {
    final t = _authToken.trim();
    if (t.isNotEmpty) {
      return t;
    }
    return (_staticToken ?? '').trim();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  static void clearSessionCaches() {
    _staticToken = null;
    _summariesCache = null;
    _latestStatusCache = null;
  }

  static void setCachedLatestVisitStatus(Map<String, dynamic> status) {
    _latestStatusCache = CacheEntry(status, DateTime.now());
  }

  static void setAuthToken(String token) {
    _staticToken = token;
  }

  static List<SummaryItem>? getCachedSummaries() {
    return _summariesCache?.data;
  }

  static void setCachedSummaries(List<SummaryItem> summaries) {
    _summariesCache = CacheEntry(summaries, DateTime.now());
  }

  static Map<String, dynamic>? getCachedLatestVisitStatus() {
    return _latestStatusCache?.data;
  }

  // In-memory cache
  static CacheEntry<List<SummaryItem>>? _summariesCache;
  static CacheEntry<Map<String, dynamic>>? _latestStatusCache;

  // Medications
  Future<List<Medication>> getMedications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/medications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Medication.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load medications: ${response.statusCode}');
    }
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/medications'),
      headers: _headers,
      body: json.encode(medication.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Medication.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create medication: ${response.statusCode}');
    }
  }

  Future<Medication> updateMedication(Medication medication) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/patient/medications/${medication.id}'),
      headers: _headers,
      body: json.encode(medication.toJson()),
    );

    if (response.statusCode == 200) {
      return Medication.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update medication: ${response.statusCode}');
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/patient/medications/$medicationId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete medication: ${response.statusCode}');
    }
  }

  // Reminders
  Future<List<Reminder>> getReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reminders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reminders: ${response.statusCode}');
    }
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reminders'),
      headers: _headers,
      body: json.encode(reminder.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create reminder: ${response.statusCode}');
    }
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/reminders/${reminder.id}'),
      headers: _headers,
      body: json.encode(reminder.toJson()),
    );

    if (response.statusCode == 200) {
      return Reminder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update reminder: ${response.statusCode}');
    }
  }

  Future<void> markReminderCompleted(String reminderId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/reminders/$reminderId/complete'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to mark reminder as completed: ${response.statusCode}');
    }
  }

  Future<void> snoozeReminder(String reminderId, int minutes) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/reminders/$reminderId/snooze'),
      headers: _headers,
      body: json.encode({'minutes': minutes}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to snooze reminder: ${response.statusCode}');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/reminders/$reminderId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reminder: ${response.statusCode}');
    }
  }

  // Appointments
  Future<List<Appointment>> getAppointments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/appointments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load appointments: ${response.statusCode}');
    }
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/appointments'),
      headers: _headers,
      body: json.encode(appointment.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Appointment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create appointment: ${response.statusCode}');
    }
  }

  Future<Appointment> updateAppointment(Appointment appointment) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/patient/appointments/${appointment.id}'),
      headers: _headers,
      body: json.encode(appointment.toJson()),
    );

    if (response.statusCode == 200) {
      return Appointment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update appointment: ${response.statusCode}');
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/patient/appointments/$appointmentId/cancel'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment: ${response.statusCode}');
    }
  }

  // Visits
  Future<List<Visit>> getVisits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Visit.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load visits: ${response.statusCode}');
    }
  }

  Future<Visit> createVisit(Visit visit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/visits'),
      headers: _headers,
      body: json.encode(visit.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Visit.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create visit: ${response.statusCode}');
    }
  }

  Future<Visit> getVisit(String visitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits/$visitId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Visit.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load visit: ${response.statusCode}');
    }
  }

  Future<Visit> updateVisit(Visit visit) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/visits/${visit.id}'),
      headers: _headers,
      body: json.encode(visit.toJson()),
    );

    if (response.statusCode == 200) {
      return Visit.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update visit: ${response.statusCode}');
    }
  }

  Future<void> deleteVisit(String visitId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/visits/$visitId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete visit: ${response.statusCode}');
    }
  }

  // Visit Summary (AI-generated)
  Future<Map<String, dynamic>> getVisitSummary(String visitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits/$visitId/summary'),
      headers: _headers,
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch visit summary: ${response.statusCode}');
    }
  }

  // Visit Structured Summary (AI-generated)
  Future<Map<String, dynamic>> getVisitSummaryStructured(String visitId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits/$visitId/summary-structured'),
      headers: _headers,
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch structured visit summary: ${response.statusCode}');
    }
  }

  // Summaries List
  Future<List<SummaryItem>> getSummaries() async {
    if (_token.isEmpty) {
      throw Exception(
          'Authentication required - sign in again to load summaries.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/api/summaries'),
      headers: _headers,
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SummaryItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch summaries: ${response.statusCode}');
    }
  }

  // Latest visit processing status
  Future<Map<String, dynamic>> getLatestVisitStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/visits/latest/status'),
      headers: _headers,
    ).timeout(_requestTimeout);

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

  Future<List<Map<String, dynamic>>> getScannedDocs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/scanned-docs'),
      headers: _headers,
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception('Failed to load scanned docs: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getLabResults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/lab-results'),
      headers: _headers,
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception('Failed to load lab results: ${response.statusCode}');
  }

  // Caregivers
  Future<List<Caregiver>> getCaregivers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patient/caregivers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Caregiver.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load caregivers: ${response.statusCode}');
    }
  }

  Future<Caregiver> inviteCaregiver(Caregiver caregiver) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patient/caregivers/invite'),
      headers: _headers,
      body: json.encode(caregiver.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Caregiver.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to invite caregiver: ${response.statusCode}');
    }
  }

  Future<Caregiver> updateCaregiver(Caregiver caregiver) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/patient/caregivers/${caregiver.id}'),
      headers: _headers,
      body: json.encode(caregiver.toJson()),
    );

    if (response.statusCode == 200) {
      return Caregiver.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update caregiver: ${response.statusCode}');
    }
  }

  Future<void> updateCaregiverPermissions(
      String caregiverId, List<Permission> permissions) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/patient/caregivers/$caregiverId/permissions'),
      headers: _headers,
      body: json.encode({
        'permissions': permissions.map((p) => p.index).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update caregiver permissions: ${response.statusCode}');
    }
  }

  Future<void> removeCaregiver(String caregiverId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/patient/caregivers/$caregiverId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove caregiver: ${response.statusCode}');
    }
  }

  /// Language Preferences
  Future<Map<String, String>> getLanguagePreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me/language-preferences'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final dynamic raw = json.decode(response.body);
      if (raw is! Map<String, dynamic>) {
        throw Exception('Invalid language preferences payload');
      }
      return {
        'app_language': (raw['app_language'] ?? 'en').toString(),
        'visit_language': (raw['visit_language'] ?? 'en').toString(),
      };
    }

    throw Exception(
      'Failed to load language preferences: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> updateLanguagePreferences({
    required String appLanguage,
    required String visitLanguage,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me/language-preferences'),
      headers: _headers,
      body: json.encode({
        'app_language': appLanguage,
        'visit_language': visitLanguage,
      }),
    );

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      throw Exception(
        'Failed to update language preferences: ${response.statusCode} ${response.body}',
      );
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}
