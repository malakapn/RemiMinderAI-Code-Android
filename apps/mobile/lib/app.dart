import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/data/models/auth_state.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'services/pending_invite_token.dart';

/// Main MaterialApp widget with theme and routing configuration
class RemiMinderApp extends ConsumerStatefulWidget {
  const RemiMinderApp({super.key});

  @override
  ConsumerState<RemiMinderApp> createState() => _RemiMinderAppState();
}

class _RemiMinderAppState extends ConsumerState<RemiMinderApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireNotifications());
  }

  void _wireNotifications() {
    final router = ref.read(appRouterProvider);
    NotificationService().setNavigationHandler((route) {
      final path = route.startsWith('/') ? route : '/$route';
      router.go(path);
    });
    unawaited(NotificationService().ensureRuntimePermissions());
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle app opened from deep link (cold start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link: $uri');

    if (uri.scheme == 'remiminder' && uri.host == 'accept-invitation') {
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) return;

      PendingInviteToken.save(token);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(appRouterProvider);
        final authState = ref.read(authNotifierProvider);
        if (authState.status == AuthStatus.authenticated) {
          PendingInviteToken.clear();
          router.go('/accept-invitation?token=$token');
        } else {
          router.go('/login?role=caregiver&token=${Uri.encodeQueryComponent(token)}');
        }
      });
      return;
    }

    if (uri.host == 'billing' ||
        uri.pathSegments.contains('billing') ||
        (uri.scheme.contains('remiminder') && uri.host == 'billing')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appRouterProvider).go('/patient/profile');
      });
      return;
    }

    final path = uri.path;
    if (path.startsWith('/patient') || path.startsWith('/caregiver')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appRouterProvider).go(path);
      });
      return;
    }

    final host = uri.host.toLowerCase();
    final isRegister =
        host == 'register' || path == '/register' || path.endsWith('/register');
    final isLogin =
        host == 'login' || path == '/login' || path.endsWith('/login');
    if (!isRegister && !isLogin) return;

    final q = uri.queryParameters;
    final token = q['inviteToken'] ?? q['token'];
    if (token != null && token.trim().isNotEmpty) {
      PendingInviteToken.save(token.trim());
    }

    final params = <String, String>{};
    final role = q['role']?.toLowerCase();
    if (role == 'caregiver' || role == 'patient') {
      params['role'] = role!;
    } else if (isRegister) {
      params['role'] = 'caregiver';
    }
    final email = q['email'];
    if (email != null && email.isNotEmpty) {
      params['email'] = email;
    }
    if (token != null && token.trim().isNotEmpty) {
      params['token'] = token.trim();
    }

    final target = isRegister ? '/register' : '/login';
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appRouterProvider).go(query.isEmpty ? target : '$target?$query');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    NotificationService().setNavigationHandler((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Logout only — LoadingScreen handles the initial unauthenticated route.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status == AuthStatus.authenticated &&
          next.status == AuthStatus.unauthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appRouterProvider).go('/welcome');
        });
      }
    });

    return MaterialApp.router(
      title: 'RemiMinder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light mode for consistent UI
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
