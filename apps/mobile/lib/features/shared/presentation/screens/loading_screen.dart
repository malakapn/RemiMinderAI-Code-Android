import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/pending_invite_token.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/auth_state.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../patient/data/services/patient_api_service.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/supported_languages.dart';
import '../../../../core/widgets/brand_logo.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  bool _hasNavigated = false;
  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('🔄 LoadingScreen: Initializing app...');

    // Explicitly trigger auth initialization
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authNotifierProvider.notifier).initialize();
    });
  }

  Future<void> _handleAuthState(AuthState authState) async {
    if (kDebugMode) print(
        '🔄 LoadingScreen: _handleAuthState called - Status: ${authState.status}');
    if (kDebugMode) print(
        '🔄 LoadingScreen: Auth state - User: ${authState.user?.email ?? 'null'}, Role: ${authState.user?.role ?? 'null'}');

    if (!mounted) {
      if (kDebugMode) print('🔄 LoadingScreen: Widget not mounted, cannot navigate');
      return;
    }

    if (authState.status == AuthStatus.authenticated) {
      if (_hasNavigated) return; // Already navigated, don't re-trigger
      if (kDebugMode) print(
          '🔄 LoadingScreen: User authenticated, fetching language preferences...');

      // Fetch and apply user's language preferences
      // Note: Using PatientApiService but this endpoint works for both patients and caregivers
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Authentication required');
      final authToken = await firebaseUser.getIdToken(true);
        if (!mounted) return;
        if (authToken != null) {
          final apiService = PatientApiService(
            baseUrl: Environment.apiBaseUrl,
            authToken: authToken,
          );

          final prefs = await SharedPreferences.getInstance();
          final savedCode = prefs.getString(kPreferredLanguagePrefsKey);
          if (savedCode != null && savedCode.trim().isNotEmpty) {
            if (kDebugMode) {
              print(
                  '🔄 LoadingScreen: Applying saved language preference: $savedCode');
            }
            if (!mounted) return;
            await ref
                .read(localeProvider.notifier)
                .setLocaleFromString(savedCode);
          } else {
            final languagePrefs = await apiService
                .getLanguagePreferences()
                .timeout(const Duration(seconds: 3));
            if (!mounted) return;
            final appLanguage =
                normalizeLanguageCode(
                  languagePrefs['app_language'] ??
                      kDefaultLanguageCode,
                );
            if (kDebugMode) {
              print(
                  '🔄 LoadingScreen: Setting app language from API: $appLanguage');
            }
            if (!mounted) return;
            await ref
                .read(localeProvider.notifier)
                .setLocaleFromString(appLanguage);
          }
        }
      } catch (e) {
        if (kDebugMode) print('🔄 LoadingScreen: Failed to fetch language preferences: $e');
        if (kDebugMode) print(
            '🔄 LoadingScreen: Keeping locale from local saved preferences');
      }

      // Route based on saved role — skip role selection if already chosen
      _hasNavigated = true;
      final role = authState.user?.role;
      final inviteRoute = await PendingInviteToken.consumeRoute();
      if (inviteRoute != null) {
        if (kDebugMode) {
          print('🔄 LoadingScreen: Pending invite found, navigating to accept...');
        }
        if (!mounted) return;
        context.go(inviteRoute);
        return;
      }
      if (role == UserRole.caregiver) {
        if (kDebugMode) print('🔄 LoadingScreen: Navigating to caregiver home...');
        if (!mounted) return;
        context.go('/caregiver/home');
      } else if (role == UserRole.patient) {
        if (kDebugMode) print('🔄 LoadingScreen: Navigating to patient home...');
        if (!mounted) return;
        context.go('/patient/home');
      } else {
        if (kDebugMode) print('🔄 LoadingScreen: No role saved, navigating to role selection...');
        if (!mounted) return;
        context.go('/role-selection');
      }
    } else if (authState.status == AuthStatus.unauthenticated) {
      _hasNavigated = false;
      if (kDebugMode) print(
          '🔄 LoadingScreen: User not authenticated, going to welcome screen...');
      // Go to welcome/onboarding flow
      if (!mounted) return;
      context.go('/welcome');
    } else if (authState.status == AuthStatus.error) {
      if (kDebugMode) print(
          '🔄 LoadingScreen: Auth error occurred, going to welcome screen...');
      // Go to welcome/onboarding flow
      if (!mounted) return;
      context.go('/welcome');
    }
    // If still loading, continue showing loading screen
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      _handleAuthState(next);
    });

    return Scaffold(
      backgroundColor: Theme.of(context)
          .scaffoldBackgroundColor, // Consistent with all other screens

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 160),

            const SizedBox(height: 20),

            // App Name - PM specs: Serif (Merriweather), Bold, primaryGreen
            const Text(
              "RemiMinder.ai",
              style: TextStyle(
                fontFamily: 'Merriweather', // Serif typeface as requested
                fontSize: 36,
                fontWeight: FontWeight.w700, // Bold weight
                color: Color(0xff1A3A5C), // primaryGreen (primaryColor)
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 6),

            // Tagline - PM specs: Sans-serif (Poppins), small size, textSecondary
            const Text(
              "Capture what matters. Remember what's next.",
              style: TextStyle(
                fontFamily: 'Poppins', // Sans-serif as requested
                fontSize: 12, // Small size (~12-14sp) as requested
                color: Color(0xff4A7FB5), // textSecondary (accentColor)
              ),
            ),

            const SizedBox(height: 28),

            // Loading dots animation
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LoadingDot(delay: 0),
                _LoadingDot(delay: 300),
                _LoadingDot(delay: 600),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDot extends StatefulWidget {
  final int delay;
  const _LoadingDot({required this.delay});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          color: Color(0xff4A7FB5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
