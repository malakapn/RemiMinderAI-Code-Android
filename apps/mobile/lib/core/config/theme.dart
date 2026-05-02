import 'package:flutter/material.dart';

/// App-wide theme configuration
class AppTheme {
  // Healthcare-focused Colors (matching loading screen)
  static const Color primaryColor =
      Color(0xff1B4E59); // Dark teal - main brand color
  static const Color secondaryColor =
      Color(0xff3AA8A1); // Light teal - accent color
  static const Color backgroundColor =
      Color(0xffF8F4E8); // Warm off-white background
  static const Color accentColor =
      Color(0xff557A7F); // Medium teal for secondary text
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
