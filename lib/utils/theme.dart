import 'package:flutter/material.dart';

/// App-wide ThemeData definitions.
class AppTheme {
  static const Color primaryDark = Color(0xFF1B263B);
  static const Color primaryMid = Color(0xFF415A77);
  static const Color accentBlue = Color(0xFFB0C4DE);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightAlt = Color(0xFFF5F7FA);
  static const Color textLight = Color(0xFF1B263B);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryMid,
        secondary: primaryDark,
        error: errorRed,
        surface: bgLight,
      ),
      scaffoldBackgroundColor: bgLightAlt,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryMid,
        foregroundColor: bgLight,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMid,
          foregroundColor: bgLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryMid,
        secondary: accentBlue,
        error: errorRed,
        surface: primaryDark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A111F),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: bgLight,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMid,
          foregroundColor: bgLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A3A5A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
