import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/care_team/data/services/care_team_api_service.dart';
import '../../features/patient/data/services/patient_api_service.dart';
import '../../l10n/app_localizations.dart';
import '../config/legal_urls.dart';
import '../services/user_api_service.dart';

/// Shared account deletion and data-request flows for Profile and Privacy Settings.
abstract final class AccountDataActions {
  static const String supportEmail = LegalUrls.supportEmail;

  static Future<void> confirmAndDeleteAccount({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _DeleteAccountConfirmDialog(),
    );

    if (confirmed != true || !context.mounted) return;

    await _performAccountDeletion(context: context, ref: ref, l10n: l10n);
  }

  static Future<void> _performAccountDeletion({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(l10n.deletingYourAccount),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception(l10n.authenticationErrorLoginAgain);
      }
      final token = await firebaseUser.getIdToken(true);
      if (token == null) {
        throw Exception(l10n.authenticationErrorLoginAgain);
      }

      await UserApiService().deleteAccount(token);

      // Best-effort: remove Auth user if backend left it (requires recent login).
      try {
        await firebaseUser.delete();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Account deletion: Firebase Auth client delete skipped: $e');
        }
      }

      await _clearLocalAppData();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(l10n.accountDeletedTitle),
            content: Text(l10n.accountDeletedSuccess),
          ),
        ),
      );

      // Auto-logout after 2 seconds so the success message is readable.
      await Future<void>.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // success dialog
      }

      try {
        await ref.read(authNotifierProvider.notifier).signOut();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Account deletion: signOut after delete: $e');
        }
      }

      if (!context.mounted) return;
      context.go('/welcome');
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Account deletion failed: $e\n$stack');
      }
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // loading

      final shouldRetry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (errorContext) => AlertDialog(
          title: Text(l10n.accountDeletionFailedTitle),
          content: Text(
            '${l10n.accountDeletionFailed(e.toString())}\n\n'
            '${l10n.accountDeletionContactSupport(supportEmail)}',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: supportEmail,
                  query: _encodeQuery({
                    'subject': 'Account deletion help',
                    'body':
                        'I need help deleting my RemiMinder account.\n\nError: $e',
                  }),
                );
                await launchUrl(uri);
              },
              child: Text(l10n.contactSupport),
            ),
            TextButton(
              onPressed: () => Navigator.of(errorContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(errorContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );

      if (shouldRetry == true && context.mounted) {
        await _performAccountDeletion(context: context, ref: ref, l10n: l10n);
      }
    }
  }

  static Future<void> _clearLocalAppData() async {
    PatientApiService.invalidateSummariesCache();
    PatientApiService.invalidateLatestVisitStatusCache();
    CareTeamApiService.invalidateCaches();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Account deletion: SharedPreferences clear failed: $e');
      }
    }
  }

  static Future<void> requestDataExport(BuildContext context) async {
    await _launchPrivacyEmail(
      context,
      subject: AppLocalizations.of(context)!.dataExportEmailSubject,
      body: AppLocalizations.of(context)!.dataExportEmailBody,
      successMessage: AppLocalizations.of(context)!.dataExportRequestSent,
    );
  }

  static Future<void> requestMedicalRecordsDeletion(BuildContext context) async {
    await _launchPrivacyEmail(
      context,
      subject: AppLocalizations.of(context)!.deleteRecordsEmailSubject,
      body: AppLocalizations.of(context)!.deleteRecordsEmailBody,
      successMessage: AppLocalizations.of(context)!.deleteRecordsRequestSent,
    );
  }

  static Future<void> _launchPrivacyEmail(
    BuildContext context, {
    required String subject,
    required String body,
    required String successMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'mailto',
      path: LegalUrls.privacyEmail,
      query: _encodeQuery({'subject': subject, 'body': body}),
    );

    final launched = await launchUrl(uri);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(launched ? successMessage : l10n.privacyDataRequestMessage),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}

class _DeleteAccountConfirmDialog extends StatefulWidget {
  const _DeleteAccountConfirmDialog();

  @override
  State<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<_DeleteAccountConfirmDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const deleteRed = Color(0xFFA32D2D);

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountMessage),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _understood = !_understood),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _understood,
                    activeColor: deleteRed,
                    onChanged: (value) {
                      setState(() => _understood = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.deleteAccountConfirmationCheckbox,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: deleteRed),
          child: Text(l10n.deleteMyAccountConfirm),
        ),
      ],
    );
  }
}
