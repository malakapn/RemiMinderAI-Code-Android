import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user consent acknowledgments for media features
///
/// Stores non-PHI consent flags locally to avoid repeated consent prompts
/// for microphone and camera usage in healthcare contexts.
class ConsentService {
  /// Legacy single-party audio consent (pre two-party dialog).
  static const String _legacyAudioConsentKey = 'hasAcceptedAudioConsent';

  /// Two-party recording consent (required before first record).
  static const String _twoPartyAudioConsentKey =
      'hasAcceptedTwoPartyRecordingConsent';

  static const String _cameraConsentKey = 'hasAcceptedCameraConsent';

  /// Whether the user accepted the two-party recording consent dialog.
  Future<bool> hasAcceptedAudioConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_twoPartyAudioConsentKey) ?? false;
  }

  /// Persist two-party recording consent (also marks legacy key for compatibility).
  Future<void> acceptAudioConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoPartyAudioConsentKey, true);
    await prefs.setBool(_legacyAudioConsentKey, true);
  }

  /// Check if user has accepted camera scanning consent
  Future<bool> hasAcceptedCameraConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cameraConsentKey) ?? false;
  }

  /// Mark camera consent as accepted
  Future<void> acceptCameraConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cameraConsentKey, true);
  }

  /// Clear all consent flags (optional, for logout scenarios)
  Future<void> clearAllConsents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyAudioConsentKey);
    await prefs.remove(_twoPartyAudioConsentKey);
    await prefs.remove(_cameraConsentKey);
  }
}
