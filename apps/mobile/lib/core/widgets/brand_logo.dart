import 'package:flutter/material.dart';

import '../config/theme.dart';

/// RemiMinder logo that blends with the app beige scaffold (removes baked-in white PNG box).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 120,
    this.assetPath = 'assets/images/RemiMinder_logo.png',
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final beige = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: beige,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          color: beige,
          colorBlendMode: BlendMode.multiply,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.medical_services,
            size: size * 0.55,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
