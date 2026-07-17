import 'package:flutter/material.dart';

import '/utils/theme.dart';

/// Theme tokens for admin screens (ADM-DM-02).
///
/// Prefer this over ad-hoc `isDarkMode ? Color(0x…)` forks so light/dark
/// contrast stays consistent (ADM-DM-03…10).
class AdminTheme {
  AdminTheme._(this.isDark);

  final bool isDark;

  factory AdminTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AdminTheme._(dark);
  }

  // ── Surfaces ─────────────────────────────────────────────────────────────
  List<Color> get scaffoldGradient => AppTheme.scaffoldGradient(isDark);

  Color get card => isDark ? AppTheme.surfaceDarkAlt : AppTheme.bgLight;

  /// Nested panel inside a card (doc grid strip, etc.).
  Color get cardInset => isDark ? AppTheme.inputDark : AppTheme.bgLightAlt;

  /// Search / inputs — same family as [card] so fields don’t clash (ADM-DM-05).
  Color get fieldFill => isDark ? AppTheme.inputDark : AppTheme.inputLight;

  Color get scrim => Colors.black.withValues(alpha: isDark ? 0.55 : 0.45);

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? AppTheme.textOnDark : AppTheme.textLight;

  Color get textMuted =>
      isDark ? AppTheme.accentBlue : AppTheme.textMuted;

  Color get textOnBrand => AppTheme.bgLight;

  // ── Accents / icons (ADM-DM-08: lighter on dark) ──────────────────────────
  Color get icon => isDark ? AppTheme.accentBlue : AppTheme.primaryMid;

  Color get brand => AppTheme.primaryMid;

  /// Detail row keys, tab selection (ADM-DM-09 / ADM-DM-10).
  Color get labelAccent =>
      isDark ? AppTheme.accentBlue : AppTheme.primaryMid;

  Color get tabSelected =>
      isDark ? AppTheme.accentBlue : AppTheme.primaryMid;

  Color get tabUnselected => textMuted;

  Color get outline =>
      isDark ? AppTheme.accentBlue.withValues(alpha: 0.35) : AppTheme.primaryMid.withValues(alpha: 0.12);

  // ── Status fills (ADM-DM-03: stronger on dark) ───────────────────────────
  Color statusFill(Color statusColor) =>
      statusColor.withValues(alpha: isDark ? 0.28 : 0.14);

  Color statusBorder(Color statusColor) =>
      statusColor.withValues(alpha: isDark ? 0.7 : 0.4);

  // ── Chips (ADM-DM-04) ────────────────────────────────────────────────────
  Color get chipSelectedBg =>
      isDark ? AppTheme.primaryMid : AppTheme.primaryMid.withValues(alpha: 0.15);

  Color get chipUnselectedBg =>
      isDark ? AppTheme.surfaceDarkAlt : Colors.transparent;

  Color chipLabel(bool selected) {
    if (selected) {
      return isDark ? AppTheme.textOnDark : AppTheme.textLight;
    }
    return textMuted;
  }

  // ── Shadows ──────────────────────────────────────────────────────────────
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: isDark ? 12 : 8,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Gradients ────────────────────────────────────────────────────────────
  LinearGradient get appBarGradient => AppTheme.appBarGradient;

  // ── Progress track (ADM-DM-11 related; usable here) ──────────────────────
  Color get progressTrack =>
      isDark ? AppTheme.primaryMid.withValues(alpha: 0.35) : const Color(0xFFE5E7EB);
}
