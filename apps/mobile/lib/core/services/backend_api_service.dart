import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';
import '../config/environment.dart';
import '../models/user.dart';

/// Service for making authenticated API calls to the backend
class BackendApiService {
  final AuthService _authService;
  WebSocketChannel? _voxStreamChannel;
  StreamSubscription<dynamic>? _voxStreamSubscription;
  StreamController<Uint8List>? _voxAudioController;
  Timer? _voxConnectivityTimer;
  String? _voxNetworkSignature;
  bool _voxConnectivityCheckInProgress = false;

  BackendApiService({AuthService? authService})
      : _authService = authService ?? AuthService();

  Stream<Uint8List> get voxAudioStream {
    final controller = _voxAudioController;
    if (controller == null) {
      throw StateError('Vox stream is not connected.');
    }
    return controller.stream;
  }

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

  /// Vox today briefing
  Future<Map<String, dynamic>> getVoxTodayBriefing({
    String replyLanguage = 'en',
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final response = await http.post(
      Uri.parse(
        '${Environment.apiBaseUrl}/api/remivox/today?reply_language=$replyLanguage',
      ),
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
      if (message == 'Not Found') {
        message = 'Vox backend is not deployed yet. Please deploy the latest backend.';
      }
      throw Exception(message);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> askVox(
    String? prompt, {
    String replyLanguage = 'en',
    String timezone = 'UTC',
    String? audioBase64,
    String contentType = 'audio/wav',
    bool autoDetectLanguage = true,
    String? sessionId,
  }) async {
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
      body: json.encode({
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
        'reply_language': replyLanguage,
        'timezone': timezone,
        if (audioBase64 != null && audioBase64.isNotEmpty)
          'audio_base64': audioBase64,
        'content_type': contentType,
        'auto_detect_language': autoDetectLanguage,
        if (sessionId != null && sessionId.trim().isNotEmpty)
          'session_id': sessionId.trim(),
      }),
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
      if (message == 'Not Found') {
        message = 'Vox backend is not deployed yet. Please deploy the latest backend.';
      }
      throw Exception(message);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> translateVoxTurn({
    String? text,
    String? audioBase64,
    String sourceLanguage = 'en',
    String targetLanguage = 'bn',
    String contentType = 'audio/wav',
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/api/remivox/translate-turn'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        if (text != null) 'text': text,
        if (audioBase64 != null) 'audio_base64': audioBase64,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'content_type': contentType,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Live translate is not available right now.';
      try {
        final decoded = json.decode(response.body);
        final detail = decoded is Map ? decoded['detail'] : null;
        if (detail is String && detail.isNotEmpty) message = detail;
      } catch (_) {}
      throw Exception(message);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Uri voxStreamWebSocketUri({
    required String token,
    String language = 'en',
  }) {
    final base = Uri.parse(Environment.apiBaseUrl);
    return Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/remivox/stream',
      queryParameters: {
        'token': token,
        'language': language,
      },
    );
  }

  Future<void> connectVoxStream({
    required String token,
    String language = 'en',
  }) async {
    await closeVoxStream();

    final controller = StreamController<Uint8List>.broadcast();
    final channel = WebSocketChannel.connect(
      voxStreamWebSocketUri(token: token, language: language),
    );
    _voxAudioController = controller;
    _voxStreamChannel = channel;

    try {
      await channel.ready;
      channel.sink.add(json.encode({'type': 'auth', 'token': token}));
      _voxStreamSubscription = channel.stream.listen(
        (event) {
          if (event is Uint8List) {
            controller.add(event);
          } else if (event is List<int>) {
            controller.add(Uint8List.fromList(event));
          } else if (event is String) {
            try {
              final message = json.decode(event);
              if (message is Map) {
                if (message['type'] == 'ping') {
                  channel.sink.add(
                    json.encode({
                      'type': 'pong',
                      'timestamp': message['timestamp'],
                    }),
                  );
                } else if (message['type'] == 'error') {
                  final error = message['error'];
                  final detail = error is Map
                      ? error['message']?.toString()
                      : error?.toString();
                  controller.addError(
                    Exception(detail ?? 'Vox stream failed.'),
                  );
                }
              }
            } catch (_) {
              // Pipecat audio is binary; ignore malformed text control frames.
            }
          }
        },
        onError: controller.addError,
        onDone: () {
          _voxConnectivityTimer?.cancel();
          _voxConnectivityTimer = null;
          _voxNetworkSignature = null;
          _voxStreamChannel = null;
          _voxStreamSubscription = null;
          if (!controller.isClosed) {
            controller.close();
          }
        },
      );
      await _startVoxConnectivityMonitor();
    } catch (_) {
      await closeVoxStream();
      rethrow;
    }
  }

  Future<String> _currentNetworkSignature() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );
      final entries = <String>[];
      for (final interface in interfaces) {
        final addresses = interface.addresses
            .map((address) => address.address)
            .toList()
          ..sort();
        if (addresses.isNotEmpty) {
          entries.add('${interface.name}:${addresses.join(',')}');
        }
      }
      entries.sort();
      return entries.isEmpty ? 'offline' : entries.join('|');
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _startVoxConnectivityMonitor() async {
    _voxConnectivityTimer?.cancel();
    _voxNetworkSignature = await _currentNetworkSignature();
    _voxConnectivityTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_checkVoxConnectivity()),
    );
  }

  Future<void> _checkVoxConnectivity() async {
    if (_voxConnectivityCheckInProgress || _voxStreamChannel == null) return;
    _voxConnectivityCheckInProgress = true;
    try {
      final current = await _currentNetworkSignature();
      final previous = _voxNetworkSignature;
      if (previous != null &&
          previous != 'unknown' &&
          current != 'unknown' &&
          current != previous) {
        _voxNetworkSignature = current;
        await closeVoxStream();
      }
    } finally {
      _voxConnectivityCheckInProgress = false;
    }
  }

  void sendAudioChunk(Uint8List audioBytes) {
    final channel = _voxStreamChannel;
    if (channel == null) return;
    channel.sink.add(audioBytes);
  }

  Future<void> closeVoxStream() async {
    final subscription = _voxStreamSubscription;
    final channel = _voxStreamChannel;
    final controller = _voxAudioController;

    _voxConnectivityTimer?.cancel();
    _voxConnectivityTimer = null;
    _voxNetworkSignature = null;
    _voxStreamSubscription = null;
    _voxStreamChannel = null;
    _voxAudioController = null;

    await subscription?.cancel();
    await channel?.sink.close();
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  /// Hydra S2S live WebSocket URL (token in query; API key stays on server).
  Uri voxLiveWebSocketUri({
    required String accessToken,
    String mode = 'translate',
    String sourceLanguage = 'en',
    String targetLanguage = 'bn',
    String timezone = 'UTC',
  }) {
    final base = Uri.parse(Environment.apiBaseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/remivox/live',
      queryParameters: {
        'token': accessToken,
        'mode': mode,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        'timezone': timezone,
      },
    );
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