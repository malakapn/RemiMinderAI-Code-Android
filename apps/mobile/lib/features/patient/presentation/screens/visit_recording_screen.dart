import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/visit_summary_gemini_prompt.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/visit_context.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/utils/locale_format.dart';

class VisitRecordingScreen extends StatefulWidget {
  final String visitId;

  const VisitRecordingScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<VisitRecordingScreen> createState() => _VisitRecordingScreenState();
}

class _VisitRecordingScreenState extends State<VisitRecordingScreen> {
  static const String _consentVersion = 'v1';
  static final Uri _privacyPolicyUri =
      Uri.parse('https://remiminderai.com/privacy');

  final AudioService _audioService = AudioService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RecordingState _recordingState = RecordingState.idle;
  Timer? _timer;
  int _secondsElapsed = 0;
  String _formattedTime = '00:00';
  String? _audioFilePath;
  bool _microphoneConsentGiven = false;
  bool _aiConsentGiven = false;
  bool _isStartingRecording = false;
  bool _isStoppingRecording = false;
  bool _isSavingRecording = false;
  bool _didFormatInitialTime = false;

  @override
  void initState() {
    super.initState();
    // Establish this visit as the current visit context.
    // Do not touch BuildContext here — LocaleFormat/AppLocalizations require
    // inherited widgets that are not available until after initState completes.
    VisitContext().setCurrentVisit(widget.visitId);
    // _formattedTime already defaults to '00:00'; locale-aware formatting
    // happens in didChangeDependencies / when the timer ticks.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFormatInitialTime) {
      _didFormatInitialTime = true;
      _updateFormattedTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_recordingState == RecordingState.recording) {
      unawaited(_audioService.cancelRecording());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _handleClose,
        ),
        title: const Text(
          'Record Visit',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_recordingState == RecordingState.completed)
            TextButton(
              onPressed: _isSavingRecording ? null : _saveRecording,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _buildStateContent(_recordingState),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStateContent(RecordingState state) {
    // Use MediaQuery to determine screen size and adjust layout
    final screenHeight = MediaQuery.of(context).size.height;
    final compactLayout =
        screenHeight < 700; // iPhone SE and similar small screens

    final gapAfterTimer = compactLayout ? 10.0 : 20.0;
    final gapAfterStatus = compactLayout ? 8.0 : 16.0;
    final gapAfterConsent = compactLayout ? 8.0 : 16.0;
    final gapAfterMic = compactLayout ? 6.0 : 16.0;

    return Column(
      key: ValueKey(state), // Required for AnimatedSwitcher
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer Display - Always visible, hero element
        Container(
          width: compactLayout
              ? 200
              : 250, // Fixed width for consistent alignment
          padding: EdgeInsets.symmetric(
            horizontal: compactLayout ? 24 : 32,
            vertical: compactLayout ? 8 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compactLayout ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            _formattedTime,
            style: TextStyle(
              fontSize: compactLayout ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: gapAfterTimer),

        // Recording Status
        Container(
          constraints: BoxConstraints(
            minWidth: compactLayout ? 140 : 160, // Fixed minimum width
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: compactLayout ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: compactLayout ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: gapAfterStatus),

        if (state == RecordingState.idle) ...[
          _buildConsentBlock(compactLayout),
          SizedBox(height: gapAfterConsent),
        ],

        // State-specific content - All buttons use identical width constraints
        SizedBox(
          width: compactLayout ? 200 : 240, // Fixed width for all button areas
          child: state == RecordingState.idle
              ? _buildMicButtonContent(compactLayout)
              : state == RecordingState.recording
                  ? _buildStopButtonContent(compactLayout)
                  : _buildCompletedButtonsContent(compactLayout),
        ),

        SizedBox(height: gapAfterMic),

        // Recording Instructions - state-specific
        SizedBox(
          width: compactLayout
              ? 280
              : 320, // Fixed width for consistent text alignment
          child: Text(
            _getRecordingInstructions(compact: compactLayout),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: compactLayout ? 13 : 15,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: compactLayout ? 2 : 3,
          ),
        ),
      ],
    );
  }

  Widget _buildConsentBlock(bool compactLayout) {
    final theme = Theme.of(context);

    return SizedBox(
      width: compactLayout ? 300 : 360,
      child: Container(
        padding: EdgeInsets.all(compactLayout ? 10 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent required before recording',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: compactLayout ? 14 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compactLayout ? 6 : 8),
            Text(
              'Please review and accept both items to enable the Record button.',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: compactLayout ? 12 : 13,
                height: 1.3,
              ),
            ),
            SizedBox(height: compactLayout ? 8 : 12),
            _ConsentCheckboxTile(
              value: _microphoneConsentGiven,
              enabled: !_isStartingRecording,
              compactLayout: compactLayout,
              label:
                  'I consent to this conversation being recorded and transcribed.',
              onChanged: (value) {
                setState(() {
                  _microphoneConsentGiven = value;
                });
              },
              onPrivacyPolicyTap: _openPrivacyPolicy,
            ),
            SizedBox(height: compactLayout ? 4 : 8),
            _ConsentCheckboxTile(
              value: _aiConsentGiven,
              enabled: !_isStartingRecording,
              compactLayout: compactLayout,
              label:
                  'I understand this recording will be processed by AI (Google Speech-to-Text and Gemini) to generate a summary.',
              onChanged: (value) {
                setState(() {
                  _aiConsentGiven = value;
                });
              },
              onPrivacyPolicyTap: _openPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButtonContent(bool compactLayout) {
    final canStartRecording =
        _hasRequiredRecordingConsents && !_isStartingRecording;
    final disabledColor = Colors.grey.shade400;

    return Semantics(
      button: true,
      enabled: canStartRecording,
      label: 'Record',
      child: GestureDetector(
        onTap: canStartRecording ? _toggleRecording : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: compactLayout ? 88 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: canStartRecording
                  ? [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ]
                  : [
                      disabledColor,
                      Colors.grey.shade500,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: canStartRecording
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: _isStartingRecording
              ? Center(
                  child: SizedBox(
                    width: compactLayout ? 30 : 36,
                    height: compactLayout ? 30 : 36,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: compactLayout ? 36 : 52,
                ),
        ),
      ),
    );
  }

  Widget _buildStopButtonContent(bool isSmallScreen) {
    return _PulsingButton(
      child: GestureDetector(
        onTap: _isStoppingRecording ? null : _stopRecording,
        child: Container(
          width: double.infinity,
          height: isSmallScreen ? 100 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isStoppingRecording
              ? SizedBox(
                  width: isSmallScreen ? 36 : 44,
                  height: isSmallScreen ? 36 : 44,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: isSmallScreen ? 40 : 52,
                ),
        ),
      ),
    );
  }

  Widget _buildCompletedButtonsContent(bool isSmallScreen) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Success Checkmark
        Container(
          width: isSmallScreen ? 50 : 60,
          height: isSmallScreen ? 50 : 60,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: isSmallScreen ? 28 : 32,
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Save Button
        ElevatedButton.icon(
          onPressed: _isSavingRecording ? null : _saveRecording,
          icon: const Icon(Icons.save, size: 20),
          label: Text(l10n.generateSummary),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize:
                Size(double.infinity, 0), // Full width within container
          ),
        ),

        SizedBox(height: isSmallScreen ? 8 : 12),

        // Discard Button
        OutlinedButton.icon(
          onPressed: _discardRecording,
          icon: const Icon(Icons.delete_outline, size: 20),
          label: Text(l10n.discardRecording),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize:
                Size(double.infinity, 0), // Full width within container
          ),
        ),
      ],
    );
  }

  Color _getTimerColor() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Theme.of(context).colorScheme.primary;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.completed:
        return Colors.green;
    }
  }

  void _toggleRecording() async {
    switch (_recordingState) {
      case RecordingState.idle:
        if (_hasRequiredRecordingConsents && !_isStartingRecording) {
          _startRecording();
        }
        break;
      case RecordingState.recording:
        await _stopRecording();
        break;
      case RecordingState.completed:
        _resetRecording();
        break;
    }
  }

  bool get _hasRequiredRecordingConsents =>
      _microphoneConsentGiven && _aiConsentGiven;

  Future<void> _startRecording() async {
    if (!_hasRequiredRecordingConsents || _isStartingRecording) {
      return;
    }

    setState(() {
      _isStartingRecording = true;
    });

    try {
      await _logRecordingConsents();
      if (!mounted) return;

      if (kDebugMode) print('🎬 Starting recording...');
      final success = await _audioService.startRecording(context);
      if (!mounted) return;

      if (kDebugMode) print('🎬 Recording start success: $success');
      if (success) {
        setState(() {
          _recordingState = RecordingState.recording;
          _secondsElapsed = 0;
          _updateFormattedTime();
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsElapsed++;
              _updateFormattedTime();
            });
          }
        });
      } else {
        // Permission denied or initialization failed
        if (kDebugMode) print(
            '🎬 Recording failed - permission denied or initialization error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone permission is required. Please enable it in Settings > RemiMinder > Microphone.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableToStartRecording('$e'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRecording = false;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isStoppingRecording || _recordingState != RecordingState.recording) {
      return;
    }

    setState(() {
      _isStoppingRecording = true;
    });

    try {
      final recordingPath = await _audioService.stopRecording();
      if (!mounted) return;

      _timer?.cancel();
      setState(() {
        _recordingState = RecordingState.completed;
        _audioFilePath = recordingPath;
        _isStoppingRecording = false;
      });

      if (recordingPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.recordingCompleted)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to save recording. Please try recording again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStoppingRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableToStopRecording('$e'))),
      );
    }
  }

  void _resetRecording() async {
    await _audioService.cancelRecording();
    if (!mounted) return;

    setState(() {
      _recordingState = RecordingState.idle;
      _secondsElapsed = 0;
      _updateFormattedTime();
    });

    _timer?.cancel();
  }

  void _discardRecording() async {
    // Delete the recorded file if it exists
    if (_audioFilePath != null) {
      await _audioService.deleteRecording(_audioFilePath!);
    }
    if (!mounted) return;

    // Reset to idle state
    setState(() {
      _recordingState = RecordingState.idle;
      _secondsElapsed = 0;
      _updateFormattedTime();
      _audioFilePath = null;
    });

    _timer?.cancel();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.recordingDiscarded)),
    );
  }

  Future<void> _logRecordingConsents() async {
    final currentUser = await _authService.getCurrentUser();
    final uid = currentUser?.authUid ?? currentUser?.id;

    if (uid == null || uid.isEmpty) {
      throw Exception('Please sign in again before recording.');
    }

    final sessionId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

    await _firestore
        .collection('consents')
        .doc(uid)
        .collection('recording_sessions')
        .doc(sessionId)
        .set({
      'microphoneConsentGiven': true,
      'aiConsentGiven': true,
      'consentVersion': _consentVersion,
      'platform': _platformLabel,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String get _platformLabel {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return Platform.operatingSystem;
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final launched = await launchUrl(
        _privacyPolicyUri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenPrivacyPolicy)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenPrivacyPolicy)),
      );
    }
  }

  Future<void> _saveRecording() async {
    if (_isSavingRecording) {
      return;
    }

    if (_audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noRecordingAvailable)),
      );
      return;
    }

    setState(() {
      _isSavingRecording = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.uploadingAudio)),
    );

    try {
      if (kDebugMode) print("🧪 Starting upload...");
      await _uploadAudioToBackend(_audioFilePath!);
      if (!mounted) return;

      if (kDebugMode) print("🧪 Upload finished");

      // Trigger audio processing pipeline (returns immediately)
      if (kDebugMode) print("🧪 Triggering processing...");
      await _triggerAudioProcessing();
      if (!mounted) return;

      // Clean up local file
      await _audioService.deleteRecording(_audioFilePath!);
      if (!mounted) return;

      VisitContext().clearVisit();

      final l10n = AppLocalizations.of(context)!;
      final goHome = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.visitProcessingTitle),
          content: Text(l10n.visitProcessingBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.goToHome),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.viewOverviewAction),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (goHome == true) {
        context.go('/patient/home');
      } else {
        context.go('/patient/overview');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSavingRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadAudio('$e'))),
      );
    } finally {
      if (mounted && _isSavingRecording) {
        setState(() {
          _isSavingRecording = false;
        });
      }
    }
  }

  Future<void> _uploadAudioToBackend(String audioFilePath) async {
    // Get access token from AuthService
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    // Use the visit ID from widget arguments
    final visitId = widget.visitId;

    // Use API_BASE_URL from environment configuration
    final uri =
        Uri.parse('${Environment.apiBaseUrl}/api/visits/$visitId/audio/upload');
    final request = http.MultipartRequest('POST', uri);

    // Add authentication header
    request.headers['Authorization'] = 'Bearer $accessToken';

    // Use MultipartFile.fromPath for efficient streaming (no memory loading)
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Field name expected by backend
        audioFilePath,
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

  Future<void> _triggerAudioProcessing() async {
    if (kDebugMode) print("🧪 Inside _triggerAudioProcessing()");

    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication required. Please log in again.');
    }

    final visitId = widget.visitId;
    final uri = Uri.parse(
        '${Environment.apiBaseUrl}/api/visits/$visitId/process-audio');

    final preferredLanguage = await readPreferredLanguageCodeForVisitSummary();
    final geminiLanguageInstruction =
        geminiLanguageInstructionForCode(preferredLanguage);

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'preferred_language': preferredLanguage,
        'gemini_language_instruction': geminiLanguageInstruction,
      }),
    );

    if (kDebugMode) print("🧪 process-audio status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to trigger audio processing: ${response.statusCode}');
    }
  }

  void _handleClose() {
    final l10n = AppLocalizations.of(context)!;
    if (_recordingState == RecordingState.recording) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.stopRecordingTitle),
          content: Text(l10n.stopRecordingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.continueRecording),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _timer?.cancel();
                await _audioService.cancelRecording();
                if (!mounted) return;
                setState(() {
                  _recordingState = RecordingState.idle;
                  _secondsElapsed = 0;
                  _updateFormattedTime();
                  _audioFilePath = null;
                  _isStoppingRecording = false;
                });
                context.go('/patient/home');
              },
              child: Text(l10n.stopAndDiscard),
            ),
          ],
        ),
      );
    } else {
      context.go('/patient/home');
    }
  }

  void _updateFormattedTime() {
    _formattedTime = LocaleFormat.durationMinutesSeconds(
      context,
      Duration(seconds: _secondsElapsed),
    );
  }

  Color _getStatusColor() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Theme.of(context).colorScheme.primary;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.completed:
        return Colors.green;
    }
  }

  String _getStatusText() {
    switch (_recordingState) {
      case RecordingState.idle:
        return _hasRequiredRecordingConsents
            ? 'Ready to Record'
            : 'Consent Required';
      case RecordingState.recording:
        return 'Recording...';
      case RecordingState.completed:
        return 'Recording complete';
    }
  }

  String _getRecordingInstructions({bool compact = false}) {
    switch (_recordingState) {
      case RecordingState.idle:
        if (compact) {
          if (_hasRequiredRecordingConsents) {
            return 'Your recording stays private and secure';
          }
          return 'Review and accept both consent items to enable recording.';
        }
        return _hasRequiredRecordingConsents
            ? 'Tap to start recording your visit\nYour recording stays private and secure'
            : 'Review and accept both consent items to enable recording.';
      case RecordingState.recording:
        return 'Recording in progress...';
      case RecordingState.completed:
        return 'Recording complete!\nTap Generate to process your visit summary';
    }
  }
}

class _ConsentCheckboxTile extends StatelessWidget {
  final bool value;
  final bool enabled;
  final bool compactLayout;
  final String label;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPrivacyPolicyTap;

  const _ConsentCheckboxTile({
    required this.value,
    required this.enabled,
    this.compactLayout = false,
    required this.label,
    required this.onChanged,
    required this.onPrivacyPolicyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compactLayout ? 2 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Checkbox(
                    value: value,
                    onChanged: enabled
                        ? (checked) => onChanged(checked ?? false)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: enabled ? onPrivacyPolicyTap : null,
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: theme.colorScheme.primary,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingButton extends StatefulWidget {
  final Widget child;

  const _PulsingButton({required this.child});

  @override
  _PulsingButtonState createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

enum RecordingState {
  idle, // before recording
  recording, // while recording
  completed, // after recording stops
}
