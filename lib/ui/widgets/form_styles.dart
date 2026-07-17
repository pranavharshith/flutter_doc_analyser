import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Shared field colors/decoration for long student forms.
class FormStyles {
  FormStyles._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) =>
      isDark(context) ? AppTheme.accentBlue : AppTheme.textMuted;

  static Color fieldFill(BuildContext context) =>
      isDark(context) ? AppTheme.inputDark : AppTheme.inputLight;

  static Color dropdownBg(BuildContext context) =>
      isDark(context) ? AppTheme.surfaceDarkAlt : AppTheme.bgLight;

  static TextStyle fieldText(BuildContext context) =>
      TextStyle(color: onSurface(context));

  static TextStyle labelText(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface(context),
          ) ??
      TextStyle(
        fontWeight: FontWeight.bold,
        color: onSurface(context),
      );

  static InputDecoration decoration(
    BuildContext context, {
    String? hintText,
    String? counterText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    final dark = isDark(context);
    final borderColor = dark ? AppTheme.accentBlue : Colors.transparent;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: muted(context)),
      counterText: counterText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: dark
            ? BorderSide(color: borderColor, width: 1)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? AppTheme.accentBlue : AppTheme.primaryMid,
          width: 1.5,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
