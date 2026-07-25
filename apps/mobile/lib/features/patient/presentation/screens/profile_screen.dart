import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/account_data_actions.dart';
import '../../../../core/config/app_build_info.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/services/subscription_api_service.dart';
import '../../../../core/widgets/remi_shell_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'account_details_screen.dart';
import 'account_security_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Notification toggles
  bool _mobileNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RemiShellUi.screenHeader(
              context: context,
              title: l10n.profileSettings,
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Settings Section
                    _buildSettingsSection(theme, l10n),

                    const SizedBox(height: 32),

                    _buildBottomButtons(theme, l10n),

                    const SizedBox(height: 20),
                    Text(
                      '$kAppBuildLabel · $kAppGitCommitShort',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        fontFamily: 'Poppins',
                      ),
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

  Widget _buildSettingsSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Details
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountDetailsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountDetails,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.accountDetailsSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
        ),

        const SizedBox(height: 12),

        // Account Security
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AccountSecurityScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountSecurity,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.accountSecuritySubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
        ),

        const SizedBox(height: 12),

        // Notifications
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.notificationsLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mobileLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: _mobileNotifications,
                    onChanged: (value) async {
                      setState(() {
                        _mobileNotifications = value;
                      });
                      if (!value) return;
                      final granted =
                          await NotificationService().requestPermissions();
                      if (!mounted) return;
                      if (!granted) {
                        setState(() => _mobileNotifications = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.pushNotificationsDisabled),
                          ),
                        );
                      }
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.emailLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.emailNotificationPreferenceMessage),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Language Settings
        InkWell(
          onTap: () => context.push('/patient/language-settings'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.languageSettings,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
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
        ),

        const SizedBox(height: 12),

        _buildPremiumTile(theme),
      ],
    );
  }

  Widget _buildPremiumTile(ThemeData theme) {
    final profile = ref.watch(authNotifierProvider).profile;
    final isPremium = profile?.isPremium ?? false;
    final title = isPremium ? 'Premium active' : 'RemiMinderAI Premium';
    final subtitle = isPremium
        ? 'Vox, unlimited summaries, and caregiver support are unlocked.'
        : 'Unlock Vox, unlimited summaries, and up to 5 caregivers.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A84C).withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.55)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isPremium ? null : () => context.push('/patient/upgrade'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC9A84C),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPremium)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _restorePurchases,
              icon: const Icon(Icons.restore),
              label: const Text('Restore purchases'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    try {
      final info = await RevenueCatService.instance.restorePurchases();
      final premium = RevenueCatService.instance.hasPremium(info);
      final productId = RevenueCatService.instance.activeProductId(info);
      await SubscriptionApiService().syncRevenueCatStatus(
        premium: premium,
        appUserId: info?.originalAppUserId,
        productId: productId,
      );
      final profile = await BackendApiService().getMyProfile();
      final current = ref.read(authNotifierProvider);
      final role = current.user?.role.name ?? current.profile?.role ?? profile.role;
      ref.read(authNotifierProvider.notifier).updateProfile(
            AuthProfile.fromUserProfile(profile).copyWith(role: role),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            premium
                ? 'Purchases restored. Premium is active.'
                : 'No active Premium subscription was found.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore purchases failed: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(AppLocalizations l10n) async {
    await AccountDataActions.confirmAndDeleteAccount(
      context: context,
      ref: ref,
    );
  }

  Widget _buildBottomButtons(ThemeData theme, AppLocalizations l10n) {
    const deleteRed = Color(0xFFA32D2D);
    final creamBg = theme.scaffoldBackgroundColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Sign Out Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (kDebugMode) {
                    print('👆 ProfileScreen: Sign Out button tapped');
                  }
                  try {
                    if (kDebugMode) {
                      print(
                          '👆 ProfileScreen: Calling authNotifierProvider.notifier.signOut()');
                    }
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (!mounted) return;
                    context.go('/welcome');
                    if (kDebugMode) {
                      print(
                          '👆 ProfileScreen: signOut() completed successfully');
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('👆 ProfileScreen: signOut() failed: $e');
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.signOut,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _confirmDeleteAccount(l10n),
          style: OutlinedButton.styleFrom(
            backgroundColor: creamBg,
            foregroundColor: deleteRed,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            side: const BorderSide(color: deleteRed, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.deleteAccount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
