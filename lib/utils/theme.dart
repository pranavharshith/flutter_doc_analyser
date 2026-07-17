import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide color tokens and ThemeData definitions.
///
/// Screens should prefer [Theme.of] / [ColorScheme] over these constants,
/// but the constants remain available for one-off decorations (gradients, etc.).
class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF1B263B);
  static const Color primaryMid = Color(0xFF415A77);
  static const Color accentBlue = Color(0xFFB0C4DE);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightAlt = Color(0xFFF5F7FA);
  static const Color bgDark = Color(0xFF0A111F);
  static const Color surfaceDark = Color(0xFF1B263B);
  static const Color surfaceDarkAlt = Color(0xFF2A3A5A);
  static const Color inputDark = Color(0xFF3B4A6B);
  static const Color inputLight = Color(0xFFF1F5F9);

  static const Color textLight = Color(0xFF1B263B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Shared app-bar gradient used across student/admin chrome.
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primaryMid, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> scaffoldGradient(bool isDark) => isDark
      ? const [surfaceDark, bgDark]
      : const [bgLight, bgLightAlt];

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primaryMid,
      onPrimary: bgLight,
      secondary: primaryDark,
      onSecondary: bgLight,
      error: errorRed,
      onError: bgLight,
      surface: bgLight,
      onSurface: textLight,
      surfaceContainerHighest: inputLight,
      outline: const Color(0xFFD1D5DB),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgLightAlt,
      canvasColor: bgLight,
      dividerColor: const Color(0xFFE5E7EB),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryMid,
        foregroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: bgLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: bgLight),
      ),
      cardTheme: CardThemeData(
        color: bgLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMid,
          foregroundColor: bgLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryMid),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMid,
          side: const BorderSide(color: primaryMid),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputLight,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryMid, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        errorStyle: const TextStyle(color: errorRed),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgLightAlt,
        selectedItemColor: primaryMid,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(color: bgLight),
        actionTextColor: accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: bgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(color: textLight),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: bgLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryMid,
        textColor: textLight,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryMid,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMid,
        foregroundColor: bgLight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputLight,
        selectedColor: primaryMid.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: textLight),
        secondaryLabelStyle: const TextStyle(color: bgLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryMid,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryMid,
      ),
      textTheme: _textTheme(textLight, textMuted),
      iconTheme: const IconThemeData(color: primaryMid),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: accentBlue,
      onPrimary: primaryDark,
      secondary: primaryMid,
      onSecondary: bgLight,
      error: errorRed,
      onError: bgLight,
      surface: surfaceDark,
      onSurface: textOnDark,
      surfaceContainerHighest: surfaceDarkAlt,
      outline: const Color(0xFF4B5563),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,
      canvasColor: surfaceDark,
      dividerColor: const Color(0xFF374151),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: bgLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: bgLight),
      ),
      cardTheme: CardThemeData(
        color: surfaceDarkAlt,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMid,
          foregroundColor: bgLight,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentBlue),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentBlue,
          side: const BorderSide(color: accentBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputDark,
        hintStyle: TextStyle(color: accentBlue.withValues(alpha: 0.7)),
        labelStyle: const TextStyle(color: accentBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentBlue, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        errorStyle: const TextStyle(color: errorRed),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accentBlue,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceDarkAlt,
        contentTextStyle: const TextStyle(color: textOnDark),
        actionTextColor: accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceDarkAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(color: textOnDark, fontSize: 14),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentBlue,
        unselectedLabelColor: Color(0xFF9CA3AF),
        indicatorColor: accentBlue,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF374151),
        thickness: 1,
        space: 1,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: accentBlue,
        textColor: textOnDark,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryMid,
        foregroundColor: bgLight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDarkAlt,
        selectedColor: primaryMid.withValues(alpha: 0.4),
        labelStyle: const TextStyle(color: textOnDark),
        secondaryLabelStyle: const TextStyle(color: textOnDark),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: _textTheme(textOnDark, accentBlue),
      iconTheme: const IconThemeData(color: accentBlue),
    );
  }

  static TextTheme _textTheme(Color primary, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 16),
      bodyMedium: TextStyle(color: primary, fontSize: 14),
      bodySmall: TextStyle(color: muted, fontSize: 12),
      labelLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}
