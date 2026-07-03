import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/auth_state.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../data/services/patient_api_service.dart';
import 'upgrade_screen.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  bool _isUpdatingPhone = false;

  @override
  void initState() {
    super.initState();
    // Load profile if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authNotifierProvider);
      if (authState.profile == null && authState.isAuthenticated) {
        try {
          final profile = await BackendApiService().getMyProfile();
          final role = authState.user?.role;
          final roleStr = role?.name ?? authState.profile?.role ?? 'patient';
          ref.read(authNotifierProvider.notifier).updateProfile(
            AuthProfile.fromUserProfile(profile).copyWith(role: roleStr),
          );
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.accountDetails,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      theme,
                      l10n.nameLabel,
                      authState.profile?.fullName ?? l10n.notSet,
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      theme,
                      l10n.emailLabel,
                      () {
                        final email = authState.profile?.email ?? '';
                        if (email.contains('privaterelay.appleid.com')) {
                          return l10n.appleIdHidden;
                        }
                        return email.isEmpty ? l10n.notSet : email;
                      }(),
                      Icons.email,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      theme,
                      l10n.accountType,
                      () {
                        final role = authState.profile?.role
                            ?? (authState.user?.isPatient == true ? 'patient' : 'caregiver');
                        return role == 'patient' ? l10n.patientRole : l10n.caregiverRole;
                      }(),
                      Icons.account_circle,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneDetailItem(theme, authState.profile?.phone, l10n),
                    const SizedBox(height: 16),
                    _buildUsageDetailItem(theme, l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneDetailItem(
      ThemeData theme, String? phone, AppLocalizations l10n) {
    final isPhoneSet = phone != null && phone.isNotEmpty;
    final displayValue = isPhoneSet ? phone : l10n.notSet;
    final actionText = isPhoneSet ? l10n.edit : l10n.add;

    return InkWell(
      onTap: _showPhoneEditDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.phoneLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        actionText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageDetailItem(ThemeData theme, AppLocalizations l10n) {
    final cached = PatientApiService.getCachedSummaries();
    final int count = cached?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usageLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count summaries generated',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUpgrade() {
    launchUrl(
      Uri.parse('https://remiminderai.com/pricing'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _showPhoneEditDialog() {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.read(authNotifierProvider);
    final currentPhone = authState.profile?.phone ?? '';
    final controller = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.editPhoneNumber),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              hintText: '+1 (555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            enabled: !_isUpdatingPhone,
          ),
          actions: [
            TextButton(
              onPressed:
                  _isUpdatingPhone ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: _isUpdatingPhone
                  ? null
                  : () => _savePhoneNumber(controller.text.trim(), setState),
              child: _isUpdatingPhone
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber(String phoneInput, StateSetter setState) async {
    final l10n = AppLocalizations.of(context)!;
    // Validate input
    if (phoneInput.isNotEmpty && phoneInput.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneMinLength)),
      );
      return;
    }

    // Convert empty string to null
    final phoneToSave = phoneInput.isEmpty ? null : phoneInput;

    setState(() => _isUpdatingPhone = true);

    try {
      final backendApiService = BackendApiService();
      final updatedPhone = await backendApiService.updateMyPhone(phoneToSave);

      // Update Riverpod state
      final authState = ref.read(authNotifierProvider);
      final updatedProfile = authState.profile?.copyWith(phone: updatedPhone);
      ref.read(authNotifierProvider.notifier).updateProfile(updatedProfile);

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phoneUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.phoneUpdateFailed(e.toString()))),
        );
      }
    } finally {
      setState(() => _isUpdatingPhone = false);
    }
  }
}
