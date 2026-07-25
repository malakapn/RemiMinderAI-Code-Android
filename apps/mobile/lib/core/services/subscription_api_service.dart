import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/monetization_status.dart';
import 'auth_service.dart';

class SubscriptionApiService {
  SubscriptionApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<Map<String, String>> _headers() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  Future<MonetizationStatus> getStatus() async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/api/subscription/status'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load subscription status');
    }
    return MonetizationStatus.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<MonetizationStatus> syncRevenueCatStatus({
    required bool premium,
    String? appUserId,
    String? productId,
    String source = 'play_store',
  }) async {
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/api/subscription/sync'),
      headers: await _headers(),
      body: json.encode({
        'premium': premium,
        'app_user_id': appUserId,
        'product_id': productId,
        'source': source,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to sync subscription status');
    }
    return MonetizationStatus.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> trackEvent(
    String event, {
    Map<String, Object?> parameters = const {},
  }) async {
    await http.post(
      Uri.parse('${Environment.apiBaseUrl}/api/subscription/events'),
      headers: await _headers(),
      body: json.encode({
        'event': event,
        ...parameters,
      }),
    );
  }
}
