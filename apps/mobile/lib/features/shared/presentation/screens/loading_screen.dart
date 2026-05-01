import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/auth_state.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../patient/data/services/patient_api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    print('🔄 LoadingScreen: Initializing app...');

    // Explicitly trigger auth initialization
    Future.microtask(() {
      if (!mounted) return;
      ref.read(authNotifierProvider.notifier).initialize();
    });
  }

  Future<void> _handleAuthState(AuthState authState) async {
    print(
        '🔄 LoadingScreen: _handleAuthState called - Status: ${authState.status}');
    print(
        '🔄 LoadingScreen: Auth state - User: ${authState.user?.email ?? 'null'}, Role: ${authState.user?.role ?? 'null'}');

    if (!mounted) {
      print('🔄 LoadingScreen: Widget not mounted, cannot navigate');
      return;
    }

    if (authState.status == AuthStatus.authenticated) {
      print(
          '🔄 LoadingScreen: User authenticated, fetching language preferences...');

      // Fetch and apply user's language preferences
      // Note: Using PatientApiService but this endpoint works for both patients and caregivers
      try {
        final authToken = await AuthService().getAccessToken();
        if (!mounted) return;
        if (authToken != null) {
          final apiService = PatientApiService(
            baseUrl: Environment.apiBaseUrl,
            authToken: authToken,
          );

          final languagePrefs = await apiService
              .getLanguagePreferences()
              .timeout(const Duration(seconds: 3));
          if (!mounted) return;
          final appLanguage = languagePrefs['app_language'] ?? 'en';

          print('🔄 LoadingScreen: Setting app language to: $appLanguage');
          if (!mounted) return;
          await ref.read(localeProvider.notifier).setLocaleFromString(appLanguage);
        } else {
          print(
              '🔄 LoadingScreen: No auth token available, using default language');
          if (!mounted) return;
          await ref.read(localeProvider.notifier).setLocaleFromString('en');
        }
      } catch (e) {
        print('🔄 LoadingScreen: Failed to fetch language preferences: $e');
        print('🔄 LoadingScreen: Using default language (English)');
        if (!mounted) return;
        await ref.read(localeProvider.notifier).setLocaleFromString('en');
      }

      print('🔄 LoadingScreen: Navigating to role selection...');
      if (!mounted) return;
      context.go('/role-selection');
    } else if (authState.status == AuthStatus.unauthenticated) {
      print(
          '🔄 LoadingScreen: User not authenticated, going to welcome screen...');
      // Go to welcome/onboarding flow
      if (!mounted) return;
      context.go('/welcome');
    } else if (authState.status == AuthStatus.error) {
      print(
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
            // Logo - Simple display
            Image.asset(
              'assets/images/RemiMinder_logo.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // App Name - PM specs: Serif (Merriweather), Bold, primaryGreen
            const Text(
              "RemiMinder.ai",
              style: TextStyle(
                fontFamily: 'Merriweather', // Serif typeface as requested
                fontSize: 36,
                fontWeight: FontWeight.w700, // Bold weight
                color: Color(0xff1B4E59), // primaryGreen (primaryColor)
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 6),

            // Tagline - PM specs: Sans-serif (Poppins), small size, textSecondary
            const Text(
              "Smart AI for Health & Care Coordination",
              style: TextStyle(
                fontFamily: 'Poppins', // Sans-serif as requested
                fontSize: 12, // Small size (~12-14sp) as requested
                color: Color(0xff557A7F), // textSecondary (accentColor)
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
          color: Color(0xff3AA8A1),
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
