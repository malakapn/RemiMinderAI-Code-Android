import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/models/auth_state.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../models/caregiver_invitation.dart';
import '../services/invitation_service.dart';

final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService();
});

final receivedInvitationsProvider =
    StreamProvider<List<CaregiverInvitation>>((ref) {
  final auth = ref.watch(authNotifierProvider);
  if (auth.status != AuthStatus.authenticated) {
    return Stream<List<CaregiverInvitation>>.value([]);
  }
  final service = ref.watch(invitationServiceProvider);
  return service.watchReceivedInvitations();
});

final invitationActionsProvider =
    AsyncNotifierProvider<InvitationActionsNotifier, void>(
  InvitationActionsNotifier.new,
);

class InvitationActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> accept(CaregiverInvitation invitation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(invitationServiceProvider).acceptInvitation(invitation),
    );
  }

  Future<void> decline(String invitationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(invitationServiceProvider).declineInvitation(invitationId),
    );
  }
}
