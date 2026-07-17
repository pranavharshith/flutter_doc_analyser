import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Single pattern for user feedback (prefer over Fluttertoast).
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    // ADM-DM-06: theme-aware defaults (avoid light flash in dark mode).
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color? bg;
    Color fg = scheme.onSurface;
    if (isError) {
      bg = AppTheme.errorRed;
      fg = AppTheme.bgLight;
    } else if (isSuccess) {
      bg = AppTheme.successGreen;
      fg = AppTheme.bgLight;
    } else {
      bg = isDark ? AppTheme.surfaceDarkAlt : AppTheme.primaryDark;
      fg = AppTheme.bgLight;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: isDark ? AppTheme.accentBlue : AppTheme.bgLight,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, isSuccess: true);

  static void error(BuildContext context, String message) =>
      show(context, message: message, isError: true);
}
