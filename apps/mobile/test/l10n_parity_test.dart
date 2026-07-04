import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:RemiMinder/core/config/supported_languages.dart';

void main() {
  test('all supported languages have complete ARB files', () {
    final arbDir = Directory('lib/l10n');
    final enFile = File('lib/l10n/app_en.arb');
    expect(enFile.existsSync(), isTrue);

    final en = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
    final enKeys = {
      for (final key in en.keys)
        if (!key.startsWith('@')) key,
    };

    expect(kSupportedLanguageCodes.length, 10);
    expect(kSupportedLanguages.length, 10);

    for (final code in kSupportedLanguageCodes) {
      final path = File('${arbDir.path}/app_$code.arb');
      expect(path.existsSync(), isTrue, reason: 'Missing app_$code.arb');

      final loc = json.decode(path.readAsStringSync()) as Map<String, dynamic>;
      final locKeys = {
        for (final key in loc.keys)
          if (!key.startsWith('@')) key,
      };

      final missing = enKeys.difference(locKeys);
      expect(
        missing,
        isEmpty,
        reason: 'app_$code.arb missing keys: ${missing.take(5).join(", ")}',
      );
    }
  });
}
