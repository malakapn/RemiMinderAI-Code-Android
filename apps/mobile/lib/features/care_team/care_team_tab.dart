import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/models/user.dart';

import '../../core/config/theme.dart';
import '../../core/widgets/remi_shell_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/invitation_provider.dart';
import 'data/models/care_team_member.dart';
import 'data/services/care_team_api_service.dart';
import '../patient/presentation/screens/care_team_screen.dart';
import 'widgets/invitations_received_section.dart';

/// Caregiver Care Team tab: Firestore invitations + existing API care team UI.
class CareTeamTab extends ConsumerStatefulWidget {
  const CareTeamTab({super.key});

  @override
  ConsumerState<CareTeamTab> createState() => _CareTeamTabState();
}

class _CareTeamTabState extends ConsumerState<CareTeamTab> {
  bool _isLoading = true;
  String? _error;
  List<CareTeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadCareTeamData();
  }

  Future<void> _loadCareTeamData() async {
    try {
      final cached = CareTeamApiService.getCachedMembers();
      if (cached != null && mounted) {
        setState(() {
          _members = cached;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final members = await CareTeamApiService().getCareTeam();
      if (!mounted) return;
      CareTeamApiService.setCachedMembers(members);
      setState(() {
        _members = members;
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

  Future<void> _onRefresh() async {
    ref.invalidate(receivedInvitationsProvider);
    await _loadCareTeamData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: RemiCareUiColors.bodyBackground,
      body: Column(
        children: [
          RemiShellUi.screenHeader(
            context: context,
            title: l10n.careTeamTitle,
            subtitle: l10n.caregiverCareTeamSubtitle,
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _onRefresh,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InvitationsReceivedSection(),
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
                  l10n.noCaregiversYet,
                  textAlign: TextAlign.center,
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
                    l10n.activeCaregivers,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: RemiCareUiColors.sectionHeaderText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CaregiverTile(
                        name: member.fullName ??
                            member.email ??
                            member.memberUserId,
                        role: member.role,
                        permission: member.permission,
                        l10n: l10n,
                        onManagePermissions: () {
                          _showManageDialog(context, member);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            if (ref.read(authNotifierProvider).user?.role != UserRole.caregiver)
              InviteCaregiverTile(
                l10n: l10n,
                onInvite: () => _showInviteDialog(context),
              ),
                ],
              ),
            ),
          ),
        ],
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
                      content: Text('Email and role are required'),
                    ),
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
        permission: 'view',
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
    final l10n = AppLocalizations.of(context)!;
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
                  successMessage = l10n.accessUpdatedSuccess;
                });
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() {
                  isLoading = false;
                  successMessage = null;
                  errorMessage = l10n.accessUpdateFailed;
                });
              }
            }

            Future<void> handleRemove() async {
              final confirmed = await showDialog<bool>(
                context: dialogContext,
                builder: (context) => AlertDialog(
                  title: Text(l10n.removeCaregiverTitle),
                  content: Text(l10n.removeCaregiverMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.remove),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
                successMessage = l10n.removingCaregiver;
              });

              final success = await _applyRemoveMember(member.id);
              if (!mounted) return;
              if (success) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() {
                  isLoading = false;
                  successMessage = null;
                  errorMessage = l10n.removeCaregiverFailed;
                });
              }
            }

            return AlertDialog(
              title: Text(l10n.manageAccess),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.manageAccessDescription),
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
                            l10n.updatingAccess,
                          ),
                  child: Text(l10n.viewAccess),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => handleAction(
                            () => _applyPermissionChange(member.id, 'full'),
                            l10n.updatingAccess,
                          ),
                  child: Text(l10n.fullAccess),
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
                      : Text(l10n.remove),
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

  Future<bool> _applyRemoveMember(String memberId) async {
    try {
      await CareTeamApiService().removeMember(memberId: memberId);
      await _loadCareTeamData();
      return true;
    } catch (e) {
      return false;
    }
  }

}
