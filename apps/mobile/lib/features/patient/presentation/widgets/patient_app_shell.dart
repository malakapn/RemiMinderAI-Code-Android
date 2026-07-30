import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/config/supported_languages.dart';
import '../../../../core/providers/locale_provider.dart';
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

          if (widget.routes == null)
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
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _busy = false;
  bool _liveActive = false;
  VoxLiveSession? _live;

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

  Future<String> _preferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return normalizeLanguageCode(
        prefs.getString(kPreferredLanguagePrefsKey) ?? 'en',
      );
    } catch (_) {
      return 'en';
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleTap() async {
    // Second tap during live translate stops the session in place.
    if (_liveActive) {
      await _stopLive();
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final prompt = await _listenForPrompt();
      final tz = await _timezone();
      final lang = await _preferredLanguage();
      final wantsTranslate = prompt != null &&
          prompt.toLowerCase().contains('translate');

      if (wantsTranslate) {
        var target = lang == 'en' ? 'bn' : lang;
        for (final entry in const {
          'bangla': 'bn',
          'bengali': 'bn',
          'hindi': 'hi',
          'spanish': 'es',
          'french': 'fr',
          'portuguese': 'pt',
          'german': 'de',
          'tamil': 'ta',
          'gujarati': 'gu',
          'punjabi': 'pa',
          'english': 'en',
        }.entries) {
          if (prompt!.toLowerCase().contains(entry.key)) {
            target = entry.value;
            break;
          }
        }
        await _startLiveInPlace(targetLanguage: target);
        return;
      }

      final data = prompt == null || prompt.trim().isEmpty
          ? await BackendApiService().getVoxTodayBriefing(replyLanguage: lang)
          : await BackendApiService().askVox(
              prompt.trim(),
              replyLanguage: lang,
              timezone: tz,
            );
      final text =
          data['text']?.toString() ?? 'Vox has nothing to read right now.';
      final audio = data['audio_base64'] as String?;
      if (audio != null && audio.isNotEmpty) {
        await _playAudio(base64Decode(audio));
      } else {
        _snack(text);
      }

      final action = data['action']?.toString();
      if (action == 'start_live_translate') {
        final payload = data['action_payload'];
        final target = payload is Map
            ? normalizeLanguageCode(
                payload['target_language']?.toString() ?? 'bn',
              )
            : (lang == 'en' ? 'bn' : lang);
        await _startLiveInPlace(targetLanguage: target);
      }
    } catch (e) {
      final message = e.toString();
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
    } finally {
      if (mounted && !_liveActive) setState(() => _busy = false);
    }
  }

  Future<void> _startLiveInPlace({required String targetLanguage}) async {
    final session = VoxLiveSession(
      sourceLanguage: 'en',
      targetLanguage: targetLanguage == 'en' ? 'bn' : targetLanguage,
      mode: 'translate',
      timezone: await _timezone(),
    );
    setState(() {
      _live = session;
      _liveActive = true;
      _busy = true;
    });
    _snack(
      'Vox live translate on (${languageLabel(session.targetLanguage)}). '
      'Tap Vox again to stop.',
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

  Future<String?> _listenForPrompt() async {
    try {
      final available = await _speech.initialize();
      if (!available) return null;
      var heard = '';
      _snack('Vox is listening...');
      await _speech.listen(
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        onResult: (result) {
          heard = result.recognizedWords;
        },
      );
      await Future<void>.delayed(const Duration(seconds: 5));
      await _speech.stop();
      return heard;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playAudio(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes));
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
              color: _liveActive
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
                Text(
                  _liveActive ? 'Live' : "Ask",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                Text(
                  _liveActive ? 'Tap stop' : 'me',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
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
    // Default to home for unknown routes
    return NavigationItem.home;
  }
}
