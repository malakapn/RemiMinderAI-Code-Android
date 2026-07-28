import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/theme.dart';
import '../../../core/utils/locale_format.dart';
import '../../../core/utils/relationship_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/caregiver_invitation.dart';
import '../../../providers/invitation_provider.dart';

enum _InviteFilter { all, pending, viewed, expired }

const _activeStatuses = ['pending', 'viewed', 'expired', 'accepted'];

/// Caregiver Care Team: Firestore "Invitations received" block.
class InvitationsReceivedSection extends ConsumerStatefulWidget {
  const InvitationsReceivedSection({super.key});

  @override
  ConsumerState<InvitationsReceivedSection> createState() =>
      _InvitationsReceivedSectionState();
}

class _InvitationsReceivedSectionState
    extends ConsumerState<InvitationsReceivedSection> {
  _InviteFilter _filter = _InviteFilter.all;
  String? _busyInvitationId;
  final Set<String> _acceptedInvitationIds = {};
  bool _appliedRouteFilter = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedRouteFilter) return;
    final filter = GoRouterState.of(context).uri.queryParameters['filter'];
    if (filter == 'pending') {
      _filter = _InviteFilter.pending;
    }
    _appliedRouteFilter = true;
  }

  List<CaregiverInvitation> _sortedNewestFirst(List<CaregiverInvitation> raw) {
    final copy = [...raw];
    copy.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return copy;
  }

  List<CaregiverInvitation> _applyFilter(List<CaregiverInvitation> list) {
    switch (_filter) {
      case _InviteFilter.all:
        return list;
      case _InviteFilter.pending:
        return list
            .where((i) => i.status == 'pending' || i.status == 'viewed')
            .toList();
      case _InviteFilter.viewed:
        return list.where((i) => i.status == 'viewed').toList();
      case _InviteFilter.expired:
        return list.where((i) => i.status == 'expired').toList();
    }
  }

  int _pendingCount(List<CaregiverInvitation> all) => all
      .where((i) => i.status == 'pending' || i.status == 'viewed')
      .length;

  @override
  Widget build(BuildContext context) {
    final asyncInvites = ref.watch(receivedInvitationsProvider);

    return asyncInvites.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          e.toString(),
          style: const TextStyle(color: RemiCareUiColors.urgentBadgeText),
          textAlign: TextAlign.center,
        ),
      ),
      data: (raw) {
        final l10n = AppLocalizations.of(context)!;
        final sortedAll = _sortedNewestFirst(raw);
        // Keep locally-accepted cards visible until snackbar dismisses
        final withAccepted = sortedAll.where((i) =>
          _activeStatuses.contains(i.status) ||
          _acceptedInvitationIds.contains(i.invitationId)
        ).toList();
        final filtered = _sortedNewestFirst(_applyFilter(withAccepted));
        final pending = _pendingCount(sortedAll);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.invitationsReceived,
                  style: const TextStyle(
                    color: RemiCareUiColors.sectionHeaderText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (pending > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RemiCareUiColors.pendingBadgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LocaleFormat.localizeDigitsInText(
                        context,
                        l10n.pendingBadge(pending),
                      ),
                      style: const TextStyle(
                        color: RemiCareUiColors.pendingBadgeText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(l10n.tabAll, _InviteFilter.all),
                  const SizedBox(width: 8),
                  _filterChip(l10n.tabPending, _InviteFilter.pending),
                  const SizedBox(width: 8),
                  _filterChip(l10n.statusViewed, _InviteFilter.viewed),
                  const SizedBox(width: 8),
                  _filterChip(l10n.statusExpired, _InviteFilter.expired),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              _InvitationsEmptyState(message: l10n.noInvitationsToShow)
            else
              ...filtered.map(
                (inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InvitationCard(
                    invitation: inv,
                    l10n: l10n,
                    busy: _busyInvitationId == inv.invitationId,
                    onAccept: () => _onAccept(context, inv, l10n),
                    onDecline: () => _onDecline(context, inv.invitationId, l10n),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, _InviteFilter value) {
    final selected = _filter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? RemiCareUiColors.primaryDarkTeal
                : RemiCareUiColors.filterInactiveBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : RemiCareUiColors.bodySubtitleText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept(
    BuildContext context,
    CaregiverInvitation inv,
    AppLocalizations l10n,
  ) async {
    setState(() => _busyInvitationId = inv.invitationId);
    try {
      await ref.read(invitationActionsProvider.notifier).accept(inv);
      if (!context.mounted) return;
      final async = ref.read(invitationActionsProvider);
      async.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: RemiCareUiColors.snackbarSuccessBg,
              content: Text(
                l10n.joinedCareTeamSnackbar(inv.patientName, inv.role),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _busyInvitationId = null);
    }
  }

  Future<void> _onDecline(
    BuildContext context,
    String invitationId,
    AppLocalizations l10n,
  ) async {
    setState(() => _busyInvitationId = invitationId);
    try {
      await ref.read(invitationActionsProvider.notifier).decline(invitationId);
      if (!context.mounted) return;
      final async = ref.read(invitationActionsProvider);
      async.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invitationDeclined)),
          );
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _busyInvitationId = null);
    }
  }
}

class _InvitationsEmptyState extends StatelessWidget {
  final String message;

  const _InvitationsEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mail_outline,
              size: 40,
              color: RemiCareUiColors.declineBorder,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: RemiCareUiColors.confidenceText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  final CaregiverInvitation invitation;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.invitation,
    required this.l10n,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    final l10n = widget.l10n;
    final expired = inv.status == 'expired';
    final opacity = expired ? 0.65 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RemiCareUiColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: RemiCareUiColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InitialsAvatar(patientId: inv.patientId, name: inv.patientName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleFormat.displayName(
                          context,
                          inv.patientName,
                          fallback: l10n.defaultPatient,
                        ),
                        style: const TextStyle(
                          color: RemiCareUiColors.sectionHeaderText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.invitedByLabel(inv.invitedBy),
                        style: const TextStyle(
                          color: RemiCareUiColors.bodySubtitleText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  LocaleFormat.timeAgo(context, inv.createdAt, l10n),
                  style: const TextStyle(
                    color: RemiCareUiColors.confidenceText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _roleBadge(l10n, inv.role),
                _statusBadge(l10n, inv.status),
              ],
            ),
            const SizedBox(height: 14),
            if (inv.status == 'accepted')
              const SizedBox.shrink()
            else if (expired)
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: RemiCareUiColors.bodySubtitleText,
                  side: const BorderSide(color: RemiCareUiColors.declineBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.statusExpired,
                  style: const TextStyle(fontSize: 13),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.busy ? null : widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RemiCareUiColors.tealAcceptButton,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.acceptInvitation,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.busy ? null : widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RemiCareUiColors.bodySubtitleText,
                        side: const BorderSide(
                          color: RemiCareUiColors.declineBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.declineInvitation,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _roleBadge(AppLocalizations l10n, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB5D4F4)),
      ),
      child: Text(
        RelationshipL10n.label(l10n, role),
        style: const TextStyle(
          color: Color(0xFF185FA5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _statusBadge(AppLocalizations l10n, String status) {
    late Color dot;
    late Color bg;
    late Color fg;
    late Color border;
    late String label;

    switch (status) {
      case 'viewed':
        dot = RemiCareUiColors.blueViewedAccent;
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        border = const Color(0xFFBFDBFE);
        label = l10n.statusViewed;
        break;
      case 'expired':
        dot = RemiCareUiColors.grayExpiredAccent;
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        border = const Color(0xFFE5E7EB);
        label = l10n.statusExpired;
        break;
      case 'accepted':
        dot = const Color(0xFF2D6A4F);
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2D6A4F);
        border = const Color(0xFF81C784);
        label = l10n.statusJoined;
        break;
      case 'pending':
      default:
        dot = RemiCareUiColors.amberPendingAccent;
        bg = const Color(0xFFFAEEDA);
        fg = const Color(0xFF854F0B);
        border = const Color(0xFFFAC775);
        label = l10n.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String patientId;
  final String name;

  const _InitialsAvatar({
    required this.patientId,
    required this.name,
  });

  static const _palettes = [
    (Color(0xFFE6F0FA), Color(0xFF1A3A5C)),
    (Color(0xFFE6F1FB), Color(0xFF185FA5)),
    (Color(0xFFEEEDFE), Color(0xFF534AB7)),
    (Color(0xFFFAEEDA), Color(0xFF854F0B)),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = patientId.hashCode.abs() % 4;
    final palette = _palettes[idx];
    final initials = _initialsFrom(name);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: palette.$1,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: palette.$2,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initialsFrom(String raw) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
