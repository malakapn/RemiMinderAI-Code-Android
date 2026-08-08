import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/supported_languages.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';

/// Live Hydra S2S translate session (server-proxied).
class VoxLiveSession {
  VoxLiveSession({
    required this.sourceLanguage,
    required this.targetLanguage,
    this.mode = 'translate',
    this.timezone = 'UTC',
  });

  final String sourceLanguage;
  final String targetLanguage;
  final String mode;
  final String timezone;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription? _wsSub;
  final BytesBuilder _pcmOut = BytesBuilder(copy: false);
  bool _active = false;
  String? lastStatus;

  bool get isActive => _active;

  Future<void> start({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
    void Function(String transcript)? onTranscript,
  }) async {
    if (_active) return;
    final token = await AuthService().getAccessToken();
    if (token == null) {
      onError('Authentication required.');
      return;
    }

    final uri = BackendApiService().voxLiveWebSocketUri(
      accessToken: token,
      mode: mode,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      timezone: timezone,
    );

    _channel = WebSocketChannel.connect(uri);
    _active = true;
    lastStatus = 'Connecting…';
    onStatus(lastStatus!);

    _wsSub = _channel!.stream.listen(
      (event) async {
        try {
          final data = event is String
              ? json.decode(event) as Map<String, dynamic>
              : <String, dynamic>{};
          final type = data['type']?.toString() ?? '';
          if (type == 'remivox.ready' || type == 'session.configured') {
            lastStatus = 'Listening — speak naturally';
            onStatus(lastStatus!);
            await _startMic();
          } else if (type == 'response.output_audio.delta') {
            final delta = data['delta']?.toString();
            if (delta != null && delta.isNotEmpty) {
              _pcmOut.add(base64Decode(delta));
            }
          } else if (type == 'response.output_audio.done' ||
              type == 'response.done') {
            await _flushPlayback();
          } else if (type == 'response.output_audio_transcript.delta' ||
              type == 'response.output_text.delta') {
            final t = data['delta']?.toString();
            if (t != null && t.isNotEmpty) onTranscript?.call(t);
          } else if (type == 'error') {
            final msg = data['error'] is Map
                ? (data['error']['message']?.toString() ?? 'Live session error')
                : 'Live session error';
            onError(msg);
          } else if (type == 'remivox.tool_result') {
            onStatus('Updated: ${data['name'] ?? 'action'}');
          }
        } catch (e) {
          onError(e.toString());
        }
      },
      onError: (e) => onError(e.toString()),
      onDone: () {
        _active = false;
        onStatus('Session ended');
      },
    );
  }

  Future<void> _startMic() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      throw Exception('Microphone permission is required for Live Translate.');
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: VoxAudioConfig.inputSampleRate,
        numChannels: VoxAudioConfig.inputChannels,
      ),
    );
    _micSub = stream.listen((chunk) {
      if (!_active || _channel == null) return;
      _channel!.sink.add(chunk);
    });
  }

  Future<void> _flushPlayback() async {
    final bytes = _pcmOut.takeBytes();
    if (bytes.isEmpty) return;
    final wav = _pcm16ToWav(bytes, sampleRate: 48000);
    await _player.stop();
    await _player.play(BytesSource(wav));
  }

  Future<void> stop() async {
    _active = false;
    await _micSub?.cancel();
    _micSub = null;
    try {
      _channel?.sink.add(json.encode({'type': 'client.end'}));
    } catch (_) {}
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    await _recorder.dispose();
  }

  static Uint8List _pcm16ToWav(Uint8List pcm, {required int sampleRate}) {
    final dataSize = pcm.length;
    final byteRate = sampleRate * 2;
    final header = BytesBuilder();
    void writeString(String s) => header.add(ascii.encode(s));
    void writeUint32(int v) {
      header.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    }

    void writeUint16(int v) {
      header.add([v & 0xff, (v >> 8) & 0xff]);
    }

    writeString('RIFF');
    writeUint32(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(1);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(2);
    writeUint16(16);
    writeString('data');
    writeUint32(dataSize);
    return Uint8List.fromList([...header.toBytes(), ...pcm]);
  }
}

String languageLabel(String code) {
  for (final lang in kSupportedLanguages) {
    if (lang.code == code) return lang.nativeName;
  }
  return code;
}
