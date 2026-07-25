import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/environment.dart';
import '../models/user.dart';

/// Service for making authenticated API calls to the backend
class BackendApiService {
  final AuthService _authService;

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

  /// Upload image file to backend, returns GCS file path
  Future<String> uploadImage({
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
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
          'Image upload failed: ${response.statusCode} - $responseBody');
    }

    final data = json.decode(responseBody) as Map<String, dynamic>;
    return data['gcs_file_path'] as String;
  }

  /// Trigger OCR processing for uploaded image
  Future<void> triggerOcr({required String visitId}) async {
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
  }

  /// Bootstrap user in backend after Firebase authentication
  Future<void> bootstrapUser({String? fullName}) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/bootstrap');
    final requestBody =
        fullName != null ? json.encode({'full_name': fullName}) : null;

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

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
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Get profile failed: ${response.statusCode} - ${response.body}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(jsonData);
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

  /// Register or refresh this device's FCM token for server push notifications.
  Future<Map<String, dynamic>> getVoxTodayBriefing() async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/api/remivox/today'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      String message = 'Vox is not available right now. Please try again.';
      try {
        final decoded = json.decode(response.body);
        final detail = decoded is Map ? decoded['detail'] : null;
        if (detail is Map && detail['message'] is String) {
          message = detail['message'] as String;
        } else if (detail is String && detail.isNotEmpty) {
          message = detail;
        }
      } catch (_) {}
      throw Exception(message);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> askVox(String prompt) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/api/remivox/ask'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'prompt': prompt}),
    );

    if (response.statusCode != 200) {
      String message = 'Vox is not available right now. Please try again.';
      try {
        final decoded = json.decode(response.body);
        final detail = decoded is Map ? decoded['detail'] : null;
        if (detail is Map && detail['message'] is String) {
          message = detail['message'] as String;
        } else if (detail is String && detail.isNotEmpty) {
          message = detail;
        }
      } catch (_) {}
      throw Exception(message);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Register or refresh this device's FCM token for server push notifications.
  Future<void> registerFcmToken({
    required String fcmToken,
    String deviceType = 'android',
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/api/fcm/token');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'fcm_token': fcmToken,
        'device_type': deviceType,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'FCM token registration failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
  Future<Map<String, dynamic>> scanDocument({required String gcsFilePath}) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) throw Exception('Authentication required');
    final uri = Uri.parse('${Environment.apiBaseUrl}/api/scan-document');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'gcs_file_path': gcsFilePath}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Scan failed: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getCaregiverAlerts(String caregiverId) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) return [];
    try {
      final uri = Uri.parse('${Environment.apiBaseUrl}/api/caregivers/$caregiverId/alerts');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Failed to fetch caregiver alerts: $e');
    }
    return [];
  }
}