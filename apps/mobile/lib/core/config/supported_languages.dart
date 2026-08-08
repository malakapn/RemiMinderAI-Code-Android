/// App + visit-summary language codes supported end-to-end.
const String kDefaultLanguageCode = 'en';
const String kHindiLanguageCode = 'hi';

const Set<String> kSupportedLanguageCodes = {
  kDefaultLanguageCode,
  'es',
  kHindiLanguageCode,
  'fr',
  'pt',
  'de',
  'bn',
  'ta',
  'gu',
  'pa',
};

String normalizeLanguageCode(String raw) {
  final code = raw.trim().toLowerCase();
  return kSupportedLanguageCodes.contains(code)
      ? code
      : kDefaultLanguageCode;
}

const Set<String> kVoxSupportedLanguageCodes = {
  kDefaultLanguageCode,
  kHindiLanguageCode,
};

String normalizeVoxLanguageCode(String raw) {
  final code = raw.trim().toLowerCase();
  return kVoxSupportedLanguageCodes.contains(code)
      ? code
      : kDefaultLanguageCode;
}

abstract final class VoxAudioConfig {
  static const int inputSampleRate = 16000;
  static const int outputSampleRate = 24000;
  static const int inputChannels = 1;
  static const int bytesPerSample = 2;
  static const int chunkDurationMilliseconds = 200;
  static const int inputChunkBytes =
      inputSampleRate * bytesPerSample * chunkDurationMilliseconds ~/ 1000;
}

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.nativeName,
  });

  final String code;
  final String nativeName;
}

const List<SupportedLanguage> kSupportedLanguages = [
  SupportedLanguage(code: kDefaultLanguageCode, nativeName: 'English'),
  SupportedLanguage(code: 'es', nativeName: 'Español'),
  SupportedLanguage(code: kHindiLanguageCode, nativeName: 'हिन्दी'),
  SupportedLanguage(code: 'fr', nativeName: 'Français'),
  SupportedLanguage(code: 'pt', nativeName: 'Português'),
  SupportedLanguage(code: 'de', nativeName: 'Deutsch'),
  SupportedLanguage(code: 'bn', nativeName: 'বাংলা'),
  SupportedLanguage(code: 'ta', nativeName: 'தமிழ்'),
  SupportedLanguage(code: 'gu', nativeName: 'ગુજરાતી'),
  SupportedLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ'),
];
