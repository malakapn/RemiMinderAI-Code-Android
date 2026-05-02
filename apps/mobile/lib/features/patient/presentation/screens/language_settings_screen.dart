import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/patient_api_service.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  static const String _localAppLanguageKey = 'app_language';
  static const String _localVisitLanguageKey = 'visit_language';
  String _selectedAppLanguage = "en";
  String _selectedVisitLanguage = "en";
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, String>> _availableLanguages = [
    {"name": "English", "code": "en"},
    {"name": "Spanish", "code": "es"},
    {"name": "Hindi", "code": "hi"},
    {"name": "Mandarin", "code": "zh"},
    {"name": "Arabic", "code": "ar"},
    {"name": "French", "code": "fr"},
  ];

  String _getLanguageName(String code) {
    return _availableLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {"name": "English", "code": "en"},
    )['name']!;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePreferences();
  }

  Future<void> _loadLanguagePreferences() async {
    final localPrefs = await SharedPreferences.getInstance();
    final cachedAppLanguage = localPrefs.getString(_localAppLanguageKey);
    final cachedVisitLanguage = localPrefs.getString(_localVisitLanguageKey);
    if (mounted &&
        ((cachedAppLanguage?.isNotEmpty ?? false) ||
            (cachedVisitLanguage?.isNotEmpty ?? false))) {
      setState(() {
        _selectedAppLanguage = cachedAppLanguage ?? _selectedAppLanguage;
        _selectedVisitLanguage = cachedVisitLanguage ?? _selectedVisitLanguage;
      });
    }

    try {
      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      final preferences = await apiService.getLanguagePreferences();
      await localPrefs.setString(
          _localAppLanguageKey, preferences['app_language'] ?? 'en');
      await localPrefs.setString(
          _localVisitLanguageKey, preferences['visit_language'] ?? 'en');

      setState(() {
        _selectedAppLanguage = preferences['app_language'] ?? 'en';
        _selectedVisitLanguage = preferences['visit_language'] ?? 'en';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedAppLanguage = cachedAppLanguage ?? "en";
        _selectedVisitLanguage = cachedVisitLanguage ?? "en";
        _isLoading = false;
      });
      if (mounted && cachedAppLanguage == null && cachedVisitLanguage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load language preferences')),
        );
      }
    }
  }

  Future<void> _saveLanguagePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final localPrefs = await SharedPreferences.getInstance();
      await localPrefs.setString(_localAppLanguageKey, _selectedAppLanguage);
      await localPrefs.setString(_localVisitLanguageKey, _selectedVisitLanguage);

      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      await apiService.updateLanguagePreferences(
        appLanguage: _selectedAppLanguage,
        visitLanguage: _selectedVisitLanguage,
      );

      // Update local locale state to trigger UI refresh
      ref
          .read(localeProvider.notifier)
          .setLocaleFromString(_selectedAppLanguage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Language settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final short =
            msg.length > 140 ? '${msg.substring(0, 140)}...' : msg;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save language settings: $short')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showLanguagePicker(BuildContext context, String title,
      String currentLanguage, Function(String) onLanguageSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language Options
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableLanguages.length,
                  itemBuilder: (context, index) {
                    final language = _availableLanguages[index];
                    final languageCode = language['code']!;
                    final languageName = language['name']!;
                    final isSelected = languageCode == currentLanguage;

                    return InkWell(
                      onTap: () {
                        onLanguageSelected(languageCode);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                languageName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                      child: Column(
                        children: [
                          // App Language Row
                          InkWell(
                            onTap: () => _showLanguagePicker(
                              context,
                              'Choose App Language',
                              _selectedAppLanguage,
                              (language) => setState(
                                  () => _selectedAppLanguage = language),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'App Language',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getLanguageName(
                                              _selectedAppLanguage),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Visit Language Row
                          InkWell(
                            onTap: () => _showLanguagePicker(
                              context,
                              'Choose Visit Language',
                              _selectedVisitLanguage,
                              (language) => setState(
                                  () => _selectedVisitLanguage = language),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.mic,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Visit Language',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getLanguageName(
                                              _selectedVisitLanguage),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving ? null : _saveLanguagePreferences,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Save Settings',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Changing visit language affects speech recognition and AI summaries.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
}
