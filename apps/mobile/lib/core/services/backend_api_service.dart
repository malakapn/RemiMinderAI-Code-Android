import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../config/environment.dart';
import '../models/user.dart';

/// Service for making authenticated API calls to the backend
class BackendApiService {
  final AuthService _authService;
  static const Duration _apiTimeout = Duration(seconds: 8);

  BackendApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  /// Upload audio file to backend
  Future<void> uploadAudio({
    required String visitId,
    required File audioFile,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/visits/$visitId/audio/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        filename: 'recording.m4a',
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
          'Audio upload failed: ${response.statusCode} - $responseBody');
    }
  }

  /// Upload image file to backend
  Future<void> uploadImage({
    required String visitId,
    required File imageFile,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/visits/$visitId/image/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $accessToken';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'image.jpg',
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
          'Image upload failed: ${response.statusCode} - $responseBody');
    }
  }

  /// Trigger OCR processing for uploaded image
  Future<Map<String, dynamic>> triggerOcr({required String visitId}) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/visits/$visitId/ocr');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'OCR trigger failed: ${response.statusCode} - ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Bootstrap user in backend after Firebase authentication
  Future<void> bootstrapUser({String? fullName, UserRole? role}) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/bootstrap');
    final body = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }
    if (role != null) {
      body['app_role'] =
          role == UserRole.caregiver ? 'caregiver' : 'patient';
    }
    final requestBody = body.isEmpty ? null : json.encode(body);

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    ).timeout(_apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'User bootstrap failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get current user's profile from backend
  Future<UserProfile> getMyProfile() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/me');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(_apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
          'Get profile failed: ${response.statusCode} - ${response.body}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(jsonData);
  }

  /// Update the current user's full name
  Future<void> updateName(String fullName) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) throw Exception('Authentication required');
    final response = await http.put(
      Uri.parse('${Environment.apiBaseUrl}/api/users/me/name'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'full_name': fullName}),
    ).timeout(_apiTimeout);
    if (response.statusCode != 200) {
      throw Exception('Update name failed: ${response.statusCode}');
    }
  }

  /// Update user role in backend
  Future<void> updateUserRole(String firebaseUid, String role) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) return;

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/$firebaseUid/role');
    await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'role': role}),
    ).timeout(_apiTimeout);
  }

  /// Update current user's phone number
  Future<String?> updateMyPhone(String? phone) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/me/phone');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Update phone failed: ${response.statusCode} - ${response.body}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return jsonData['phone'] as String?;
  }

  /// Stripe Checkout (subscription). Opens returned URL in the device browser.
  /// [interval] must be `monthly` or `yearly` (matches Stripe Price IDs on server).
  Future<String> createSubscriptionCheckoutUrl({
    required String interval,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/api/billing/create-checkout-session',
    );
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'interval': interval,
        'success_url': Environment.billingSuccessUrl,
        'cancel_url': Environment.billingCancelUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Checkout failed: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Invalid checkout response');
    }
    return url;
  }

  /// Register FCM token for the authenticated user (patient or caregiver).
  Future<void> registerFcmToken({
    required String fcmToken,
    required String deviceType,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/reminders/fcm/token');
    final normalizedType =
        deviceType.trim().toLowerCase() == 'ios' ? 'ios' : 'android';

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'fcm_token': fcmToken,
        'device_type': normalizedType,
      }),
    ).timeout(_apiTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'registerFcmToken failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
