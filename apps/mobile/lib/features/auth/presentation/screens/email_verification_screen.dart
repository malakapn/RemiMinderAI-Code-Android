import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color _navy = Color(0xFF1A3A5C);
  static const Color _cream = Color(0xFFF8F4E8);

  Timer? _checkTimer;
  bool _isResending = false;
  bool _emailSent = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _startCooldown();
  }

  void _startVerificationCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      if (user.emailVerified) {
        _checkTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified! Please sign in.')),
          );
          await firebase_auth.FirebaseAuth.instance.signOut();
          final role = GoRouterState.of(context).uri.queryParameters['role'] ?? 'patient';
          context.go('/login?role=$role');
        }
      }
    });
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) _resendCooldown--;
        });
        if (_resendCooldown == 0) _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_isResending || _resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = firebase_auth.FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () async {
            await firebase_auth.FirebaseAuth.instance.signOut();
            if (mounted) context.go('/welcome');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 40, color: _navy),
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _navy),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your inbox and tap the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _resendCooldown > 0 || _isResending ? null : _resendEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : _isResending
                            ? 'Sending...'
                            : 'Resend Verification Email',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await firebase_auth.FirebaseAuth.instance.signOut();
                  if (mounted) {
                    final role = GoRouterState.of(context).uri.queryParameters['role'] ?? 'patient';
                    context.go('/login?role=$role');
                  }
                },
                child: const Text('Back to Sign In', style: TextStyle(color: _navy)),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
