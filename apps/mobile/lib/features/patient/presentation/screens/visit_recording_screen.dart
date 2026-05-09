import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../data/services/visit_summary_gemini_prompt.dart';
import 'visit_recording_two_party_consent_screen.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/consent_service.dart';
import '../../../../core/services/visit_context.dart';
import '../../../../core/config/environment.dart';

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
  final AudioService _audioService = AudioService();
  final AuthService _authService = AuthService();
  final ConsentService _consentService = ConsentService();
  RecordingState _recordingState = RecordingState.idle;
  Timer? _timer;
  int _secondsElapsed = 0;
  String _formattedTime = '00:00';
  String? _audioFilePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Establish this visit as the current visit context
    VisitContext().setCurrentVisit(widget.visitId);
    _updateFormattedTime(); // Initialize timer display
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
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
              onPressed: _saveRecording,
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
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(RecordingState state) {
    // Use MediaQuery to determine screen size and adjust layout
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen =
        screenHeight < 700; // iPhone SE and similar small screens

    return Column(
      key: ValueKey(state), // Required for AnimatedSwitcher
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer Display - Always visible, hero element
        Container(
          width:
              isSmallScreen ? 200 : 250, // Fixed width for consistent alignment
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 32,
            vertical: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            _formattedTime,
            style: TextStyle(
              fontSize: isSmallScreen ? 36 : 48,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: isSmallScreen ? 16 : 20),

        // Recording Status
        Container(
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 140 : 160, // Fixed minimum width
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // State-specific content - All buttons use identical width constraints
        SizedBox(
          width: isSmallScreen ? 200 : 240, // Fixed width for all button areas
          child: state == RecordingState.idle
              ? _buildMicButtonContent(isSmallScreen)
              : state == RecordingState.recording
                  ? _buildStopButtonContent(isSmallScreen)
                  : _buildCompletedButtonsContent(isSmallScreen),
        ),

        SizedBox(height: isSmallScreen ? 12 : 16),

        // Recording Instructions - state-specific
        SizedBox(
          width: isSmallScreen
              ? 280
              : 320, // Fixed width for consistent text alignment
          child: Text(
            _getRecordingInstructions(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButtonContent(bool isSmallScreen) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: double.infinity,
        height: isSmallScreen ? 100 : 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.mic,
          color: Colors.white,
          size: isSmallScreen ? 40 : 52,
        ),
      ),
    );
  }

  Widget _buildStopButtonContent(bool isSmallScreen) {
    return _PulsingButton(
      child: GestureDetector(
        onTap: _toggleRecording,
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
                color: Colors.red.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.stop,
            color: Colors.white,
            size: isSmallScreen ? 40 : 52,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedButtonsContent(bool isSmallScreen) {
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
          onPressed: _saveRecording,
          icon: const Icon(Icons.save, size: 20),
          label: const Text('Generate Summary'),
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
          label: const Text('Discard Recording'),
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

  void _toggleRecording() {
    switch (_recordingState) {
      case RecordingState.idle:
        _startRecording();
        break;
      case RecordingState.recording:
        _stopRecording();
        break;
      case RecordingState.completed:
        _resetRecording();
        break;
    }
  }

  void _startRecording() async {
    // Check if user has accepted audio consent
    final hasConsent = await _consentService.hasAcceptedAudioConsent();
    if (!mounted) return;

    if (!hasConsent) {
      final accepted = await _showAudioConsentDialog();
      if (!mounted) return;

      if (!accepted) {
        return; // User declined consent
      }
    }

    final twoPartyAccepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (context) => const VisitRecordingTwoPartyConsentScreen(),
      ),
    );
    if (!mounted) return;
    if (twoPartyAccepted != true) {
      return;
    }

    print('🎬 Starting recording...');
    final success = await _audioService.startRecording(context);
    if (!mounted) return;

    print('🎬 Recording start success: $success');
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
      print('🎬 Recording failed - permission denied or initialization error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone permission is required. Please enable it in Settings > RemiMinder > Microphone.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final recordingPath = await _audioService.stopRecording();
    if (!mounted) return;

    setState(() {
      _recordingState = RecordingState.completed;
      _audioFilePath = recordingPath;
    });

    _timer?.cancel();

    if (recordingPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording completed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save recording')),
      );
    }
  }

  void _resetRecording() async {
    await _audioService.cancelRecording();
    if (!mounted) return;

    setState(() {
      _recordingState = RecordingState.idle;
      _secondsElapsed = 0;
      _formattedTime = '00:00';
    });

    _timer?.cancel();
  }

  void _discardRecording() async {
    // Delete the recorded file if it exists
    if (_audioFilePath != null) {
      await _audioService.deleteRecording(_audioFilePath!);
    }

    // Reset to idle state
    setState(() {
      _recordingState = RecordingState.idle;
      _secondsElapsed = 0;
      _formattedTime = '00:00';
      _audioFilePath = null;
    });

    _timer?.cancel();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording discarded')),
    );
  }

  void _saveRecording() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    print("🧪 SAVE BUTTON PRESSED");

    if (_audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording available')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading audio...')),
    );

    try {
      print("🧪 Starting upload...");
      await _uploadAudioToBackend(_audioFilePath!);
      if (!mounted) return;

      print("🧪 Upload finished");

      // Trigger audio processing pipeline (returns immediately)
      print("🧪 Triggering processing...");
      await _triggerAudioProcessing();
      if (!mounted) return;

      // Clean up local file
      await _audioService.deleteRecording(_audioFilePath!);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Your visit is being processed'),
          content: const Text(
            'This may take ~30–60 seconds.\n'
            "You can continue using the app. We’ll notify you when it’s ready.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/patient/home');
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload audio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    print("🧪 Inside _triggerAudioProcessing()");

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

    print("🧪 process-audio status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to trigger audio processing: ${response.statusCode}');
    }
  }

  void _handleClose() {
    if (_recordingState == RecordingState.recording) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stop Recording?'),
          content: const Text(
              'Are you sure you want to stop recording? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Recording'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _stopRecording();
                if (!mounted) return;
                context.go('/patient/home');
              },
              child: const Text('Stop & Discard'),
            ),
          ],
        ),
      );
    } else {
      context.go('/patient/home');
    }
  }

  void _updateFormattedTime() {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    _formattedTime = '$minutes:$seconds';
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
        return 'Ready to Record';
      case RecordingState.recording:
        return 'Recording...';
      case RecordingState.completed:
        return 'Recording complete';
    }
  }

  String _getRecordingInstructions() {
    switch (_recordingState) {
      case RecordingState.idle:
        return 'Tap to start recording your visit\nYour recording stays private and secure';
      case RecordingState.recording:
        return 'Recording in progress...';
      case RecordingState.completed:
        return 'Recording complete!\nTap Generate to process your visit summary';
    }
  }

  Future<bool> _showAudioConsentDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Audio Recording'),
              content: const Text(
                'Recording helps create visit notes, summaries, and reminders.\n\n'
                '• Audio is recorded only when you tap Record\n'
                '• Recordings are processed securely and deleted from your phone\n'
                '• You can stop recording at any time\n\n'
                'Would you like to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _consentService.acceptAudioConsent();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Yes, Record'),
                ),
              ],
            );
          },
        ) ??
        false;
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
