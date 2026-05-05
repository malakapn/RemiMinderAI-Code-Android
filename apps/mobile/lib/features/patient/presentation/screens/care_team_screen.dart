import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../care_team/data/models/care_team_invitation.dart';
import '../../../care_team/data/models/care_team_member.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CareTeamScreen extends ConsumerStatefulWidget {
  const CareTeamScreen({super.key});

  @override
  ConsumerState<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends ConsumerState<CareTeamScreen> {
  bool _isLoading = true;
  String? _error;
  List<CareTeamMember> _members = [];
  List<CareTeamInvitation> _pendingInvitations = [];
  final Map<String, bool> _pendingActionLoading = {};
  final Map<String, String?> _pendingActionMessage = {};
  final Map<String, bool> _pendingActionIsError = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user != null && user.isCaregiver) {
        context.go('/caregiver/accept-invitations');
        return;
      }
      _loadCareTeamData();
    });
  }

  Future<void> _loadCareTeamData() async {
    try {
      final cachedMembers = CareTeamApiService.getCachedMembers();
      final cachedPending = CareTeamApiService.getCachedPendingInvites();
      if ((cachedMembers != null || cachedPending != null) && mounted) {
        setState(() {
          _members = cachedMembers ?? _members;
          _pendingInvitations = cachedPending ?? _pendingInvitations;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final results = await Future.wait([
        CareTeamApiService().getCareTeam(),
        CareTeamApiService().getPendingInvitations(),
      ]);
      final members = results[0] as List<CareTeamMember>;
      final pending = results[1] as List<CareTeamInvitation>;
      if (!mounted) return;
      CareTeamApiService.setCachedMembers(members);
      CareTeamApiService.setCachedPendingInvites(pending);
      setState(() {
        _members = members;
        _pendingInvitations = pending;
        _pendingActionLoading.clear();
        _pendingActionMessage.clear();
        _pendingActionIsError.clear();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A4D4D), // Dark teal-green
                    Color(0xFF051818), // Very dark green/black
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Text(
                'Care Team',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Subtitle
                    Text(
                      'You are in control. Review your sharing permissions below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    else if (_members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No caregivers added yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Caregivers',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._members.map((member) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CaregiverTile(
                                  name: member.fullName ??
                                      member.email ??
                                      member.memberUserId,
                                  role: member.role,
                                  accessLevel:
                                      _formatAccessLabel(member.permission),
                                  onManagePermissions: () {
                                    _showManageDialog(context, member);
                                  },
                                ),
                              )),
                        ],
                      ),

                    if (!_isLoading && _pendingInvitations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pending Invitations',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._pendingInvitations.map(
                        (invitation) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPendingInvitationCard(invitation),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Invite Card
                    InviteCaregiverTile(
                      onInvite: () {
                        _showInviteDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Invite Caregiver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter caregiver\'s full name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter caregiver\'s email address',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g., Son, Daughter, Friend, Nurse',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                final role = relationshipController.text.trim();
                if (email.isEmpty || role.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Email and role are required')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _inviteCaregiver(email: email, role: role);
              },
              child: const Text('Send Invite'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _inviteCaregiver({
    required String email,
    required String role,
  }) async {
    try {
      await CareTeamApiService().inviteCaregiver(
        email: email,
        role: role,
        permission: "view",
      );
      await _loadCareTeamData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showManageDialog(BuildContext context, CareTeamMember member) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isLoading = false;
            String? errorMessage;
            String? successMessage;

            Future<void> handleAction(
              Future<bool> Function() action,
              String loadingMessage,
            ) async {
              setDialogState(() {
                isLoading = true;
                errorMessage = null;
                successMessage = loadingMessage;
              });
              final success = await action();
              if (!mounted) return;
              if (success) {
                setDialogState(() {
                  successMessage = 'Access updated successfully';
                });
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() {
                  isLoading = false;
                  successMessage = null;
                  errorMessage = 'Failed to update access. Please try again.';
                });
              }
            }

            Future<void> handleRemove() async {
              final confirmed = await showDialog<bool>(
                context: dialogContext,
                builder: (context) => AlertDialog(
                  title: const Text('Remove caregiver?'),
                  content: const Text(
                    'Are you sure you want to remove this caregiver? They will lose access immediately.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
                successMessage = 'Removing caregiver...';
              });

              final success = await _applyRemoveMember(member.id);
              if (!mounted) return;
              if (success) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() {
                  isLoading = false;
                  successMessage = null;
                  errorMessage =
                      'Failed to remove caregiver. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Manage Access'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update caregiver permission or remove access.'),
                  if (successMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      successMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => handleAction(
                            () => _applyPermissionChange(member.id, 'view'),
                            'Updating access...',
                          ),
                  child: const Text('View Access'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => handleAction(
                            () => _applyPermissionChange(member.id, 'full'),
                            'Updating access...',
                          ),
                  child: const Text('Full Access'),
                ),
                TextButton(
                  onPressed: isLoading ? null : handleRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _applyPermissionChange(
    String memberId,
    String permission,
  ) async {
    try {
      await CareTeamApiService().updatePermission(
        memberId: memberId,
        permission: permission,
      );
      await _loadCareTeamData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _applyRemoveMember(
    String memberId,
  ) async {
    try {
      await CareTeamApiService().removeMember(memberId: memberId);
      await _loadCareTeamData();
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatAccessLabel(String permission) {
    return permission == "full" ? "Full Access" : "View Only";
  }

  Future<void> _resendInvitation(CareTeamInvitation invitation) async {
    _setPendingActionState(
      invitation.id,
      isLoading: true,
      message: 'Resending invitation...',
      isError: false,
    );
    try {
      await CareTeamApiService().resendPendingInvitation(invitation.id);
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: 'Invitation resent',
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _loadCareTeamData();
    } catch (e) {
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: 'Failed to resend invitation',
        isError: true,
      );
    }
  }

  Future<void> _cancelInvitation(CareTeamInvitation invitation) async {
    _setPendingActionState(
      invitation.id,
      isLoading: true,
      message: 'Canceling invitation...',
      isError: false,
    );
    try {
      await CareTeamApiService()
          .cancelPendingInvitation(invitationId: invitation.id);
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: 'Invitation canceled',
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _loadCareTeamData();
    } catch (e) {
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: 'Failed to cancel invitation',
        isError: true,
      );
    }
  }

  void _setPendingActionState(
    String invitationId, {
    required bool isLoading,
    required String? message,
    required bool isError,
  }) {
    if (!mounted) return;
    setState(() {
      _pendingActionLoading[invitationId] = isLoading;
      _pendingActionMessage[invitationId] = message;
      _pendingActionIsError[invitationId] = isError;
    });
  }

  Widget _buildPendingInvitationCard(CareTeamInvitation invitation) {
    final theme = Theme.of(context);
    final isLoading = _pendingActionLoading[invitation.id] == true;
    final message = _pendingActionMessage[invitation.id];
    final isError = _pendingActionIsError[invitation.id] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.inviteeEmail,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invitation.role,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Invitation Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed:
                    isLoading ? null : () => _resendInvitation(invitation),
                child: const Text('Resend'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed:
                    isLoading ? null : () => _cancelInvitation(invitation),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================
// Caregiver Tile
// =======================
class CaregiverTile extends StatelessWidget {
  final String name;
  final String role;
  final String accessLevel;
  final VoidCallback onManagePermissions;

  const CaregiverTile({
    super.key,
    required this.name,
    required this.role,
    required this.accessLevel,
    required this.onManagePermissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFullAccess = accessLevel == 'Full Access';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),

                // Access badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFullAccess
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    accessLevel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFullAccess ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action
          TextButton(
            onPressed: onManagePermissions,
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}

// =======================
// Invite Tile
// =======================
class InviteCaregiverTile extends StatelessWidget {
  final VoidCallback onInvite;

  const InviteCaregiverTile({
    super.key,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onInvite,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Caregiver',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share access to your health information',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
