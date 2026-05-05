import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../models/caregiver_alert.dart';

class CaregiverAlertApiService {
  final AuthService _authService;
  static const Duration _requestTimeout = Duration(seconds: 8);

  CaregiverAlertApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<List<CaregiverAlert>> getAlerts({
    required String caregiverId,
    bool unreadOnly = false,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/caregivers/$caregiverId/alerts?unread_only=$unreadOnly',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load alerts');
    }
    final payload = json.decode(response.body) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(CaregiverAlert.fromJson)
        .toList();
  }

  Future<void> markAlertAsRead({
    required String caregiverId,
    required String alertId,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/caregivers/alerts/$alertId/read?caregiver_id=$caregiverId',
    );
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark alert as read');
    }
  }

  Future<void> deleteAlert({
    required String caregiverId,
    required String alertId,
  }) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/caregivers/alerts/$alertId?caregiver_id=$caregiverId',
    );
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(_requestTimeout);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete alert');
    }
  }
}
