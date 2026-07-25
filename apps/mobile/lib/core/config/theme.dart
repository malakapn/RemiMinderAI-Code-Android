import 'package:flutter/material.dart';

/// Caregiver dashboard / invitations UI tokens (Firestore care team flows).
class RemiCareUiColors {
  RemiCareUiColors._();

  static const Color primaryDarkTeal = Color(0xFF1A3A5C);
  static const Color activeTealAccent = Color(0xFF4A7FB5);
  static const Color bodyBackground = Color(0xFFF8F4E8);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color sectionHeaderText = Color(0xFF2D2D2D);
  static const Color bodySubtitleText = Color(0xFF6B6B6B);
  static const Color urgentBadgeText = Color(0xFFB71C1C);
  static const Color highBadgeText = Color(0xFFE65100);
  static const Color confidenceText = Color(0xFF9E9E9E);
  static const Color amberPendingAccent = Color(0xFFF59E0B);
  static const Color blueViewedAccent = Color(0xFF2563EB);
  static const Color grayExpiredAccent = Color(0xFF9CA3AF);
  static const Color tealAcceptButton = Color(0xFF2D6A4F);
  static const Color declineBorder = Color(0xFFBDBDBD);
  static const Color pendingBadgeBg = Color(0x22F59E0B);
  static const Color pendingBadgeText = Color(0xFF854F0B);
  static const Color filterInactiveBg = Color(0xFFEEEEEE);
  static const Color snackbarSuccessBg = Color(0xFF2D6A4F);

  /// My Patients tab
  static const Color subtitleSecondary = Color(0xFF6B6B6B);
  static const Color searchBarBg = Color(0xFFEEEEEE);
  static const Color newBadgeBg = Color(0xFFFEF3C7);
  static const Color newBadgeText = Color(0xFF92400E);
  static const Color newBadgeBorder = Color(0xFFFDE68A);
  static const Color medChipBg = Color(0xFFE6F0FA);
  static const Color medChipText = Color(0xFF1A3A5C);
  static const Color medChipBorder = Color(0xFFB5D4F4);
  static const Color alertChipBg = Color(0xFFFEF3C7);
  static const Color alertChipText = Color(0xFF92400E);
  static const Color alertChipBorder = Color(0xFFFDE68A);
  static const Color syncDot = Color(0xFF2D6A4F);
  static const Color rolePillBg = Color(0xFFE6F1FB);
  static const Color rolePillText = Color(0xFF185FA5);
  static const Color rolePillBorder = Color(0xFFB5D4F4);
  static const Color carePlanButtonText = Color(0xFF2D2D2D);

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          blurRadius: 6,
          color: Color(0x1F000000),
          offset: Offset(0, 2),
        ),
      ];
}

/// App-wide theme configuration
class AppTheme {
  // Healthcare-focused Colors (matching loading screen)
  static const Color primaryColor =
      Color(0xff1A3A5C); // Dark teal - main brand color
  static const Color secondaryColor =
      Color(0xff4A7FB5); // Light teal - accent color
  static const Color backgroundColor =
      Color(0xffF8F4E8); // Warm off-white background
  static const Color accentColor =
      Color(0xff4A7FB5); // Medium teal for secondary text
  static const Color errorColor = Color(0xFFD32F2F);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: accentColor),
      ),
      // PM-specified typography: Merriweather for headings, Poppins for body text
      fontFamily: 'Poppins', // Default font for body text and UI elements
      textTheme: const TextTheme(
        // Main headings use Merriweather (serif)
        headlineLarge: TextStyle(
          color: primaryColor,
          fontSize: 32,
          fontWeight: FontWeight.w700, // Bold
          fontFamily: 'Merriweather', // Serif for headings
          letterSpacing: -0.5, // Tighter for elegance
        ),
        headlineMedium: TextStyle(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w700, // Bold
          fontFamily: 'Merriweather', // Serif for headings
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold, // Use available weight
          fontFamily: 'Merriweather', // Serif for headings
        ),
        // Body text uses Poppins (sans-serif)
        bodyLarge: TextStyle(
          color: accentColor,
          fontSize: 16,
          fontFamily: 'Poppins', // Sans-serif for body text
          height: 1.5, // Better readability
        ),
        bodyMedium: TextStyle(
          color: accentColor,
          fontSize: 14,
          fontFamily: 'Poppins', // Sans-serif for body text
          height: 1.4, // Better readability
        ),
        bodySmall: TextStyle(
          color: accentColor,
          fontSize: 12,
          fontFamily: 'Poppins', // Sans-serif for body text
          height: 1.4,
        ),
        // UI labels and buttons
        labelLarge: TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold, // Use available weight
          fontFamily: 'Poppins',
        ),
        labelMedium: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal, // Use available weight
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
    );
  }
}
