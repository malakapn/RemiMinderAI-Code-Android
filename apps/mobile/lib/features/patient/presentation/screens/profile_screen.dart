import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/models/user.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'account_details_screen.dart';
import 'account_security_screen.dart';
import 'language_settings_screen.dart';
import 'upgrade_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _mobileNotifications = true;
  bool _emailNotifications = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotificationPrefs());
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    var mobile = prefs.getBool('mobile_notifications') ?? true;
    var email = prefs.getBool('email_notifications') ?? false;

    final user = ref.read(authNotifierProvider).user;
    if (user?.role == UserRole.caregiver) {
      try {
        final headers = await AuthService().getAuthHeaders();
        final uri = Uri.parse(
          '${Environment.apiBaseUrl}/api/users/me/notification-preferences',
        );
        final response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          email = map['caregiver_alert_email_enabled'] == true;
        }
      } catch (_) {
        email = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _mobileNotifications = mobile;
      _emailNotifications = email;
    });
  }

  Future<void> _setMobileNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mobile_notifications', value);
    if (!mounted) return;
    setState(() => _mobileNotifications = value);
  }

  Future<void> _setEmailNotifications(bool value) async {
    final user = ref.read(authNotifierProvider).user;
    if (user?.role == UserRole.caregiver) {
      try {
        final headers = await AuthService().getAuthHeaders();
        final uri = Uri.parse(
          '${Environment.apiBaseUrl}/api/users/me/notification-preferences',
        );
        final response = await http.put(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'caregiver_alert_email_enabled': value}),
        );
        if (response.statusCode != 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not save email preference (${response.statusCode})',
                ),
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save email preference: $e')),
          );
        }
        return;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', value);
    }
    if (!mounted) return;
    setState(() => _emailNotifications = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(theme),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Settings Section
                    _buildSettingsSection(theme),

                    const SizedBox(height: 24),

                    _buildDangerZone(theme),

                    const SizedBox(height: 32),

                    // Bottom Buttons
                    _buildBottomButtons(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final user = ref.watch(authNotifierProvider).user;
    final displayName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : (user?.displayName ?? 'User');
    final initials = _initialsFromName(displayName, user?.email);
    final roleLabel = user?.role.displayName ?? 'Account';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A4D4D),
            Color(0xFF051818),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditNameDialog(displayName),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              roleLabel,
              style: const TextStyle(
                color: Color(0xFF051818),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            backgroundColor: Colors.white.withOpacity(0.9),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)?.profileSettings ?? 'Profile Settings',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name, String? email) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  Widget _buildDangerZone(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.6)),
        color: theme.colorScheme.error.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger zone',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deleting your account removes your data from this app’s database. '
            'This cannot be undone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _onDeleteAccountPressed,
            icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            label: Text(
              'Delete account',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName == 'User' ? '' : currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Full name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final svc = BackendApiService(authService: AuthService());
                await svc.updateName(name);
                // Update SecureStorage cache
                await SecureStorage().saveFullName(name);
                // Refresh auth state so UI updates immediately
                await ref.read(authNotifierProvider.notifier).initialize();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update name: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteAccountPressed() async {
    final theme = Theme.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your reminders, care team links, and profile will be permanently removed '
          'from our servers. You will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type DELETE in capital letters to confirm.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              if (controller.text.trim() == 'DELETE') {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true || !mounted) return;

    try {
      final headers = await AuthService().getAuthHeaders();
      final uri = Uri.parse('${Environment.apiBaseUrl}/api/users/me');
      final response = await http.delete(uri, headers: headers);
      if (response.statusCode != 204 && response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not delete account (${response.statusCode}). '
              '${response.body.isNotEmpty ? response.body : ''}',
            ),
          ),
        );
        return;
      }
      await ref.read(authNotifierProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildSettingsSection(ThemeData theme) {
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
                        'Account Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View your profile information',
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
                        'Account Security',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage password and privacy',
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
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mobile',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: _mobileNotifications,
                    onChanged: _setMobileNotifications,
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.watch(authNotifierProvider).user?.role ==
                                  UserRole.caregiver
                              ? 'Caregiver alert emails'
                              : 'Email',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (ref.watch(authNotifierProvider).user?.role ==
                            UserRole.caregiver)
                          Text(
                            'Uses your account email when the server has SES enabled.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _emailNotifications,
                    onChanged: _setEmailNotifications,
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen()),
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
                        'Language Settings',
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
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Row(
      children: [
        // Upgrade Button
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpgradeScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sign Out Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isSigningOut
                ? null
                : () async {
                    setState(() => _isSigningOut = true);
              print('👆 ProfileScreen: Sign Out button tapped');
              try {
                print(
                    '👆 ProfileScreen: Calling authNotifierProvider.notifier.signOut()');
                await ref.read(authNotifierProvider.notifier).signOut();
                print('👆 ProfileScreen: signOut() completed successfully');
              } catch (e) {
                print('👆 ProfileScreen: signOut() failed: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out failed: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isSigningOut = false);
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
            child: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
