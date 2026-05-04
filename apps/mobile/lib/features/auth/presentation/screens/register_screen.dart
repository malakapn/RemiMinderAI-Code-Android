import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.inviteToken});

  /// Optional invite token from email link (`token` or `inviteToken` query param).
  final String? inviteToken;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  /// Provider may still be null until post-frame; URL `?role=` is the source of truth for signup.
  UserRole? _effectiveRoleForSignup() {
    final fromProvider = ref.read(selectedRoleProvider);
    if (fromProvider != null) return fromProvider;
    final q = GoRouterState.of(context).uri.queryParameters;
    final role = q['role']?.toLowerCase();
    if (role == 'caregiver') return UserRole.caregiver;
    if (role == 'patient') return UserRole.patient;
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final q = GoRouterState.of(context).uri.queryParameters;
    final role = q['role']?.toLowerCase();
    // Cannot call selectRole (Riverpod) synchronously here — still inside build.
    if (role == 'caregiver' || role == 'patient') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (role == 'caregiver') {
          ref.read(selectedRoleProvider.notifier).selectRole(UserRole.caregiver);
        } else {
          ref.read(selectedRoleProvider.notifier).selectRole(UserRole.patient);
        }
      });
    }
    final em = q['email'];
    if (em != null && em.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = Uri.decodeComponent(em);
    }
  }

  String _caregiverInviteMessage(String reason) {
    switch (reason) {
      case 'no_pending_invite':
        return 'No pending invitation found for this email. '
            'You can still register as a caregiver and connect when an invite arrives.';
      case 'invalid_token':
        return 'This invitation link is invalid. Ask your patient for a new invite.';
      case 'email_mismatch':
        return 'This invite is for a different email address. Use the invited email.';
      case 'expired':
        return 'This invitation has expired. Ask your patient to send a new one.';
      case 'not_pending':
        return 'This invitation is no longer active.';
      default:
        return 'Could not verify caregiver invitation. Please try again.';
    }
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Authentication errors
    if (errorString.contains('user already registered') ||
        errorString.contains('account with this email already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (errorString.contains('weak password') ||
        errorString.contains('password')) {
      return 'Password is too weak. Please use at least 8 characters with letters and numbers.';
    }

    if (errorString.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    // Network/API errors
    if (errorString.contains('connection refused') ||
        errorString.contains('network')) {
      return 'Connection error. Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Generic fallback
    return 'Registration failed. Please try again or contact support if the problem persists.';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  ref.watch(selectedRoleProvider) == UserRole.caregiver
                      ? 'Create your caregiver account with Google or email. '
                          'Patient details appear after someone invites you by email and you accept.'
                      : 'Join RemiMinder to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                      ),
                ),

                const SizedBox(height: 48),

                // Name Fields (Row)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          hintText: 'John',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          hintText: 'Doe',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'john.doe@example.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a strong password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'By creating an account, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showTermsOfService,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _showPrivacyPolicy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _acceptTerms && !ref.watch(isAuthLoadingProvider)
                        ? _registerWithEmail
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                          _acceptTerms && !ref.watch(isAuthLoadingProvider)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                    ),
                    child: ref.watch(isAuthLoadingProvider)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bottom indicator dots
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IndicatorDot(isActive: false),
                    SizedBox(width: 8),
                    _IndicatorDot(isActive: false),
                    SizedBox(width: 8),
                    _IndicatorDot(isActive: false),
                    SizedBox(width: 8),
                    _IndicatorDot(isActive: true),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SingleChildScrollView(
            child: Text(
              'Terms of Service for RemiMinder\n\n'
              '1. Acceptance of Terms\n'
              'By using RemiMinder, you agree to these terms.\n\n'
              '2. Use of Service\n'
              'RemiMinder is designed to help manage healthcare and medication reminders.\n\n'
              '3. Privacy\n'
              'Your privacy is important to us. All health data is handled securely.\n\n'
              '4. Account Responsibility\n'
              'You are responsible for maintaining the confidentiality of your account.\n\n'
              '5. Limitation of Liability\n'
              'RemiMinder is not a substitute for professional medical advice.\n\n'
              'For the complete Terms of Service, please visit our website.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'Privacy Policy for RemiMinder\n\n'
              '1. Information We Collect\n'
              'We collect information you provide and usage data to improve our service.\n\n'
              '2. How We Use Information\n'
              'Information is used to provide healthcare management services and improve user experience.\n\n'
              '3. Information Sharing\n'
              'We do not sell your personal information. Data is only shared with healthcare providers you authorize.\n\n'
              '4. Data Security\n'
              'We implement industry-standard security measures to protect your health data.\n\n'
              '5. Your Rights\n'
              'You have the right to access, correct, or delete your personal information.\n\n'
              'For the complete Privacy Policy, please visit our website.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerWithEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please accept the Terms and Conditions')),
        );
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();

      final selectedRole = _effectiveRoleForSignup();
      if (selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role first')),
        );
        return;
      }

      if (selectedRole == UserRole.caregiver) {
        final inviteTok = widget.inviteToken?.trim();
        if (inviteTok != null && inviteTok.isNotEmpty) {
          final v = await CareTeamApiService().validateCaregiverSignup(
            email: email,
            token: inviteTok,
          );
          if (v['ok'] != true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _caregiverInviteMessage(v['reason']?.toString() ?? ''),
                  ),
                ),
              );
            }
            return;
          }
        }
      }

      try {
        await ref.read(authNotifierProvider.notifier).signUp(
              email: email,
              password: password,
              role: selectedRole,
              fullName: fullName,
            );

        if (selectedRole == UserRole.caregiver) {
          final inviteTok = widget.inviteToken?.trim();
          if (inviteTok != null && inviteTok.isNotEmpty) {
            try {
              await CareTeamApiService().acceptInvitation(token: inviteTok);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Account created. Sign in and open Care Team to finish accepting your invitation if needed.',
                    ),
                  ),
                );
              }
            }
          }
        }

        // Show success dialog and navigate to login
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Account Created!'),
                content:
                    const Text('Your account has been created successfully. '
                        'You can now sign in with your email and password.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      final selectedRole = ref.read(selectedRoleProvider);
                      final roleParam = selectedRole == UserRole.patient
                          ? 'patient'
                          : 'caregiver';
                      final tok = widget.inviteToken?.trim();
                      final tokQ = (tok != null && tok.isNotEmpty)
                          ? '&token=${Uri.encodeQueryComponent(tok)}'
                          : '';
                      context.go('/login?role=$roleParam$tokQ');
                    },
                    child: const Text('Go to Sign In'),
                  ),
                ],
              );
            },
          );
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
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;

  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
