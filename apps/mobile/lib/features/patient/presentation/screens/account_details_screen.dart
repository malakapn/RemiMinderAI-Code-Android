import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/auth_service.dart';
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
  int _summariesUsed = 0;
  bool _isLoadingUsage = true;

  @override
  void initState() {
    super.initState();
    _loadSummariesUsage();
  }

  Future<void> _loadSummariesUsage() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) return;
      PatientApiService.setAuthToken(token);
      final summaries = await PatientApiService().getSummaries();
      if (!mounted) return;
      setState(() {
        _summariesUsed = summaries.length;
        _isLoadingUsage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUsage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

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
                      'Account Details',
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
                      'Name',
                      authState.profile?.fullName ?? 'Not set',
                      Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      theme,
                      'Email',
                      authState.profile?.email ?? 'Not set',
                      Icons.email,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      theme,
                      'Account Type',
                      authState.profile?.role == 'patient'
                          ? 'Patient'
                          : 'Caregiver',
                      Icons.account_circle,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneDetailItem(theme, authState.profile?.phone),
                    const SizedBox(height: 16),
                    _buildPlanDetailItem(
                        theme, authState.profile?.plan ?? "free"),
                    const SizedBox(height: 16),
                    _buildUsageDetailItem(
                        theme, authState.profile?.plan ?? "free"),
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

  Widget _buildPhoneDetailItem(ThemeData theme, String? phone) {
    final isPhoneSet = phone != null && phone.isNotEmpty;
    final displayValue = isPhoneSet ? phone : 'Not set';
    final actionText = isPhoneSet ? 'Edit' : 'Add';

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
                        'Phone',
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

  Widget _buildPlanDetailItem(ThemeData theme, String plan) {
    final isFreePlan = plan == "free";
    final displayValue = isFreePlan ? 'Free' : 'Premium';
    final actionText = isFreePlan ? 'Upgrade' : 'Manage';

    return InkWell(
      onTap: isFreePlan ? () => _navigateToUpgrade() : null,
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
                Icons.star,
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
                        'Plan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isFreePlan) ...[
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

  Widget _buildUsageDetailItem(ThemeData theme, String plan) {
    const int limit = 2;
    final isFreePlan = plan == "free";
    final displayValue = _isLoadingUsage
        ? 'Loading usage...'
        : isFreePlan
            ? 'Free plan — $_summariesUsed / $limit summaries used'
            : 'Unlimited';
    final actionText = isFreePlan ? 'Upgrade' : null;

    return InkWell(
      onTap: isFreePlan ? () => _navigateToUpgrade() : null,
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
                  Row(
                    children: [
                      Text(
                        'Usage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isFreePlan) ...[
                        const Spacer(),
                        Text(
                          actionText!,
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

  void _navigateToUpgrade() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpgradeScreen()),
    );
  }

  void _showPhoneEditDialog() {
    final authState = ref.read(authNotifierProvider);
    final currentPhone = authState.profile?.phone ?? '';
    final controller = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Phone Number'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1 (555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            enabled: !_isUpdatingPhone,
          ),
          actions: [
            TextButton(
              onPressed:
                  _isUpdatingPhone ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoneNumber(String phoneInput, StateSetter setState) async {
    // Validate input
    if (phoneInput.isNotEmpty && phoneInput.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Phone number must be at least 8 characters long')),
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
          const SnackBar(content: Text('Phone number updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update phone number: $e')),
        );
      }
    } finally {
      setState(() => _isUpdatingPhone = false);
    }
  }
}
