import 'package:flutter/material.dart';

/// Full-screen splash shown while auth / Firebase bootstrap completes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/splash_screen_logo.png',
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
                  color: Color(0xFF1B4E59),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart AI for Health & Care Coordination',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1B4E59).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4E59)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
