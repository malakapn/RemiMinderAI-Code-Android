import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../patient/data/models/summary_item.dart';

class CaregiverApiService {
  final String baseUrl;
  final String authToken;

  CaregiverApiService({
    required this.baseUrl,
    required this.authToken,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

  Future<List<SummaryItem>> getPatientSummaries(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/caregivers/patients/$patientId/summaries'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception(
          'Failed to fetch patient summaries: unexpected response',
        );
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SummaryItem.fromJson)
          .toList();
    }

    throw Exception(
      'Failed to fetch patient summaries: ${response.statusCode} ${response.body}',
    );
  }

  Future<Map<String, dynamic>> getPatientReminders(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/caregivers/patients/$patientId/reminders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw Exception(
        'Failed to fetch patient reminders: unexpected response',
      );
    }

    throw Exception(
      'Failed to fetch patient reminders: ${response.statusCode} ${response.body}',
    );
  }

  /// Ensures SQL care-team access exists for a Firestore-connected patient.
  Future<void> syncPatientAccess(String patientId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/caregivers/patients/$patientId/sync-access'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      'Failed to sync patient access: ${response.statusCode} ${response.body}',
    );
  }
}
