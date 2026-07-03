import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/locale_provider.dart';

const Map<String, String> _kLanguageCodeToEnglishName = {
  'en': 'English',
  'es': 'Spanish',
  'hi': 'Hindi',
  'fr': 'French',
  'pt': 'Portuguese',
  'de': 'German',
  'bn': 'Bengali',
  'ta': 'Tamil',
  'gu': 'Gujarati',
  'pa': 'Punjabi',
};

/// Reads the saved language code used for Gemini visit-summary generation.
Future<String> readPreferredLanguageCodeForVisitSummary() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kPreferredLanguagePrefsKey) ?? 'en';
}

String _languageDisplayName(String code) =>
    _kLanguageCodeToEnglishName[code.toLowerCase()] ?? 'English';

/// Line prefixed to the Vertex Gemini visit-summary prompt on the server.
///
/// Uses the same [SharedPreferences] key as the app locale so summaries
/// match the user's chosen language.
Future<String> buildVisitSummaryGeminiLanguageInstruction() async {
  final code = await readPreferredLanguageCodeForVisitSummary();
  return geminiLanguageInstructionForCode(code);
}

String geminiLanguageInstructionForCode(String languageCode) {
  final language = _languageDisplayName(languageCode);
  return 'Generate the entire response in $language language.';
}
