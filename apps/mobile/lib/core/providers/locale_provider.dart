import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple locale notifier using Notifier
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en'); // Default to English
  }

  /// Update the current locale
  void setLocale(Locale locale) {
    state = locale;
  }

  /// Get locale from language code string
  void setLocaleFromString(String languageCode) {
    state = Locale(languageCode);
  }
}

/// Riverpod provider for locale state management
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
