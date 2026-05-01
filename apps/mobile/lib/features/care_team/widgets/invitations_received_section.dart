import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/theme.dart';
import '../../../models/caregiver_invitation.dart';
import '../../../providers/invitation_provider.dart';

enum _InviteFilter { all, pending, viewed, expired }

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
        return list.where((i) => i.status == 'pending').toList();
      case _InviteFilter.viewed:
        return list.where((i) => i.status == 'viewed').toList();
      case _InviteFilter.expired:
        return list.where((i) => i.status == 'expired').toList();
    }
  }

  int _pendingCount(List<CaregiverInvitation> all) =>
      all.where((i) => i.status == 'pending').length;

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
        final sortedAll = _sortedNewestFirst(raw);
        final filtered = _sortedNewestFirst(_applyFilter(sortedAll));
        final pending = _pendingCount(sortedAll);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Invitations received',
                  style: TextStyle(
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
                      '$pending pending',
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
                  _filterChip('All', _InviteFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('Pending', _InviteFilter.pending),
                  const SizedBox(width: 8),
                  _filterChip('Viewed', _InviteFilter.viewed),
                  const SizedBox(width: 8),
                  _filterChip('Expired', _InviteFilter.expired),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const _InvitationsEmptyState()
            else
              ...filtered.map(
                (inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InvitationCard(
                    invitation: inv,
                    busy: _busyInvitationId == inv.invitationId,
                    onAccept: () => _onAccept(context, inv),
                    onDecline: () => _onDecline(context, inv.invitationId),
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

  Future<void> _onAccept(BuildContext context, CaregiverInvitation inv) async {
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
                "Joined ${inv.patientName}'s care team as ${inv.role}",
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

  Future<void> _onDecline(BuildContext context, String invitationId) async {
    setState(() => _busyInvitationId = invitationId);
    try {
      await ref.read(invitationActionsProvider.notifier).decline(invitationId);
      if (!context.mounted) return;
      final async = ref.read(invitationActionsProvider);
      async.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation declined')),
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
  const _InvitationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              size: 40,
              color: RemiCareUiColors.declineBorder,
            ),
            SizedBox(height: 12),
            Text(
              'No invitations to show',
              style: TextStyle(
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
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  @override
  void initState() {
    super.initState();
    if (widget.invitation.status == 'pending') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(invitationServiceProvider)
            .markAsViewed(widget.invitation.invitationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
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
                        inv.patientName,
                        style: const TextStyle(
                          color: RemiCareUiColors.sectionHeaderText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invited by: ${inv.invitedBy}',
                        style: const TextStyle(
                          color: RemiCareUiColors.bodySubtitleText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  inv.timeAgoLabel,
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
                _roleBadge(inv.role),
                _statusBadge(inv.status),
              ],
            ),
            const SizedBox(height: 14),
            if (expired)
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: RemiCareUiColors.bodySubtitleText,
                  side: const BorderSide(color: RemiCareUiColors.declineBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Expired',
                  style: TextStyle(fontSize: 13),
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
                          : const Text(
                              'Accept',
                              style: TextStyle(
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
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 13),
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

  static Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB5D4F4)),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFF185FA5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _statusBadge(String status) {
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
        label = 'Viewed';
        break;
      case 'expired':
        dot = RemiCareUiColors.grayExpiredAccent;
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        border = const Color(0xFFE5E7EB);
        label = 'Expired';
        break;
      case 'pending':
      default:
        dot = RemiCareUiColors.amberPendingAccent;
        bg = const Color(0xFFFAEEDA);
        fg = const Color(0xFF854F0B);
        border = const Color(0xFFFAC775);
        label = 'Pending';
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
    (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
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
