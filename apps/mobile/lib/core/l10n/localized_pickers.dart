import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Flutter Material date/time pickers only ship translations for a subset of
/// locales. Map app locales to the closest Material-supported picker locale.
Locale materialPickerLocale(Locale appLocale) {
  const supported = {'en', 'es', 'hi', 'fr', 'de', 'pt'};
  final code = appLocale.languageCode;
  if (supported.contains(code)) {
    return appLocale;
  }
  // Bengali/Tamil/Gujarati/Punjabi: Hindi calendar strings are closer than English.
  if (code == 'bn' || code == 'ta' || code == 'gu' || code == 'pa') {
    return const Locale('hi');
  }
  return const Locale('en');
}

Future<DateTime?> showLocalizedDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  Locale? locale,
}) {
  final l10n = AppLocalizations.of(context)!;
  final appLocale = locale ?? Localizations.localeOf(context);

  return showDatePicker(
    context: context,
    locale: materialPickerLocale(appLocale),
    helpText: l10n.selectDate,
    cancelText: l10n.cancel,
    confirmText: l10n.ok,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

Future<TimeOfDay?> showLocalizedTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  Locale? locale,
}) {
  final l10n = AppLocalizations.of(context)!;
  final appLocale = locale ?? Localizations.localeOf(context);
  final pickerLocale = materialPickerLocale(appLocale);

  return showTimePicker(
    context: context,
    helpText: l10n.selectTime,
    cancelText: l10n.cancel,
    confirmText: l10n.ok,
    initialTime: initialTime,
    builder: (ctx, child) {
      return Localizations.override(
        context: ctx,
        locale: pickerLocale,
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}
