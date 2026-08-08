import 'environment.dart';
import 'supported_languages.dart';

abstract final class VoxConfig {
  static const String streamPath = '/api/remivox/stream';
  static const String livePath = '/api/remivox/live';
  static const String todayPath = '/api/remivox/today';
  static const String askPath = '/api/remivox/ask';
  static const String translateTurnPath = '/api/remivox/translate-turn';

  static const String defaultLanguage = kDefaultLanguageCode;
  static const String defaultTimezone = 'UTC';
  static const String defaultLiveMode = 'translate';
  static const String defaultTranslateTargetLanguage = 'bn';
  static const String wavContentType = 'audio/wav';

  static bool get usePipecatStream =>
      Environment.remivoxUsePipecatStream;
  static Duration get silenceTimeout => Duration(
    seconds: Environment.remivoxSilenceTimeoutSeconds,
  );

  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const int hydraOutputSampleRate = 48000;
  static const int inputChannels = 1;
  static const int bytesPerSample = 2;
  static const int chunkDurationMilliseconds = 200;
  static const int inputChunkBytes =
      inputSampleRate * bytesPerSample * chunkDurationMilliseconds ~/ 1000;

  static const Duration initialListenTimeout = Duration(seconds: 5);
  static const Duration followUpListenTimeout = Duration(seconds: 15);
  static const Duration speechEndDebounce = Duration(milliseconds: 500);
  static const Duration playbackChunkTimeout = Duration(seconds: 10);
  static const Duration ttsCompletionTimeout = Duration(seconds: 45);
  static const Duration connectivityPollInterval = Duration(seconds: 3);
  static const Duration textResponseDelay = Duration(milliseconds: 900);

  static const int speechEnergyThreshold = 400;
  static const int maxCareAskTurns = 6;
}
