import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Shared shell chrome aligned with iOS ASC builds (forest green + cream).
abstract final class RemiShellUi {
  static const Color headerGreen = AppTheme.primaryColor;
  static const Color bodyCream = AppTheme.backgroundColor;
  static const Color navActivePill = Color(0xFF1A3A5C);
  static const Color navActiveIcon = Color(0xFFFFD700);
  static const Color navInactiveIcon = Color(0xFFE6CFA1);

  static BoxDecoration get headerDecoration => const BoxDecoration(
        color: headerGreen,
      );

  static BoxDecoration get navBarDecoration => BoxDecoration(
        color: headerGreen,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Colors.white, width: 0.5),
        ),
      );

  static TextStyle headerTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: 'Merriweather',
        );
  }

  static TextStyle headerSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Colors.white70,
          fontFamily: 'Poppins',
        );
  }

  static Widget screenHeader({
    required BuildContext context,
    required String title,
    VoidCallback? onBack,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: headerDecoration,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: headerTitle(context),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: headerSubtitle(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}
