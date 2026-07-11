import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/config/supported_languages.dart';
import '../../../../core/models/user.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/widgets/remi_shell_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/patient_api_service.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _localizedLanguageName(AppLocalizations l10n, String code) {
    switch (normalizeLanguageCode(code)) {
      case 'es':
        return l10n.spanish;
      case 'hi':
        return l10n.hindi;
      case 'fr':
        return l10n.french;
      case 'pt':
        return l10n.portuguese;
      case 'de':
        return l10n.german;
      case 'bn':
        return l10n.bangla;
      case 'ta':
        return l10n.tamil;
      case 'gu':
        return l10n.gujarati;
      case 'pa':
        return l10n.punjabi;
      default:
        return l10n.english;
    }
  }

  void _navigateBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    final isCaregiver =
        ref.read(authNotifierProvider).user?.role == UserRole.caregiver;
    context.go(isCaregiver ? '/caregiver/home' : '/patient/home');
  }

  Future<void> _onSelectLanguage(String code) async {
    final normalized = normalizeLanguageCode(code);
    await ref.read(localeProvider.notifier).setLocaleFromString(normalized);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final authToken = await firebaseUser.getIdToken();
        if (authToken != null) {
          final apiService = PatientApiService(
            baseUrl: Environment.apiBaseUrl,
            authToken: authToken,
          );
          await apiService.updateLanguagePreferences(
            appLanguage: normalized,
            visitLanguage: normalized,
          );
        }
      }
    } catch (_) {
      // Locale still applies locally; backend sync can retry on next selection.
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _localizedLanguageName(l10n, normalized);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.languageUpdated(name)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final selectedCode = normalizeLanguageCode(locale.languageCode);
    final l10n = AppLocalizations.of(context)!;
    final languageCount = kSupportedLanguages.length;

    return Scaffold(
      backgroundColor: RemiShellUi.bodyCream,
      body: SafeArea(
        child: Column(
          children: [
            RemiShellUi.screenHeader(
              context: context,
              title: l10n.language,
              onBack: _navigateBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languagesAvailableCount(languageCount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scrollForMoreLanguages,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: languageCount,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _languageTile(
                  theme: theme,
                  l10n: l10n,
                  index: index,
                  selectedCode: selectedCode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageTile({
    required ThemeData theme,
    required AppLocalizations l10n,
    required int index,
    required String selectedCode,
  }) {
    final opt = kSupportedLanguages[index];
    final isSelected = opt.code == selectedCode;
    final displayName = _localizedLanguageName(l10n, opt.code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSelectLanguage(opt.code),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                opt.nativeName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
