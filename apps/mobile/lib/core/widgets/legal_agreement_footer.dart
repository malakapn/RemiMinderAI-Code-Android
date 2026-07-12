import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_urls.dart';
import '../../l10n/app_localizations.dart';

/// Terms + Privacy links shown on auth screens (login, welcome, register).
class LegalAgreementFooter extends StatelessWidget {
  const LegalAgreementFooter({
    super.key,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url.contains('terms')
              ? l10n.couldNotOpenTerms
              : l10n.couldNotOpenPrivacyPolicy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
      fontSize: 13,
    );
    final bodyStyle = TextStyle(
      color: theme.colorScheme.secondary,
      fontSize: 13,
      height: 1.4,
    );

    return Padding(
      padding: padding,
      child: RichText(
        textAlign: textAlign,
        text: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: l10n.authLegalPrefix),
            TextSpan(
              text: l10n.termsOfService,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl(context, LegalUrls.terms),
            ),
            TextSpan(text: l10n.authLegalAnd),
            TextSpan(
              text: l10n.privacyPolicy,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl(context, LegalUrls.privacy),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
