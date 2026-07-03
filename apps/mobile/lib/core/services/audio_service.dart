import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling audio recording operations (conversations, consultations)
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording duration
  Duration get recordingDuration => _recordingDuration;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Request microphone permission and initialize recorder
  /// Uses record package's hasPermission() as source of truth on iOS
  Future<bool> initialize(BuildContext context) async {
    try {
      if (kDebugMode) {
        print('🎙️ Initializing audio service...');
      }

      // Initialize record package first
      _audioRecorder ??= AudioRecorder();

      // 🔥 iOS-safe: Use record package's hasPermission() as authoritative source
      final hasPermission = await _audioRecorder!.hasPermission();
      if (kDebugMode) {
        print(
            '🎙️ Recorder hasPermission (authoritative on iOS): $hasPermission');
      }

      if (!hasPermission) {
        if (kDebugMode) {
          print('🎙️ Microphone permission not granted by hardware API');
        }

        // Show dialog to open settings
        if (context.mounted) {
          await _showPermissionDialog(
            context,
            'Microphone access is needed to record conversations. Please enable it in Settings > RemiMinder > Microphone.',
          );
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ Microphone permission granted! Audio recorder ready.');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error initializing audio recorder: $e');
      return false;
    }
  }

  Future<void> _showPermissionDialog(
      BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Required'),
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

  /// Start recording audio
  /// iOS-safe: Includes delay to prevent AVAudioSession race conditions
  Future<bool> startRecording(BuildContext context) async {
    try {
      if (_isRecording) {
        debugPrint('⚠️ Already recording');
        return false;
      }

      if (_audioRecorder == null) {
        final initialized = await initialize(context);
        if (!initialized) return false;
      }

      // Get the directory to save recordings
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      // 🔥 iOS-CRITICAL: Small delay prevents AVAudioSession crash
      // This gives iOS time to properly configure the audio session
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('🎙️ Starting recorder with path: $_currentRecordingPath');

      // Start recording with record package
      await _audioRecorder!
          .start(const RecordConfig(), path: _currentRecordingPath!);

      _isRecording = true;
      _recordingDuration = Duration.zero;
      _startRecordingTimer();

      debugPrint('✅ Recording started successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _isRecording = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    if (_audioRecorder == null) {
      return null;
    }

    try {
      final recorderActive =
          _isRecording || await _audioRecorder!.isRecording();
      if (!recorderActive) {
        return null;
      }

      // iOS: brief pause avoids AVAudioSession race when stopping.
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final path = await _audioRecorder!.stop().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Timed out while stopping the recorder');
        },
      );
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final resolvedPath = path ?? _currentRecordingPath;
      if (resolvedPath != null) {
        final file = File(resolvedPath);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;

        if (exists && size > 0) {
          debugPrint(
            'Recording saved successfully: $resolvedPath ($size bytes)',
          );
          return resolvedPath;
        }

        debugPrint('Recording file is empty or missing');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
      rethrow;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      if (_audioRecorder != null && _isRecording) {
        await _audioRecorder!.pause();
        _recordingTimer?.cancel();
        debugPrint('Recording paused');
      }
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      if (_audioRecorder != null && _isRecording) {
        await _audioRecorder!.resume();
        _startRecordingTimer();
        debugPrint('Recording resumed');
      }
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  /// Cancel recording (delete the file)
  Future<void> cancelRecording() async {
    try {
      if (_audioRecorder != null) {
        final recorderActive =
            _isRecording || await _audioRecorder!.isRecording();
        if (recorderActive) {
          if (Platform.isIOS) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          await _audioRecorder!.stop();
        }
      }

      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
      _recordingDuration = Duration.zero;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
    }
  }

  /// Get recording duration as formatted string
  String getFormattedDuration([String? localeCode]) {
    final loc = localeCode ?? Intl.defaultLocale ?? 'en';
    final minutes = _recordingDuration.inMinutes.remainder(60);
    final seconds = _recordingDuration.inSeconds.remainder(60);
    return '${NumberFormat('00', loc).format(minutes)}:'
        '${NumberFormat('00', loc).format(seconds)}';
  }

  /// Check if recording is paused
  Future<bool> isRecordingPaused() async {
    try {
      return !(await _audioRecorder?.isRecording() ?? false);
    } catch (e) {
      debugPrint('Error checking recording pause state: $e');
      return false;
    }
  }

  /// Play recorded audio (placeholder for future implementation)
  Future<void> playRecording(String filePath) async {
    // TODO: Implement audio playback
    // This could use just_audio or audio_players package
    debugPrint('Playing recording: $filePath');
  }

  /// Delete recording file
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  /// Get list of saved recordings
  Future<List<File>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((entity) {
            return entity is File && entity.path.endsWith('.m4a');
          })
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      files
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      debugPrint('Error getting saved recordings: $e');
      return [];
    }
  }

  /// Start the recording timer
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
    });
  }

  /// Release native recorder resources. Stops an active recording first when possible.
  void dispose() {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    final recorder = _audioRecorder;
    _audioRecorder = null;
    _isRecording = false;

    if (recorder == null) {
      return;
    }

    unawaited(() async {
      try {
        if (await recorder.isRecording()) {
          await recorder.stop();
        }
      } catch (e) {
        debugPrint('Error stopping recorder during dispose: $e');
      }

      try {
        await recorder.dispose();
      } catch (e) {
        debugPrint('Error disposing recorder: $e');
      }
    }());
  }
}
