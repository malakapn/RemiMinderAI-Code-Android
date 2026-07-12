import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../config/legal_urls.dart';
import '../services/user_api_service.dart';

/// Shared account deletion and data-request flows for Profile and Privacy Settings.
abstract final class AccountDataActions {
  static Future<void> confirmAndDeleteAccount({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

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
      await ref.read(authNotifierProvider.notifier).signOut();

      if (!context.mounted) return;
      context.go('/welcome');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionFailed(e.toString()))),
      );
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
