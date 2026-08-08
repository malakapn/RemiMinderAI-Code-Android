import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/supported_languages.dart';
import '../../../../core/config/vox_config.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/widgets/upgrade_prompt_sheet.dart';
import '../services/vox_live_session.dart';
import 'rounded_navigation_bar.dart';

/// App shell that wraps all patient screens with a floating bottom navigation bar
class PatientAppShell extends StatefulWidget {
  final Widget child;
  final NavigationItem currentItem;
  final Map<NavigationItem, String>? routes;

  const PatientAppShell({
    super.key,
    required this.child,
    required this.currentItem,
    this.routes,
  });

  @override
  State<PatientAppShell> createState() => _PatientAppShellState();
}

class _PatientAppShellState extends State<PatientAppShell> {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: 70 + 12 + 16 + bottomInset,
            ),
            child: widget.child,
          ),

          if (widget.routes == null && widget.currentItem.index == 0)
            Positioned(
              right: 56,
              bottom: bottomInset + 102,
              child: const _VoxFloatingButton(),
            ),

          // Floating navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: RoundedNavigationBar(
              currentItem: widget.currentItem,
              routes: widget.routes,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoxFloatingButton extends StatelessWidget {
  const _VoxFloatingButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Vox',
      child: const _VoxButtonBody(),
    );
  }
}

class _VoxButtonBody extends StatefulWidget {
  const _VoxButtonBody();

  @override
  State<_VoxButtonBody> createState() => _VoxButtonBodyState();
}

class _VoxButtonBodyState extends State<_VoxButtonBody> {
  static const Duration _initialListenFor =
      VoxConfig.initialListenTimeout;
  static const Duration _followUpListenFor =
      VoxConfig.followUpListenTimeout;
  static final Duration _pipecatSilenceTimeout =
      VoxConfig.silenceTimeout;
  static const int _pipecatMicChunkBytes = VoxConfig.inputChunkBytes;

  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  final BackendApiService _backendApi = BackendApiService();
  bool _usePipecatStream = VoxConfig.usePipecatStream;
  bool _busy = false;
  bool _liveActive = false;
  bool _pipecatActive = false;
  bool _pipecatSpeaking = false;
  bool _pipecatPlaying = false;
  bool _pipecatWaiting = false;
  bool _handlingPipecatDisconnect = false;
  bool _awaitingFollowUp = false;
  VoxLiveSession? _live;
  String? _voxSessionId;
  StreamSubscription<Uint8List>? _pipecatMicSubscription;
  StreamSubscription<Uint8List>? _pipecatAudioSubscription;
  Timer? _pipecatSilenceTimer;
  Timer? _pipecatSpeechResetTimer;
  final BytesBuilder _pipecatMicBuffer = BytesBuilder(copy: false);
  Future<void> _pipecatPlaybackQueue = Future<void>.value();
  Completer<void>? _pipecatPlaybackInterrupted;
  int _pipecatPlaybackGeneration = 0;
  int _pipecatQueuedAudioChunks = 0;

  bool get _voiceLiveActive => _liveActive || _pipecatActive;
  String get _voxStatusTop {
    if (_pipecatWaiting) return 'Thinking';
    if (_pipecatActive) return 'Listening';
    if (_liveActive) return 'Live';
    if (_awaitingFollowUp) return 'Wait';
    return 'Ask';
  }

  String get _voxStatusBottom {
    if (_pipecatWaiting) return 'Please wait';
    if (_voiceLiveActive) return 'Tap stop';
    if (_awaitingFollowUp) return 'reply';
    return 'me';
  }

  @override
  void dispose() {
    _pipecatSilenceTimer?.cancel();
    _pipecatSpeechResetTimer?.cancel();
    final micSubscription = _pipecatMicSubscription;
    if (micSubscription != null) {
      unawaited(micSubscription.cancel());
    }
    final audioSubscription = _pipecatAudioSubscription;
    if (audioSubscription != null) {
      unawaited(audioSubscription.cancel());
    }
    unawaited(_backendApi.closeVoxStream());
    _live?.dispose();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _timezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return VoxConfig.defaultTimezone;
    }
  }

  Future<String> _preferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return normalizeLanguageCode(
        prefs.getString(kPreferredLanguagePrefsKey) ??
            kDefaultLanguageCode,
      );
    } catch (_) {
      return kDefaultLanguageCode;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _ensureSessionId() {
    final existing = _voxSessionId?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created =
        'vox_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.abs()}';
    _voxSessionId = created;
    return created;
  }

  Map<String, dynamic>? _pendingFromResponse(Map<String, dynamic> data) {
    final top = data['pending'];
    if (top is Map && top['intent'] != null) {
      return Map<String, dynamic>.from(top);
    }
    final payload = data['action_payload'];
    if (payload is Map) {
      final nested = payload['pending'];
      if (nested is Map && nested['intent'] != null) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return null;
  }

  Future<void> _handleTap() async {
    if (_pipecatActive) {
      await _stopPipecatStream();
      return;
    }
    if (_liveActive) {
      await _stopLive();
      return;
    }
    if (_busy) return;

    if (_usePipecatStream) {
      setState(() => _busy = true);
      try {
        await _startPipecatStream();
        return;
      } catch (e) {
        debugPrint('VOX_STREAM_ERROR: $e');
        await _stopPipecatStream(showStatus: false);
        if (mounted) {
          setState(() => _busy = false);
          _snack('Live Vox unavailable. Using standard Vox.');
        }
      }
    }

    setState(() => _busy = true);
    try {
      await _runCareAskLoop(isFollowUp: false);
    } catch (e) {
      final message = e.toString();
      debugPrint('VOX_ERROR: $message');
      if (!mounted) return;
      if (message.toLowerCase().contains('premium') ||
          message.toLowerCase().contains('trial')) {
        await showUpgradePromptSheet(
          context,
          reason: UpgradePromptReason.trialExpired,
          screen: 'patient_shell',
        );
      } else {
        _snack(message);
      }
      _voxSessionId = null;
      _awaitingFollowUp = false;
    } finally {
      if (mounted && !_voiceLiveActive) {
        setState(() {
          _busy = false;
          _awaitingFollowUp = false;
        });
      }
    }
  }

  Future<void> _startPipecatStream() async {
    final token = await AuthService().getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please log in again.');
    }
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission is required for Vox.');
    }

    final preferredLanguage = await _preferredLanguage();
    final language = normalizeVoxLanguageCode(preferredLanguage);
    _pipecatMicBuffer.takeBytes();
    _pipecatQueuedAudioChunks = 0;
    _pipecatWaiting = false;
    _pipecatPlaying = false;
    await _backendApi.connectVoxStream(token: token, language: language);

    _pipecatAudioSubscription = _backendApi.voxAudioStream.listen(
      _handlePipecatAudioChunk,
      onError: (Object error) {
        debugPrint('VOX_STREAM_AUDIO_ERROR: $error');
        unawaited(_handlePipecatConnectionLost());
      },
      onDone: () {
        unawaited(_handlePipecatConnectionLost());
      },
    );

    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: VoxConfig.inputSampleRate,
        numChannels: VoxConfig.inputChannels,
      ),
    );

    if (!mounted) {
      await _backendApi.closeVoxStream();
      return;
    }
    setState(() {
      _pipecatActive = true;
      _busy = false;
    });
    _snack('Vox is listening... tap Vox to stop.');
    _resetPipecatTimeout();

    _pipecatMicSubscription = micStream.listen(
      _handlePipecatMicChunk,
      onError: (Object error) {
        debugPrint('VOX_STREAM_MIC_ERROR: $error');
        unawaited(_handlePipecatConnectionLost());
      },
    );
  }

  void _handlePipecatMicChunk(Uint8List chunk) {
    if (!_pipecatActive || chunk.isEmpty) return;
    _pipecatMicBuffer.add(chunk);
    final buffered = _pipecatMicBuffer.takeBytes();
    var offset = 0;
    while (buffered.length - offset >= _pipecatMicChunkBytes) {
      _backendApi.sendAudioChunk(
        Uint8List.fromList(
          buffered.sublist(offset, offset + _pipecatMicChunkBytes),
        ),
      );
      offset += _pipecatMicChunkBytes;
    }
    if (offset < buffered.length) {
      _pipecatMicBuffer.add(buffered.sublist(offset));
    }

    if (_pcmChunkHasSpeech(chunk)) {
      _resetPipecatTimeout();
      if (!_pipecatSpeaking) {
        _pipecatSpeaking = true;
        _pipecatPlaybackGeneration++;
        _pipecatPlaying = false;
        _pipecatWaiting = false;
        final interrupted = _pipecatPlaybackInterrupted;
        if (interrupted != null && !interrupted.isCompleted) {
          interrupted.complete();
        }
        if (mounted) {
          setState(() => _busy = false);
        }
        unawaited(_player.stop());
      }
      _pipecatSpeechResetTimer?.cancel();
      _pipecatSpeechResetTimer = Timer(
        VoxConfig.speechEndDebounce,
        () {
          _pipecatSpeaking = false;
          if (_pipecatActive && !_pipecatPlaying && mounted) {
            setState(() {
              _pipecatWaiting = true;
              _busy = true;
            });
          }
        },
      );
    }
  }

  void _handlePipecatAudioChunk(Uint8List chunk) {
    if (!_pipecatActive || chunk.isEmpty) return;
    _pipecatSilenceTimer?.cancel();
    _pipecatWaiting = false;
    _pipecatQueuedAudioChunks++;
    if (mounted) {
      setState(() => _busy = false);
    }
    final generation = _pipecatPlaybackGeneration;
    _pipecatPlaybackQueue = _pipecatPlaybackQueue.then((_) async {
      try {
        if (!_pipecatActive || generation != _pipecatPlaybackGeneration) {
          return;
        }
        await _playPipecatPcmChunk(chunk);
      } finally {
        _pipecatQueuedAudioChunks--;
        if (_pipecatQueuedAudioChunks <= 0) {
          _pipecatQueuedAudioChunks = 0;
          _pipecatPlaying = false;
          if (_pipecatActive) {
            _pipecatWaiting = false;
            if (mounted) {
              setState(() => _busy = false);
            }
            _resetPipecatTimeout();
          }
        }
      }
    });
  }

  void _resetPipecatTimeout() {
    _pipecatSilenceTimer?.cancel();
    _pipecatSilenceTimer = Timer(_pipecatSilenceTimeout, () {
      unawaited(_stopPipecatStream());
    });
  }

  bool _pcmChunkHasSpeech(
    Uint8List bytes, {
    int threshold = VoxConfig.speechEnergyThreshold,
  }) {
    for (var i = 0; i + 1 < bytes.length; i += 4) {
      final sample = bytes[i] | (bytes[i + 1] << 8);
      final signed = sample > 32767 ? sample - 65536 : sample;
      if (signed.abs() >= threshold) return true;
    }
    return false;
  }

  Future<void> _playPipecatPcmChunk(Uint8List pcm) async {
    final wav = _pcm16ToWav(
      pcm,
      sampleRate: VoxConfig.outputSampleRate,
    );
    final done = _player.onPlayerComplete.first;
    final interrupted = Completer<void>();
    _pipecatPlaybackInterrupted = interrupted;
    _pipecatPlaying = true;
    _pipecatWaiting = false;
    if (mounted) {
      setState(() => _busy = false);
    }
    await _player.play(
      BytesSource(wav, mimeType: VoxConfig.wavContentType),
    );
    try {
      await Future.any<void>([
        done,
        interrupted.future,
      ]).timeout(VoxConfig.playbackChunkTimeout);
    } on TimeoutException {
      await _player.stop();
    } finally {
      if (identical(_pipecatPlaybackInterrupted, interrupted)) {
        _pipecatPlaybackInterrupted = null;
      }
    }
  }

  Future<void> _handlePipecatConnectionLost() async {
    if (_handlingPipecatDisconnect) return;
    _handlingPipecatDisconnect = true;
    try {
      await _stopPipecatStream(showStatus: false);
      if (mounted) {
        _snack('Connection lost. Tap Vox to reconnect.');
      }
    } finally {
      _handlingPipecatDisconnect = false;
    }
  }

  Future<void> _stopPipecatStream({bool showStatus = true}) async {
    final wasActive = _pipecatActive;
    final remainingAudio = _pipecatMicBuffer.takeBytes();
    if (wasActive && remainingAudio.isNotEmpty) {
      try {
        _backendApi.sendAudioChunk(remainingAudio);
      } catch (_) {}
    }
    _pipecatActive = false;
    _pipecatPlaying = false;
    _pipecatWaiting = false;
    _pipecatQueuedAudioChunks = 0;
    _pipecatPlaybackGeneration++;
    final interrupted = _pipecatPlaybackInterrupted;
    if (interrupted != null && !interrupted.isCompleted) {
      interrupted.complete();
    }
    _pipecatSilenceTimer?.cancel();
    _pipecatSilenceTimer = null;
    _pipecatSpeechResetTimer?.cancel();
    _pipecatSpeechResetTimer = null;
    _pipecatSpeaking = false;

    await _pipecatMicSubscription?.cancel();
    _pipecatMicSubscription = null;
    await _pipecatAudioSubscription?.cancel();
    _pipecatAudioSubscription = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    await _backendApi.closeVoxStream();
    await _player.stop();

    if (mounted) {
      setState(() => _busy = false);
      if (showStatus && wasActive) _snack('Talk to me anytime!');
    }
  }

  Uint8List _pcm16ToWav(Uint8List pcm, {required int sampleRate}) {
    final header = BytesBuilder();

    void writeString(String value) => header.add(ascii.encode(value));
    void writeUint32(int value) {
      header.add([
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ]);
    }

    void writeUint16(int value) {
      header.add([value & 0xff, (value >> 8) & 0xff]);
    }

    writeString('RIFF');
    writeUint32(36 + pcm.length);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(1);
    writeUint32(sampleRate);
    writeUint32(sampleRate * 2);
    writeUint16(2);
    writeUint16(16);
    writeString('data');
    writeUint32(pcm.length);
    return Uint8List.fromList([...header.toBytes(), ...pcm]);
  }

  /// Sequential POST /api/remivox/ask turns. Reopens mic while [pending] is set.
  Future<void> _runCareAskLoop({required bool isFollowUp}) async {
    final tz = await _timezone();
    final lang = await _preferredLanguage();
    var sessionId = _ensureSessionId();

    _snack(
      isFollowUp
          ? 'Vox is still listening…'
          : 'Vox is listening… speak in any Remi language',
    );
    if (isFollowUp && mounted) {
      setState(() => _awaitingFollowUp = true);
    }

    final initialClip = await _recordPromptClip(
      listenFor: isFollowUp ? _followUpListenFor : _initialListenFor,
      requireSpeech: isFollowUp,
    );

    if (initialClip == null) {
      if (isFollowUp) {
        _clearPendingSession();
        _snack('No worries, you can try again anytime');
        return;
      }
      final briefing = await BackendApiService().getVoxTodayBriefing(
        replyLanguage: lang,
      );
      await _playResponse(briefing);
      _clearPendingSession();
      return;
    }

    var clip = initialClip;
    for (var turn = 0; turn < VoxConfig.maxCareAskTurns; turn++) {
      final data = await BackendApiService().askVox(
        null,
        replyLanguage: lang,
        timezone: tz,
        audioBase64: clip.base64,
        contentType: clip.contentType,
        autoDetectLanguage: true,
        sessionId: sessionId,
      );

      final returnedSession = data['session_id']?.toString().trim();
      if (returnedSession != null && returnedSession.isNotEmpty) {
        sessionId = returnedSession;
        _voxSessionId = returnedSession;
      }

      // Wait for TTS to finish before reopening the mic.
      await _playResponse(data);

      final action = data['action']?.toString();
      if (action == 'start_live_translate') {
        _clearPendingSession();
        final detected = normalizeLanguageCode(
          data['detected_language']?.toString() ?? lang,
        );
        final payload = data['action_payload'];
        final target = payload is Map
            ? normalizeLanguageCode(
                payload['target_language']?.toString() ?? detected,
              )
            : detected;
        await _startLiveInPlace(
          sourceLanguage: detected,
          targetLanguage: target == detected
              ? (detected == kDefaultLanguageCode
                    ? VoxConfig.defaultTranslateTargetLanguage
                    : kDefaultLanguageCode)
              : target,
        );
        return;
      }

      final pending = _pendingFromResponse(data);
      if (pending == null) {
        _clearPendingSession();
        return;
      }

      // Clarification needed — keep session_id and auto-reopen mic.
      if (mounted) setState(() => _awaitingFollowUp = true);
      _snack('Vox is still listening…');
      final followUp = await _recordPromptClip(
        listenFor: _followUpListenFor,
        requireSpeech: true,
      );
      if (followUp == null) {
        _clearPendingSession();
        _snack('No worries, you can try again anytime');
        return;
      }
      clip = followUp;
    }

    _clearPendingSession();
  }

  void _clearPendingSession() {
    _voxSessionId = null;
    _awaitingFollowUp = false;
  }

  Future<void> _playResponse(Map<String, dynamic> data) async {
    final text =
        data['text']?.toString() ?? 'Vox has nothing to read right now.';
    final audio = data['audio_base64'] as String?;
    final detected = data['detected_language']?.toString();
    if (detected != null && detected.isNotEmpty) {
      _snack('Heard ${languageLabel(normalizeLanguageCode(detected))}');
    }
    if (audio != null && audio.isNotEmpty) {
      await _playAudio(base64Decode(audio));
    } else {
      _snack(text);
      // Brief pause so the user can read the clarification before mic reopens.
      await Future<void>.delayed(VoxConfig.textResponseDelay);
    }
  }

  /// True when 16-bit mono WAV PCM has enough energy to count as speech.
  bool _wavHasSpeech(
    Uint8List bytes, {
    int threshold = VoxConfig.speechEnergyThreshold,
  }) {
    if (bytes.length <= 44) return false;
    var peak = 0;
    // Skip 44-byte WAV header; sample every other frame for speed.
    for (var i = 44; i + 1 < bytes.length; i += 4) {
      final sample = bytes[i] | (bytes[i + 1] << 8);
      final signed = sample > 32767 ? sample - 65536 : sample;
      final abs = signed.abs();
      if (abs > peak) peak = abs;
      if (peak >= threshold) return true;
    }
    return false;
  }

  Future<({String base64, String contentType})?> _recordPromptClip({
    Duration listenFor = _initialListenFor,
    bool requireSpeech = false,
  }) async {
    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) return null;
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/vox_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: VoxConfig.inputSampleRate,
          numChannels: VoxConfig.inputChannels,
        ),
        path: path,
      );
      await Future<void>.delayed(listenFor);
      final saved = await _recorder.stop();
      final filePath = saved ?? path;
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      try {
        await file.delete();
      } catch (_) {}
      if (requireSpeech && !_wavHasSpeech(Uint8List.fromList(bytes))) {
        return null;
      }
      return (
        base64: base64Encode(bytes),
        contentType: VoxConfig.wavContentType,
      );
    } catch (_) {
      try {
        if (await _recorder.isRecording()) await _recorder.stop();
      } catch (_) {}
      return null;
    }
  }

  Future<void> _startLiveInPlace({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final session = VoxLiveSession(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      mode: 'translate',
      timezone: await _timezone(),
    );
    setState(() {
      _live = session;
      _liveActive = true;
      _busy = true;
    });
    _snack(
      'Vox live on (${languageLabel(sourceLanguage)} ↔ '
      '${languageLabel(targetLanguage)}). Tap Vox to stop.',
    );
    try {
      await session.start(
        onStatus: (s) {
          if (mounted) _snack(s);
        },
        onError: (m) {
          if (mounted) _snack(m);
        },
      );
    } catch (e) {
      _snack(e.toString());
      await _stopLive();
    }
  }

  Future<void> _stopLive() async {
    await _live?.stop();
    _live = null;
    if (mounted) {
      setState(() {
        _liveActive = false;
        _busy = false;
      });
      _snack('Vox stopped.');
    }
  }

  Future<void> _playAudio(Uint8List bytes) async {
    await _player.stop();
    // Wait until TTS finishes so follow-up mic reopen does not overlap playback.
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    try {
      await done.timeout(VoxConfig.ttsCompletionTimeout);
    } on TimeoutException {
      // Fall through — reopen mic even if completion event was missed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _voiceLiveActive
                  ? const Color(0xFF2E7D32)
                  : Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC9A84C),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Vox',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                if (_pipecatPlaying) ...[
                  const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 13,
                  ),
                  const Text(
                    'Speaking',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ] else ...[
                  Text(
                    _voxStatusTop,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  Text(
                    _voxStatusBottom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_busy)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper function to determine current navigation item based on route
NavigationItem getCurrentNavigationItem(String location) {
  if (location.startsWith('/patient/home')) {
    return NavigationItem.home;
  } else if (location.startsWith('/patient/overview')) {
    return NavigationItem.overview;
  } else if (location.startsWith('/patient/care-team')) {
    return NavigationItem.careTeam;
  } else if (location.startsWith('/patient/profile') ||
      location.startsWith('/patient/language-settings')) {
    return NavigationItem.profile;
  } else if (location.startsWith('/profile')) {
    return NavigationItem.profile;
  } else if (location.startsWith('/caregiver/home')) {
    return NavigationItem.home;
  } else if (location.startsWith('/caregiver/patients')) {
    return NavigationItem.visits;
  } else if (location.startsWith('/caregiver/alerts')) {
    return NavigationItem.overview;
  } else if (location.startsWith('/caregiver/accept-invitations')) {
    return NavigationItem.careTeam;
  } else {
    return NavigationItem.home;
  }
}
