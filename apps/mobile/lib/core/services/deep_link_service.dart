import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'pending_care_invite_token.dart';

/// Handles custom-scheme and HTTPS deep links on Android (and iOS when wired).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  GoRouter? _router;

  void attach(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    await _linkSub?.cancel();
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial);
      }
    } catch (e) {
      debugPrint('DeepLinkService.getInitialLink: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(handleUri(uri)),
      onError: (Object e) => debugPrint('DeepLinkService.uriLinkStream: $e'),
    );
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
  }

  /// Navigate to an in-app route (e.g. FCM `deep_link` payload).
  void navigate(String path) {
    final router = _router;
    if (router == null) return;
    final normalized = path.startsWith('/') ? path : '/$path';
    router.go(normalized);
  }

  Future<void> handleUri(Uri uri) async {
    debugPrint('DeepLinkService: $uri');

    if (_isBillingUri(uri)) {
      _handleBillingReturn(uri);
      return;
    }

    if (await _handleAuthInviteUri(uri)) {
      return;
    }

    final path = uri.path;
    if (path.startsWith('/patient') || path.startsWith('/caregiver')) {
      navigate(path);
    }
  }

  bool _isBillingUri(Uri uri) {
    if (uri.host == 'billing') return true;
    return uri.pathSegments.contains('billing');
  }

  void _handleBillingReturn(Uri uri) {
    final path = uri.path.toLowerCase();
    if (path.contains('success')) {
      navigate('/patient/profile');
      return;
    }
    if (path.contains('cancel')) {
      navigate('/patient/profile');
    }
  }

  Future<bool> _handleAuthInviteUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final isRegister =
        host == 'register' || path == '/register' || path.endsWith('/register');
    final isLogin =
        host == 'login' || path == '/login' || path.endsWith('/login');

    if (!isRegister && !isLogin) return false;

    final q = uri.queryParameters;
    final token = q['inviteToken'] ?? q['token'];
    if (token != null && token.trim().isNotEmpty) {
      await PendingCareInviteToken.save(token.trim());
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
      params['inviteToken'] = token.trim();
    }

    final target = isRegister ? '/register' : '/login';
    if (params.isEmpty) {
      navigate(target);
    } else {
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      navigate('$target?$query');
    }
    return true;
  }
}
