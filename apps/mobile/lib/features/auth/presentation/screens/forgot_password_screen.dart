import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildResetView(),
        ),
      ),
    );
  }

  Widget _buildResetView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Top section with title and form
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontFamily:
                        'Merriweather', // Consistent with other auth screens
                    fontWeight: FontWeight.w700, // Bold weight
                    fontSize: 32,
                    color: Color(0xFF1A3A5C), // Dark teal for consistency
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'No worries! Enter your email and we\'ll send you reset instructions.',
                  style: TextStyle(
                    fontFamily:
                        'Poppins', // Consistent sans-serif for body text
                    fontWeight: FontWeight.w400, // Regular weight
                    fontSize: 16, // Slightly smaller for better hierarchy
                    color: Color(0xFF5A5A5A), // Consistent secondary color
                    height: 1.4, // Better readability
                  ),
                ),

                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
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

                const SizedBox(height: 32),

                // Send Reset Instructions Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetInstructions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send Reset Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Centered "Remember your password?" text
          const Text(
            'Remember your password?',
            style: TextStyle(
              fontFamily: 'Poppins', // Consistent typography
              fontWeight: FontWeight.w400, // Regular weight
              fontSize: 14,
              color: Color(0xFF5A5A5A), // Consistent secondary color
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),

          // Bottom section with Back to Login button
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back to Login Button at bottom
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      side: const BorderSide(
                        color: Color(
                            0xFF1A3A5C), // Consistent primary color for border
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontFamily: 'Poppins', // Consistent typography
                        fontWeight: FontWeight.w600, // SemiBold for buttons
                        fontSize: 16,
                        color: Color(0xFF1A3A5C), // Consistent primary color
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendResetInstructions() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Send password reset email via Firebase Auth
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        // Always show generic success message for security
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'If an account exists for this email, we\'ve sent you password reset instructions.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Keep user on screen after showing success message
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message to user
        String errorMessage =
            'Failed to send reset email. Please check the email and try again.';

        if (e is firebase_auth.FirebaseAuthException) {
          switch (e.code) {
            case 'invalid-email':
              errorMessage = 'Please enter a valid email address.';
              break;
            case 'operation-not-allowed':
              errorMessage =
                  'Password reset is not available for this account.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'network-request-failed':
              errorMessage =
                  'Network error. Please check your internet connection.';
              break;
            default:
              // For security, don't reveal if account exists or what auth provider it uses
              errorMessage =
                  'Failed to send reset email. Please check the email and try again.';
          }
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
