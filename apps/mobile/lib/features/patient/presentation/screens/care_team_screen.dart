import 'package:flutter/material.dart';
import '../../../care_team/data/models/care_team_invitation.dart';
import '../../../care_team/data/models/care_team_member.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../../../care_team/care_team_permission.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/relationship_l10n.dart';

const Color _teal = Color(0xFF1A3A5C);
const Color _cream = Color(0xFFEDEAE1);
const Color _gold = Color(0xFFC9A84C);
const Color _lightTeal = Color(0xFFE6F0FA);
const Color _cancelBg = Color(0xFFFDECEA);
const Color _cancelText = Color(0xFFC0392B);
const Color _dividerLabel = Color(0xFF9CA3AF);

class _CareTeamHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 12,
        0,
        size.height - 20,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CareTeamScreen extends StatefulWidget {
  const CareTeamScreen({super.key});

  @override
  State<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends State<CareTeamScreen> {
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
    _loadCareTeamData();
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildWaveHeader(AppLocalizations l10n) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: _CareTeamHeaderClipper(),
      child: Container(
        width: double.infinity,
        color: _teal,
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 36),
        child: Row(
          children: [
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                l10n.careTeamTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            _buildHeaderAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAddButton() {
    return GestureDetector(
      onTap: () => _showInviteDialog(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: _gold.withValues(alpha: 0.5)),
        ),
        child: const Icon(
          Icons.add,
          color: _gold,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: _dividerLabel,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _cream,
      body: Column(
        children: [
          _buildWaveHeader(l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.careTeamSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.55),
                      height: 1.5,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _teal),
                      ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black.withValues(alpha: 0.55),
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
                            color: _teal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._members.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CaregiverTile(
                                name: member.fullName ??
                                    (member.email?.contains(
                                                'privaterelay.appleid.com') ==
                                            true
                                        ? l10n.appleIdHidden
                                        : member.email) ??
                                    member.memberUserId,
                                role: member.role,
                                permission: member.permission,
                                l10n: l10n,
                                onManagePermissions: () {
                                  _showManageDialog(context, member);
                                },
                              ),
                            )),
                      ],
                    ),
                  if (!_isLoading && _pendingInvitations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionDivider(l10n.sectionPending),
                    const SizedBox(height: 16),
                    ..._pendingInvitations.map(
                      (invitation) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPendingInvitationCard(invitation, l10n),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionDivider(l10n.sectionAddNew),
                  const SizedBox(height: 16),
                  InviteCaregiverTile(
                    l10n: l10n,
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
    );
  }

  void _showInviteDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.inviteCaregiverDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  hintText: l10n.caregiverNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.caregiverEmailHint,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: l10n.relationshipLabel,
                  hintText: l10n.relationshipHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                final role = relationshipController.text.trim();
                if (email.isEmpty || role.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.emailAndRoleRequired)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _inviteCaregiver(email: email, role: role);
              },
              child: Text(l10n.sendInvite),
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
    final normalized = CareTeamPermission.normalize(permission);
    final previousMembers = _members;
    setState(() {
      _members = _members
          .map(
            (member) => member.id == memberId
                ? member.copyWith(permission: normalized)
                : member,
          )
          .toList();
    });

    try {
      CareTeamMember? matched;
      for (final member in previousMembers) {
        if (member.id == memberId) {
          matched = member;
          break;
        }
      }
      await CareTeamApiService().updatePermission(
        memberId: memberId,
        permission: normalized,
        memberEmail: matched?.email,
      );
      await _loadCareTeamData();
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _members = previousMembers);
      }
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

  Future<void> _resendInvitation(
    CareTeamInvitation invitation,
    AppLocalizations l10n,
  ) async {
    _setPendingActionState(
      invitation.id,
      isLoading: true,
      message: l10n.resendingInvitation,
      isError: false,
    );
    try {
      await CareTeamApiService().resendPendingInvitation(invitation.id);
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: l10n.invitationResent,
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _loadCareTeamData();
    } catch (e) {
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: l10n.failedToResendInvitation,
        isError: true,
      );
    }
  }

  Future<void> _cancelInvitation(
    CareTeamInvitation invitation,
    AppLocalizations l10n,
  ) async {
    _setPendingActionState(
      invitation.id,
      isLoading: true,
      message: l10n.cancelingInvitation,
      isError: false,
    );
    try {
      await CareTeamApiService()
          .cancelPendingInvitation(invitationId: invitation.id);
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: l10n.invitationCanceled,
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      await _loadCareTeamData();
    } catch (e) {
      _setPendingActionState(
        invitation.id,
        isLoading: false,
        message: l10n.failedToCancelInvitation,
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

  Widget _buildPendingInvitationCard(
    CareTeamInvitation invitation,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final isLoading = _pendingActionLoading[invitation.id] == true;
    final message = _pendingActionMessage[invitation.id];
    final isError = _pendingActionIsError[invitation.id] == true;
    final emailLabel = invitation.inviteeEmail.contains('privaterelay.appleid.com')
        ? l10n.appleIdHidden
        : invitation.inviteeEmail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _lightTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: _teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emailLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _teal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      RelationshipL10n.label(l10n, invitation.role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.invitationPending,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: isError ? theme.colorScheme.error : _teal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      isLoading ? null : () => _resendInvitation(invitation, l10n),
                  style: TextButton.styleFrom(
                    backgroundColor: _lightTeal,
                    foregroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.resend,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed:
                      isLoading ? null : () => _cancelInvitation(invitation, l10n),
                  style: TextButton.styleFrom(
                    backgroundColor: _cancelBg,
                    foregroundColor: _cancelText,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
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
  final String permission;
  final AppLocalizations l10n;
  final VoidCallback onManagePermissions;

  const CaregiverTile({
    super.key,
    required this.name,
    required this.role,
    required this.permission,
    required this.l10n,
    required this.onManagePermissions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFullAccess = CareTeamPermission.isFullAccess(permission);
    final accessLevel =
        isFullAccess ? l10n.fullAccess : l10n.viewOnly;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _lightTeal,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.trim().isEmpty
                    ? '?'
                    : name
                        .trim()
                        .split(' ')
                        .where((p) => p.isNotEmpty)
                        .map((p) => p[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _teal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  RelationshipL10n.label(l10n, role),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFullAccess
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
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
          TextButton(
            onPressed: onManagePermissions,
            child: Text(l10n.manage),
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
  final AppLocalizations l10n;

  const InviteCaregiverTile({
    super.key,
    required this.onInvite,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onInvite,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: _gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inviteCaregiver,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.inviteCaregiverSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: _cream.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
