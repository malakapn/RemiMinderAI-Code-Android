import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_notification_sync.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/data/models/auth_state.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

/// Main MaterialApp widget with theme and routing configuration
class RemiMinderApp extends ConsumerStatefulWidget {
  const RemiMinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Show splash until auth resolves: `loading` during check, `initial` for first
    // frame before `_checkAuthStatus` assigns `loading` (avoids white flash).
    final showAuthSplash = authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial;

    // Listen to auth state changes for logout navigation only
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status != AuthStatus.unauthenticated) return;
      final wasLoggedIn = previous?.status == AuthStatus.authenticated &&
          previous?.user != null;
      if (!wasLoggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appRouterProvider).go('/role-selection');
      });
    });

    if (showAuthSplash) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    return MaterialApp.router(
      title:
          'RemiMinder', // TODO: Use AppLocalizations.of(context)?.appTitle ?? 'RemiMinder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
