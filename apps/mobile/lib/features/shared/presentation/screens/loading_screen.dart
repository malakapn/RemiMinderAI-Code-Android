import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _localAppLanguageKey = 'app_language';

  @override
  void initState() {
    super.initState();
    // Also check current state immediately after first frame in case
    // auth state was already resolved before the listener was set up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = ref.read(authNotifierProvider);
      if (currentState.status != AuthStatus.loading) {
        _handleAuthState(currentState);
      }
    });
  }

  Future<void> _handleAuthState(AuthState authState) async {
    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      final user = authState.user;

      // Navigate immediately — don't block on language fetch
      final destination = (user?.isCaregiver ?? false)
          ? '/caregiver/home'
          : '/patient/home';
      context.go(destination);

      // Fetch language prefs in background after navigation
      _fetchLanguagePrefsInBackground();

    } else if (authState.status == AuthStatus.unauthenticated ||
               authState.status == AuthStatus.error) {
      context.go('/welcome');
    }
    // AuthStatus.loading — stay on loading screen
  }

  void _fetchLanguagePrefsInBackground() {
    Future.microtask(() async {
      try {
        final localPrefs = await SharedPreferences.getInstance();
        final cachedAppLanguage = localPrefs.getString(_localAppLanguageKey);
        if (cachedAppLanguage != null &&
            cachedAppLanguage.trim().isNotEmpty &&
            mounted) {
          ref
              .read(localeProvider.notifier)
              .setLocaleFromString(cachedAppLanguage);
        }

        final authToken = await AuthService().getAccessToken();
        if (authToken == null || !mounted) return;
        final apiService = PatientApiService(
          baseUrl: Environment.apiBaseUrl,
          authToken: authToken,
        );
        final languagePrefs = await apiService
            .getLanguagePreferences()
            .timeout(const Duration(seconds: 3));
        if (!mounted) return;
        final appLanguage = languagePrefs['app_language'] ?? 'en';
        await localPrefs.setString(_localAppLanguageKey, appLanguage);
        ref.read(localeProvider.notifier).setLocaleFromString(appLanguage);
      } catch (_) {
        // Non-critical — use default language
      }
    });
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
