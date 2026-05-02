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
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

/// Main MaterialApp widget with theme and routing configuration
class RemiMinderApp extends ConsumerStatefulWidget {
  const RemiMinderApp({super.key});

  @override
  ConsumerState<RemiMinderApp> createState() => _RemiMinderAppState();
}

class _RemiMinderAppState extends ConsumerState<RemiMinderApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (!authState.isAuthenticated || user == null) return;
    unawaited(
      ReminderNotificationSync.syncAfterAuth(AuthService(), user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    NotificationService().setNavigationHandler((route) {
      router.go(route);
    });

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final r = ref.read(appRouterProvider);
          r.go('/welcome');
        });
      }
    });

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
