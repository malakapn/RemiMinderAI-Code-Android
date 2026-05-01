import 'package:flutter/material.dart';

/// Full-screen splash shown while auth / Firebase bootstrap completes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _background = Color(0xFFF8F4E8);
  static const Color _teal = Color(0xFF1B4E59);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'RemiMinder.ai',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _teal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart AI for Health & Care Coordination',
                style: TextStyle(
                  fontSize: 14,
                  color: _teal.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
