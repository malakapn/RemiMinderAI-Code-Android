import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key for the user's chosen app language code.
const String kPreferredLanguagePrefsKey = 'preferred_language';

/// Locale notifier: persists to SharedPreferences + Firestore `preferredLanguage`.
class LocaleNotifier extends Notifier<Locale> {

  @override
  Locale build() {
    Future.microtask(_loadSavedLocale);
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(kPreferredLanguagePrefsKey) ?? 'en';
      if (code != state.languageCode) {
        state = Locale(code);
      }
    } catch (_) {
      // Keep default [Locale('en')].
    }
  }

  /// Update the current locale and persist.
  Future<void> setLocale(Locale locale) async {
    await setLocaleFromString(locale.languageCode);
  }

  /// Set locale from a BCP-47 language code (e.g. en, es, hi).
  Future<void> setLocaleFromString(String languageCode) async {
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPreferredLanguagePrefsKey, languageCode);
    } catch (_) {
      // Ignore persistence failures; in-memory locale still updates.
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'preferredLanguage': languageCode},
          SetOptions(merge: true),
        );
      } catch (_) {
        // Skip Firestore when offline / permission denied.
      }
    }
  }
}

/// Riverpod provider for locale state management
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
