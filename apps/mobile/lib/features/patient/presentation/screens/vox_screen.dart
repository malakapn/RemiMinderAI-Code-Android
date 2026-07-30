import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/config/supported_languages.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/widgets/upgrade_prompt_sheet.dart';
import '../services/vox_live_session.dart';

class VoxScreen extends ConsumerStatefulWidget {
  const VoxScreen({super.key});

  @override
  ConsumerState<VoxScreen> createState() => _VoxScreenState();
}

class _VoxScreenState extends ConsumerState<VoxScreen> {
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _loading = false;
  bool _playing = false;
  bool _listening = false;
  String? _briefingText;
  Uint8List? _audioBytes;
  String? _error;
  String? _lastAction;
  String _targetLanguage = 'bn';
  VoxLiveSession? _live;
  String _liveStatus = '';
  final StringBuffer _liveTranscript = StringBuffer();

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = ref.read(localeProvider).languageCode;
      if (code != 'en') {
        setState(() => _targetLanguage = normalizeLanguageCode(code));
      }
      _loadBriefing();
    });
  }

  @override
  void dispose() {
    _live?.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<String> _timezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return 'UTC';
    }
  }

  Future<void> _playResponse(Map<String, dynamic> data) async {
    final text = data['text']?.toString() ?? 'Vox has nothing to say right now.';
    final audio = data['audio_base64'] as String?;
    setState(() {
      _briefingText = text;
      _lastAction = data['action']?.toString();
      _audioBytes =
          audio == null || audio.isEmpty ? null : base64Decode(audio);
      _error = null;
      _loading = false;
    });
    if (_audioBytes != null) {
      await _playAudio();
    }
  }

  Future<void> _loadBriefing() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lang = ref.read(localeProvider).languageCode;
      final data = await BackendApiService().getVoxTodayBriefing(
        replyLanguage: lang,
      );
      await _playResponse(data);
      await AnalyticsService.instance.voxInteraction(1);
    } catch (e) {
      await _handleError(e);
    }
  }

  Future<void> _handleError(Object e) async {
    final message = e.toString();
    setState(() {
      _error = message;
      _loading = false;
    });
    if (message.toLowerCase().contains('premium') && mounted) {
      await AnalyticsService.instance.featureGated('remivox', 'FREE');
      if (!mounted) return;
      await showUpgradePromptSheet(
        context,
        reason: UpgradePromptReason.voxLocked,
        screen: 'vox',
      );
    }
  }

  Future<void> _askWithMic({String? preset}) async {
    if (_loading || (_live?.isActive ?? false)) return;
    setState(() {
      _loading = true;
      _listening = true;
      _error = null;
    });
    try {
      final prompt = preset ?? await _listenForPrompt();
      setState(() => _listening = false);
      if (prompt == null || prompt.trim().isEmpty) {
        await _loadBriefing();
        return;
      }
      final data = await BackendApiService().askVox(
        prompt.trim(),
        replyLanguage: ref.read(localeProvider).languageCode,
        timezone: await _timezone(),
      );
      await _playResponse(data);
      await AnalyticsService.instance.voxInteraction(1);
      final action = data['action']?.toString();
      if (action == 'open_live_translate' && mounted) {
        await _startLiveTranslate();
      }
    } catch (e) {
      setState(() => _listening = false);
      await _handleError(e);
    }
  }

  Future<String?> _listenForPrompt() async {
    try {
      final available = await _speech.initialize();
      if (!available) return null;
      var heard = '';
      await _speech.listen(
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        onResult: (result) {
          heard = result.recognizedWords;
        },
      );
      await Future<void>.delayed(const Duration(seconds: 6));
      await _speech.stop();
      return heard;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startLiveTranslate() async {
    if (_live?.isActive ?? false) {
      await _stopLive();
      return;
    }
    final source = 'en';
    final target = _targetLanguage == 'en' ? 'bn' : _targetLanguage;
    final session = VoxLiveSession(
      sourceLanguage: source,
      targetLanguage: target,
      mode: 'translate',
      timezone: await _timezone(),
    );
    setState(() {
      _live = session;
      _liveStatus = 'Starting live translate…';
      _liveTranscript.clear();
      _error = null;
    });
    try {
      await session.start(
        onStatus: (s) {
          if (mounted) setState(() => _liveStatus = s);
        },
        onError: (m) {
          if (mounted) {
            setState(() {
              _error = m;
              _liveStatus = 'Error';
            });
          }
        },
        onTranscript: (t) {
          if (mounted) {
            setState(() => _liveTranscript.write(t));
          }
        },
      );
      await AnalyticsService.instance.voxInteraction(1);
    } catch (e) {
      await _handleError(e);
      await session.dispose();
      if (mounted) setState(() => _live = null);
    }
  }

  Future<void> _stopLive() async {
    await _live?.stop();
    if (mounted) {
      setState(() {
        _liveStatus = 'Stopped';
      });
    }
  }

  Future<void> _playAudio() async {
    final bytes = _audioBytes;
    if (bytes == null || bytes.isEmpty) return;
    await _player.stop();
    setState(() => _playing = true);
    await _player.play(BytesSource(bytes));
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveActive = _live?.isActive ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Vox'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Vox care voice',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set reminders, check in on doses, hear summaries, caregiver briefs, '
                      'and live-translate across Remi’s languages. Not medical advice.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2D2D2D),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    label: 'Ask Vox',
                    icon: Icons.mic,
                    onTap: _loading ? null : () => _askWithMic(),
                  ),
                  _ActionChip(
                    label: 'Today',
                    icon: Icons.wb_sunny_outlined,
                    onTap: _loading ? null : _loadBriefing,
                  ),
                  _ActionChip(
                    label: 'Set reminder',
                    icon: Icons.alarm_add,
                    onTap: _loading ? null : () => _askWithMic(),
                  ),
                  _ActionChip(
                    label: 'I took it',
                    icon: Icons.check_circle_outline,
                    onTap: _loading
                        ? null
                        : () => _askWithMic(preset: 'I took my medication'),
                  ),
                  _ActionChip(
                    label: 'Care brief',
                    icon: Icons.family_restroom,
                    onTap: _loading
                        ? null
                        : () => _askWithMic(preset: 'Give me a caregiver brief'),
                  ),
                  _ActionChip(
                    label: 'Last summary',
                    icon: Icons.notes,
                    onTap: _loading
                        ? null
                        : () => _askWithMic(preset: 'Read my last summary'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _targetLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Live translate to',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final lang in kSupportedLanguages)
                          if (lang.code != 'en')
                            DropdownMenuItem(
                              value: lang.code,
                              child: Text('${lang.nativeName} (${lang.code})'),
                            ),
                      ],
                      onChanged: liveActive
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _targetLanguage = v);
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: _loading ? null : _startLiveTranslate,
                    icon: Icon(liveActive ? Icons.stop : Icons.translate),
                    label: Text(liveActive ? 'Stop' : 'Live'),
                  ),
                ],
              ),
              if (_liveStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _liveStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _loading || _listening
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(_listening ? 'Listening…' : 'Working…'),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_lastAction != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Action: $_lastAction',
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ),
                                  Text(
                                    _briefingText ??
                                        'Tap Ask Vox or Live to begin.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF2D2D2D),
                                      height: 1.45,
                                    ),
                                  ),
                                  if (_liveTranscript.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Live transcript',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    Text(_liveTranscript.toString()),
                                  ],
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _audioBytes == null
                          ? null
                          : (_playing ? _stopAudio : _playAudio),
                      icon: Icon(_playing ? Icons.stop : Icons.volume_up),
                      label: Text(_playing ? 'Stop' : 'Play Vox'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: (_loading || liveActive) ? null : _loadBriefing,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: “Set a reminder for Allegra every day at 8 pm” · '
                '“I took Metoprolol” · “Read my last summary”',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C5C5C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
