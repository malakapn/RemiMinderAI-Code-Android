import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:RemiMinder/features/patient/presentation/widgets/patient_app_shell.dart';
import 'package:RemiMinder/features/patient/presentation/widgets/rounded_navigation_bar.dart';
import 'package:RemiMinder/l10n/app_localizations.dart';

void main() {
  testWidgets('Patient shell shows all five navigation tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PatientAppShell(
          currentItem: NavigationItem.home,
          child: const Scaffold(body: Center(child: Text('Home body'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Care Team'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Visits tab opens localized action sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PatientAppShell(
          currentItem: NavigationItem.home,
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visits'));
    await tester.pumpAndSettle();

    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Audio Record Conversation'), findsOneWidget);
    expect(find.text('Capture & Scan'), findsOneWidget);
  });
}
