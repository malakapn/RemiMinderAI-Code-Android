import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for handling app permissions (Camera, Microphone, etc.)
class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  /// Request camera permission for scanning pill bottles, lab reports, etc.
  Future<PermissionStatus> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied || !status.isGranted) {
      await _showPermissionDialog(
        context,
        title: 'Camera Permission Required',
        message:
            'Camera access is needed to scan pill bottles, lab reports, and other medical documents. Please enable camera permission in settings.',
        permission: Permission.camera,
      );
    }

    return status;
  }

  /// Request microphone permission for recording conversations
  Future<PermissionStatus> requestMicrophonePermission(
    BuildContext context,
  ) async {
    if (kDebugMode) {
      print('🔊 Requesting microphone permission...');
    }
    final status = await Permission.microphone.request();
    if (kDebugMode) {
      print('🔊 Microphone permission status: $status');
    }

    if (status.isPermanentlyDenied) {
      if (kDebugMode) {
        print('🔊 Microphone permission permanently denied, opening settings...');
      }
      await _showPermissionDialog(
        context,
        title: 'Microphone Permission Required',
        message:
            'Microphone access is needed to record healthcare conversations and consultations. Permission was previously denied. Please go to Settings > RemiMinder > Microphone to enable it.',
        permission: Permission.microphone,
      );
    } else if (status.isDenied || !status.isGranted) {
      if (kDebugMode) {
        print('🔊 Microphone permission denied, showing dialog...');
      }
      await _showPermissionDialog(
        context,
        title: 'Microphone Permission Required',
        message:
            'Microphone access is needed to record healthcare conversations and consultations. Please enable microphone permission in settings.',
        permission: Permission.microphone,
      );
    }

    return status;
  }

  /// Request both camera and microphone permissions
  Future<Map<Permission, PermissionStatus>> requestMediaPermissions(
    BuildContext context,
  ) async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    // Show dialogs for denied permissions
    for (final entry in statuses.entries) {
      if (entry.value.isDenied ||
          entry.value.isPermanentlyDenied ||
          !entry.value.isGranted) {
        final title = entry.key == Permission.camera
            ? 'Camera Permission Required'
            : 'Microphone Permission Required';
        final message = entry.key == Permission.camera
            ? 'Camera access is needed to scan pill bottles, lab reports, and other medical documents.'
            : 'Microphone access is needed to record healthcare conversations and consultations.';

        await _showPermissionDialog(
          context,
          title: title,
          message: message,
          permission: entry.key,
        );
      }
    }

    return statuses;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Show permission dialog with option to go to settings
  Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Permission permission,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Get permission status for a specific permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  /// Open app settings (for when permissions are permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
