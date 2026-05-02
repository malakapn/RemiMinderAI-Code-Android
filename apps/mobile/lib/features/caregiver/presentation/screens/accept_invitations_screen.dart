import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../care_team/data/models/care_team_invitation.dart';
import '../../../care_team/data/services/care_team_api_service.dart';

class AcceptInvitationsScreen extends StatefulWidget {
  const AcceptInvitationsScreen({super.key});

  @override
  State<AcceptInvitationsScreen> createState() =>
      _AcceptInvitationsScreenState();
}

class _AcceptInvitationsScreenState extends State<AcceptInvitationsScreen> {
  List<CareTeamInvitation> _invitations = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _acceptingIds = {};
  final Set<String> _decliningIds = {};

  @override
  void initState() {
    super.initState();
    _loadInvitations(initial: true);
  }

  DateTime? _parseUtc(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  bool _isExpired(CareTeamInvitation invitation) {
    if (invitation.status != 'pending') return false;
    final exp = _parseUtc(invitation.expiresAt);
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(exp);
  }

  bool _canActOn(CareTeamInvitation invitation) {
    return invitation.status == 'pending' && !_isExpired(invitation);
  }

  String _statusLabel(CareTeamInvitation invitation) {
    if (_isExpired(invitation)) return 'Expired';
    switch (invitation.status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'revoked':
        return 'Revoked';
      default:
        return invitation.status;
    }
  }

  Color _statusColor(CareTeamInvitation invitation, ColorScheme scheme) {
    if (_isExpired(invitation)) return scheme.outline;
    switch (invitation.status) {
      case 'pending':
        return scheme.primary;
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'revoked':
        return scheme.secondary;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/caregiver/home'),
        ),
        title: const Text(
          'Invitations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadInvitations(initial: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_invitations.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadInvitations(initial: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
            ),
            Center(
              child: Text(
                'No invitations yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInvitations(initial: false),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }

  Widget _buildInvitationCard(CareTeamInvitation invitation) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = _statusColor(invitation, scheme);
    final canAct = _canActOn(invitation);
    final isAccepting = _acceptingIds.contains(invitation.id);
    final isDeclining = _decliningIds.contains(invitation.id);
    final patientTitle = invitation.patientName?.trim().isNotEmpty == true
        ? invitation.patientName!
        : (invitation.patientId ?? 'Patient');
    final invitedBy = invitation.invitedByName?.trim().isNotEmpty == true
        ? invitation.invitedByName!
        : patientTitle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    patientTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(invitation),
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: borderColor.withOpacity(0.4)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Invited by $invitedBy',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.75),
              ),
            ),
            if (invitation.inviteeEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Sent to: ${invitation.inviteeEmail}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text('Role: ${invitation.role}'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('Access: ${invitation.permission}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (canAct) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isDeclining || isAccepting
                          ? null
                          : () => _confirmDecline(invitation),
                      child: isDeclining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isAccepting || isDeclining
                          ? null
                          : () => _acceptInvitation(invitation),
                      child: isAccepting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadInvitations({required bool initial}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final invitations = await CareTeamApiService().getMyInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invitations;
        if (initial) _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        if (initial) _isLoading = false;
      });
    }
  }

  String _consentSummary(CareTeamInvitation invitation) {
    final name = invitation.patientName?.trim().isNotEmpty == true
        ? invitation.patientName!
        : 'This patient';
    final scope = invitation.permission == 'full'
        ? 'full care coordination (including notes and health-related data shared in the app)'
        : 'read-only access to information their patient shares with you in the app';
    return '$name invited you as a caregiver with $scope. By accepting, you agree to use this information only for their care and to follow applicable privacy rules.';
  }

  Future<void> _confirmDecline(CareTeamInvitation invitation) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline invitation?'),
        content: const Text(
          'You will not join this care team unless the patient sends a new invite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _decliningIds.add(invitation.id));
    try {
      await CareTeamApiService().declineMyInvitation(invitation.id);
      if (!mounted) return;
      await _loadInvitations(initial: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _decliningIds.remove(invitation.id));
      }
    }
  }

  Future<void> _acceptInvitation(CareTeamInvitation invitation) async {
    final token = invitation.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation token is missing')),
      );
      return;
    }
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept care team invitation'),
        content: SingleChildScrollView(child: Text(_consentSummary(invitation))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    setState(() {
      _acceptingIds.add(invitation.id);
    });

    try {
      await CareTeamApiService().acceptInvitation(token: token);
      if (!mounted) return;
      await _loadInvitations(initial: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _acceptingIds.remove(invitation.id);
        });
      }
    }
  }
}
