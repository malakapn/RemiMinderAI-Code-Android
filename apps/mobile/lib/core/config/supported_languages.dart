/// App + visit-summary language codes supported end-to-end.
const Set<String> kSupportedLanguageCodes = {
  'en',
  'es',
  'hi',
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
  return kSupportedLanguageCodes.contains(code) ? code : 'en';
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
  SupportedLanguage(code: 'en', nativeName: 'English'),
  SupportedLanguage(code: 'es', nativeName: 'Español'),
  SupportedLanguage(code: 'hi', nativeName: 'हिन्दी'),
  SupportedLanguage(code: 'fr', nativeName: 'Français'),
  SupportedLanguage(code: 'pt', nativeName: 'Português'),
  SupportedLanguage(code: 'de', nativeName: 'Deutsch'),
  SupportedLanguage(code: 'bn', nativeName: 'বাংলা'),
  SupportedLanguage(code: 'ta', nativeName: 'தமிழ்'),
  SupportedLanguage(code: 'gu', nativeName: 'ગુજરાતી'),
  SupportedLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ'),
];
