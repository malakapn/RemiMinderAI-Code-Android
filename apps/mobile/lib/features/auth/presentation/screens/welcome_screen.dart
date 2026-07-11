import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/brand_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String _tagline = "Capture what matters. Remember what's next.";
  static const String _bodyCopy =
      'Record visits and everyday moments, keep what was said, and get gentle reminders when you need them—without juggling another health app.';

  @override
  Widget build(BuildContext context) {
    final compactLayout = MediaQuery.sizeOf(context).height < 820;

    final gapAfterSkip = compactLayout ? 24.0 : 32.0;
    final gapAfterLogo = compactLayout ? 20.0 : 32.0;
    final gapAfterTitle = compactLayout ? 10.0 : 16.0;
    final gapAfterTagline = compactLayout ? 12.0 : 24.0;
    final gapBeforeButton = compactLayout ? 24.0 : 48.0;
    final gapBelowExpanded = compactLayout ? 16.0 : 24.0;
    final gapBottom = compactLayout ? 12.0 : 16.0;

    final brandingColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: compactLayout ? 100 : 120),
        SizedBox(height: gapAfterLogo),
        Text(
          'Welcome to RemiMinder',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: compactLayout ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: gapAfterTitle),
        Text(
          _tagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: compactLayout ? 16 : 18,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: gapAfterTagline),
        Text(
          _bodyCopy,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: compactLayout ? 14 : null,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: gapBeforeButton),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/role-selection'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );

    final skipButton = Align(
      alignment: Alignment.topRight,
      child: TextButton(
        onPressed: () => context.go('/role-selection'),
        child: Text(
          'Skip',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ),
    );

    final pageDots = const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IndicatorDot(isActive: true),
        SizedBox(width: 8),
        _IndicatorDot(isActive: false),
        SizedBox(width: 8),
        _IndicatorDot(isActive: false),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          skipButton,
                          SizedBox(height: gapAfterSkip),
                          brandingColumn,
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(height: gapBelowExpanded),
                          pageDots,
                          SizedBox(height: gapBottom),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
