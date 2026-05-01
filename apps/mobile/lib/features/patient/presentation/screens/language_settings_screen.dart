import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LangOption {
  const _LangOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  final String code;
  final String englishName;
  final String nativeName;
}

const List<_LangOption> _kLanguages = [
  _LangOption(code: 'en', englishName: 'English', nativeName: 'English'),
  _LangOption(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  _LangOption(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
];

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  String _normalizeCode(String raw) {
    switch (raw.toLowerCase()) {
      case 'es':
        return 'es';
      case 'hi':
        return 'hi';
      default:
        return 'en';
    }
  }

  String _summaryLanguageName(String code) {
    switch (_normalizeCode(code)) {
      case 'es':
        return 'Spanish';
      case 'hi':
        return 'Hindi';
      default:
        return 'English';
    }
  }

  void _navigateBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/patient/home');
  }

  Future<void> _onSelectLanguage(String code) async {
    final normalized = _normalizeCode(code);
    await ref.read(localeProvider.notifier).setLocaleFromString(normalized);
    if (!mounted) return;
    final name = _summaryLanguageName(normalized);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language updated. New summaries will be generated in $name.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final selectedCode = _normalizeCode(locale.languageCode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _navigateBack,
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.language ?? 'Language',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                itemCount: _kLanguages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final opt = _kLanguages[index];
                  final isSelected = opt.code == selectedCode;

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
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.08)
                              : theme.colorScheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt.englishName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              opt.nativeName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 26,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
