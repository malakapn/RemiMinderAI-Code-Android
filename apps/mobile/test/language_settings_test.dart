import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:RemiMinder/core/config/supported_languages.dart';
import 'package:RemiMinder/core/providers/locale_provider.dart';
import 'package:RemiMinder/features/patient/presentation/screens/language_settings_screen.dart';
import 'package:RemiMinder/l10n/app_localizations.dart';

void main() {
  testWidgets('Language settings lists all 10 supported languages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(() => _FixedLocaleNotifier()),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LanguageSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSettingsScreen), findsOneWidget);
    expect(kSupportedLanguages.length, 10);
    expect(find.text('10 languages'), findsOneWidget);
    expect(find.text('Scroll down to see all languages'), findsOneWidget);

    // First languages are visible without scrolling.
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);

    // Scroll to the last language (Punjabi) to confirm all 10 are in the list.
    await tester.scrollUntilVisible(
      find.text('ਪੰਜਾਬੀ'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('ਪੰਜਾਬੀ'), findsOneWidget);
  });

  testWidgets('Hindi locale localizes home navigation labels', (tester) async {
    late LocaleNotifier notifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(() {
            notifier = _FixedLocaleNotifier(initial: const Locale('hi'));
            return notifier;
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(localeProvider);
            return MaterialApp(
              key: ValueKey(locale.languageCode),
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Scaffold(
                    body: Column(
                      children: [
                        Text(l10n.navHome),
                        Text(l10n.navOverview),
                        Text(l10n.navCareTeam),
                        Text(l10n.goodMorning),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('होम'), findsOneWidget);
    expect(find.text('अवलोकन'), findsOneWidget);
    expect(find.text('केयर टीम'), findsOneWidget);
    expect(find.text('सुप्रभात'), findsOneWidget);

    await notifier.setLocaleFromString('es');
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Buenos días'), findsOneWidget);
  });
}

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier({Locale initial = const Locale('en')}) : _initial = initial;

  final Locale _initial;

  @override
  Locale build() => _initial;

  @override
  Future<void> setLocaleFromString(String languageCode) async {
    final normalized = normalizeLanguageCode(languageCode);
    if (state.languageCode == normalized) return;
    state = Locale(normalized);
  }
}
