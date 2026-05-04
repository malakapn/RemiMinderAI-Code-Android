import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible =
      false; // false = password hidden, true = password visible
  bool _rememberMe = false; // Remember me checkbox state
  String? _userRole;
  String? _careInviteToken;

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Role mismatch: chose Caregiver sign-in but account is a patient (or the reverse).
    if (errorString.contains('not registered as a caregiver')) {
      return 'You are not a caregiver. Use Patient sign-in for this account.';
    }
    if (errorString.contains('not registered as a patient')) {
      return 'You are not a patient. Use Caregiver sign-in for this account.';
    }

    // Authentication errors
    if (errorString.contains('invalid email or password') ||
        errorString.contains('invalid_credentials') ||
        errorString.contains('invalid-credential') ||
        errorString.contains('invalid-login-credentials') ||
        errorString.contains('incorrect password')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (errorString.contains('email not confirmed') ||
        errorString.contains('email_not_confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('user_not_found')) {
      return 'No account found with this email address.';
    }

    // Network/API errors
    if (errorString.contains('connection refused') ||
        errorString.contains('network') ||
        errorString.contains('failed to get user profile')) {
      return 'Connection error. Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Generic fallback
    return 'Sign in failed. Please try again or contact support if the problem persists.';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get role from navigation parameters
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    _userRole = uri.queryParameters['role'];
    final raw =
        uri.queryParameters['inviteToken'] ?? uri.queryParameters['token'];
    _careInviteToken =
        (raw != null && raw.trim().isNotEmpty) ? raw.trim() : null;
    // Load remember me preference
    _loadRememberMePreference();
  }

  /// Role intent from `/login?role=…`, normalized via [UserRole.tryFromString].
  UserRole? get _intentRole {
    final raw = _userRole?.trim();
    if (raw == null || raw.isEmpty) return null;
    return UserRole.tryFromString(raw) ?? UserRole.patient;
  }

  Future<void> _loadRememberMePreference() async {
    final rememberMe = await SecureStorage().getRememberMe();
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryAcceptPendingCareInvite() async {
    final token = _careInviteToken?.trim();
    if (token == null || token.isEmpty) return;
    if (_intentRole != UserRole.caregiver) return;
    try {
      await CareTeamApiService().acceptInvitation(token: token);
      _careInviteToken = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are connected to your patient\'s care team.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not accept the invitation automatically. '
              'Open Care Team in the menu and tap Accept. (${e.toString()})',
            ),
          ),
        );
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email,
            password,
            selectedRole: _intentRole,
          );

      // Check auth state after login attempt
      final authState = ref.read(authNotifierProvider);

      if (authState.hasError) {
        if (mounted) {
          final errorMessage = _getUserFriendlyErrorMessage(
              authState.errorMessage ?? 'Authentication failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        return;
      }

      if (authState.isAuthenticated) {
        final user = authState.user;

        // Save remember me preference
        await SecureStorage().saveRememberMe(_rememberMe);

        if (user?.isPatient ?? false) {
          if (mounted) {
            context.go('/patient/home');
          }
        } else if (user?.isCaregiver ?? false) {
          await _tryAcceptPendingCareInvite();
          if (mounted) {
            context.go('/caregiver/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _getUserFriendlyErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  void _navigateToEmailForm() {
    // For now, show a simple dialog with email form
    // In a real app, you might want to scroll to a form section
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sign in with Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                        print(
                            '🔐 Password visibility toggled: $_isPasswordVisible');
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _signIn();
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo Section - No circular container, bigger logo
              Image.asset(
                'assets/images/RemiMinder_logo.png',
                width: 140, // Made bigger without container
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.medical_services,
                  color: Color(0xff1B4E59),
                  size: 80, // Larger fallback icon
                ),
              ),

              const SizedBox(height: 24),

              // Brand Name
              const Text(
                'RemiMinder.ai',
                style: TextStyle(
                  fontFamily: 'Merriweather', // Merriweather-Bold font
                  fontWeight: FontWeight.w700, // Bold weight
                  fontSize: 28, // Increased size for more prominence
                  color: Color(0xFF1B4E59), // Dark teal
                  letterSpacing: -0.5, // Better spacing for serif font
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Smart AI for Health & Care Coordination',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins', // Poppins-Regular
                  fontWeight: FontWeight.w400, // Regular
                  fontSize: 13, // 13-14sp
                  color: Color(0xFF5A5A5A), // Gray
                ),
              ),

              const SizedBox(height: 48),

              // Heading - "Login"
              const Text(
                'Login',
                style: TextStyle(
                  fontFamily:
                      'Merriweather', // Merriweather-Bold for consistency
                  fontWeight: FontWeight.w700, // Bold weight
                  fontSize: 28, // Reduced size for better hierarchy
                  color: Color(0xFF1A4D4D), // Dark teal
                ),
              ),

              const SizedBox(height: 48),

              // Google Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white, // White background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3), // Gray border
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation:
                        0, // Remove default elevation since we have shadow
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google logo (currently JPEG - replace with SVG for better quality)
                      Image.asset(
                        'assets/images/google_logo.svg', // Currently a JPEG file
                        width: 22,
                        height: 22,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Apple Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black, // Black background
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _signInWithApple,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation:
                        0, // Remove default elevation since we have shadow
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Apple logo placeholder (add SVG file for real logo)
                      Container(
                        width: 20,
                        height: 24,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Apple',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4E59), // Teal background
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _navigateToEmailForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4E59),
                    foregroundColor: Colors.white,
                    elevation:
                        0, // Remove default elevation since we have shadow
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.email,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Email',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Create Account Link
              Center(
                child: TextButton(
                  onPressed: () {
                    final r = _userRole;
                    final roleQ =
                        (r != null && r.isNotEmpty) ? 'role=$r' : '';
                    final tok = _careInviteToken?.trim();
                    final tokQ = (tok != null && tok.isNotEmpty)
                        ? 'token=${Uri.encodeQueryComponent(tok)}'
                        : '';
                    final parts = [roleQ, tokQ].where((s) => s.isNotEmpty).join('&');
                    final q = parts.isEmpty ? '' : '?$parts';
                    context.go('/register$q');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF1B4E59), // Teal
                      decoration: TextDecoration.underline, // Underlined
                      decorationColor: Color(0xFF1B4E59),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot Password Link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF1B4E59), // Teal
                      decoration: TextDecoration.underline, // Underlined
                      decorationColor: Color(0xFF1B4E59),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle(
            selectedRole: _intentRole,
          );

      // Check auth state after login attempt
      final authState = ref.read(authNotifierProvider);

      if (authState.hasError) {
        if (mounted) {
          final errorMessage = _getUserFriendlyErrorMessage(
              authState.errorMessage ?? 'Authentication failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        return;
      }

      if (authState.isAuthenticated) {
        // Navigate to appropriate home screen based on selected role (not backend role)
        final user = authState.user;

        if (user?.isPatient ?? false) {
          if (mounted) {
            context.go('/patient/home');
          }
        } else if (user?.isCaregiver ?? false) {
          await _tryAcceptPendingCareInvite();
          if (mounted) {
            context.go('/caregiver/home');
          }
        } else {
          if (mounted) {
            context.go('/welcome'); // Fallback
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign In failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyErrorMessage(e)),
          ),
        );
      }
    }
  }

  void _signInWithApple() {
    // TODO: Implement Apple Sign In with Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign In - Coming Soon!')),
    );
  }
}
