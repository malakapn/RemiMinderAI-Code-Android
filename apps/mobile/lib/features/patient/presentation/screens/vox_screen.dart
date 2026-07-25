import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/widgets/upgrade_prompt_sheet.dart';

class VoxScreen extends StatefulWidget {
  const VoxScreen({super.key});

  @override
  State<VoxScreen> createState() => _VoxScreenState();
}

class _VoxScreenState extends State<VoxScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = true;
  bool _playing = false;
  String? _briefingText;
  Uint8List? _audioBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBriefing();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadBriefing() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await BackendApiService().getVoxTodayBriefing();
      final audio = data['audio_base64'] as String?;
      setState(() {
        _briefingText = data['text']?.toString();
        _audioBytes = audio == null || audio.isEmpty ? null : base64Decode(audio);
        _loading = false;
      });
      await AnalyticsService.instance.voxInteraction(1);
      if (_audioBytes != null) {
        await _playAudio();
      }
    } catch (e) {
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
                padding: const EdgeInsets.all(22),
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
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC9A84C),
                          width: 4,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Vox',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Today's care briefing",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vox reads your reminders and visit summaries aloud. It does not replace medical advice.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2D2D2D),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Text(
                                _briefingText ?? 'Vox has nothing to read right now.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF2D2D2D),
                                  height: 1.45,
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 18),
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
                    onPressed: _loading ? null : _loadBriefing,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
