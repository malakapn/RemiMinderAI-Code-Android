import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_urls.dart';
import '../../../../core/services/account_data_actions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/remi_shell_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../care_team/care_team_permission.dart';
import '../../../care_team/data/models/care_team_member.dart';
import '../../../care_team/data/services/care_team_api_service.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _allowCaregiverSummaries = true;
  bool _allowCaregiverMedications = false;
  bool _allowCaregiverReminders = true;
  bool _allowAiImprovement = true;

  bool _allowEmailNotifications = true;
  bool _allowPushNotifications = true;

  CareTeamMember? _activeCaregiver;
  bool _isLoadingCaregiver = true;
  String? _caregiverError;
  bool _isUpdatingPermission = false;

  @override
  void initState() {
    super.initState();
    _loadCaregiver();
  }

  Future<void> _exportMyData() async {
    await AccountDataActions.requestDataExport(context);
  }

  Future<void> _deleteMedicalRecords() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMedicalRecordsTitle),
        content: Text(l10n.deleteMedicalRecordsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteRecords),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AccountDataActions.requestMedicalRecordsDeletion(context);
    }
  }

  Future<void> _deleteMyAccount() async {
    await AccountDataActions.confirmAndDeleteAccount(
      context: context,
      ref: ref,
    );
  }

  void _setAllToggleStates(bool value) {
    _allowCaregiverSummaries = value;
    _allowCaregiverMedications = value;
    _allowCaregiverReminders = value;
    _allowAiImprovement = value;
    _allowEmailNotifications = value;
    _allowPushNotifications = value;
  }

  Future<void> _loadCaregiver() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingCaregiver = true;
        _caregiverError = null;
      });

      final members = await CareTeamApiService().getCareTeam();
      if (!mounted) return;
      final caregiver = members.isNotEmpty ? members.first : null;
      setState(() {
        _activeCaregiver = caregiver;
        _isLoadingCaregiver = false;
        _setAllToggleStates(CareTeamPermission.isFullAccess(caregiver?.permission));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _caregiverError = _friendlyError(e);
        _isLoadingCaregiver = false;
        _setAllToggleStates(false);
      });
    }
  }

  Future<void> _updateCaregiverPermission(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    final caregiver = _activeCaregiver;
    if (caregiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCaregiversYet)),
      );
      return;
    }

    final previousPermission = caregiver.permission;
    final newPermission = value ? 'full' : 'view';

    setState(() {
      _isUpdatingPermission = true;
      _allowCaregiverSummaries = value;
      _allowCaregiverMedications = value;
      _allowCaregiverReminders = value;
      _activeCaregiver = CareTeamMember(
        id: caregiver.id,
        patientId: caregiver.patientId,
        memberUserId: caregiver.memberUserId,
        fullName: caregiver.fullName,
        email: caregiver.email,
        role: caregiver.role,
        permission: newPermission,
        status: caregiver.status,
      );
    });

    try {
      await CareTeamApiService().updatePermission(
        memberId: caregiver.id,
        permission: newPermission,
        memberEmail: caregiver.email,
      );
      if (!mounted) return;
      setState(() {
        _isUpdatingPermission = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? l10n.caregiverSharingEnabled
              : l10n.caregiverSharingDisabled),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingPermission = false;
        _allowCaregiverSummaries = CareTeamPermission.isFullAccess(previousPermission);
        _allowCaregiverMedications = CareTeamPermission.isFullAccess(previousPermission);
        _allowCaregiverReminders = CareTeamPermission.isFullAccess(previousPermission);
        _activeCaregiver = CareTeamMember(
          id: caregiver.id,
          patientId: caregiver.patientId,
          memberUserId: caregiver.memberUserId,
          fullName: caregiver.fullName,
          email: caregiver.email,
          role: caregiver.role,
          permission: previousPermission,
          status: caregiver.status,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accessUpdateFailed)),
      );
    }
  }

  void _showEmailPreferenceInfo() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.emailNotificationPreferenceMessage),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _updatePushNotifications(bool value) async {
    _updateLocalPreference(() => _allowPushNotifications = value);
    if (!value) return;

    final granted = await NotificationService().requestPermissions();
    if (!mounted) return;
    if (!granted) {
      setState(() => _allowPushNotifications = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pushNotificationsDisabled)),
      );
    }
  }

  void _updateEmailNotifications(bool value) {
    _updateLocalPreference(() => _allowEmailNotifications = value);
    if (value) {
      _showEmailPreferenceInfo();
    }
  }

  void _updateLocalPreference(void Function() apply) {
    setState(apply);
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('not-found')) {
      return AppLocalizations.of(context)!.caregiverSyncRetry;
    }
    return message;
  }

  Future<void> _openTermsOfService() async {
    final uri = Uri.parse(LegalUrls.terms);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenTerms)),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(LegalUrls.privacy);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenPrivacyPolicy),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final togglesEnabled = !_isLoadingCaregiver &&
        !_isUpdatingPermission &&
        _activeCaregiver != null;

    return Scaffold(
      backgroundColor: RemiShellUi.bodyCream,
      body: SafeArea(
        child: Column(
          children: [
            RemiShellUi.screenHeader(
              context: context,
              title: l10n.privacySettings,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(l10n.dataSharing, Icons.share),
                    const SizedBox(height: 8),
                    if (_caregiverError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _caregiverError!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (!_isLoadingCaregiver && _activeCaregiver == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.noCaregiversYet,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    _buildToggleTile(
                      l10n.allowCaregiverSummaries,
                      _allowCaregiverSummaries,
                      _updateCaregiverPermission,
                      isEnabled: togglesEnabled,
                    ),
                    _buildToggleTile(
                      l10n.allowCaregiverMedications,
                      _allowCaregiverMedications,
                      _updateCaregiverPermission,
                      isEnabled: togglesEnabled,
                    ),
                    _buildToggleTile(
                      l10n.allowCaregiverReminders,
                      _allowCaregiverReminders,
                      _updateCaregiverPermission,
                      isEnabled: togglesEnabled,
                    ),
                    _buildToggleTile(
                      l10n.allowAiImprovement,
                      _allowAiImprovement,
                      (value) => _updateLocalPreference(
                        () => _allowAiImprovement = value,
                      ),
                      isEnabled: !_isLoadingCaregiver,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        l10n.communicationAndConsent, Icons.notifications),
                    const SizedBox(height: 8),
                    _buildToggleTile(
                      l10n.allowEmailNotifications,
                      _allowEmailNotifications,
                      _updateEmailNotifications,
                      isEnabled: !_isLoadingCaregiver,
                    ),
                    _buildToggleTile(
                      l10n.allowPushNotifications,
                      _allowPushNotifications,
                      _updatePushNotifications,
                      isEnabled: !_isLoadingCaregiver,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(l10n.dataControl, Icons.storage),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      l10n.exportMyData,
                      Icons.download,
                      _exportMyData,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      l10n.deleteAllMedicalRecords,
                      Icons.delete_forever,
                      _deleteMedicalRecords,
                    ),
                    const SizedBox(height: 8),
                    _buildDangerButton(
                      l10n.deleteMyAccount,
                      _deleteMyAccount,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(l10n.legal, Icons.gavel),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      l10n.viewPrivacyPolicy,
                      Icons.policy,
                      _openPrivacyPolicy,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      l10n.viewTermsOfService,
                      Icons.description,
                      _openTermsOfService,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isEnabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        onChanged: isEnabled ? onChanged : null,
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
