import 'package:go_router/go_router.dart';

import 'pending_invite_token.dart';

/// Navigate home, or to a pending care-team invite if one was stored.
Future<void> navigateAfterAuth(GoRouter router, {required bool isCaregiver}) async {
  final inviteRoute = await PendingInviteToken.consumeRoute();
  if (inviteRoute != null) {
    router.go(inviteRoute);
    return;
  }

  router.go(isCaregiver ? '/caregiver/home' : '/patient/home');
}
