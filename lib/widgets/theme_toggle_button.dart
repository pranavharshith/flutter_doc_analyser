import 'package:flutter/material.dart';
import '/providers/theme_controller.dart';

/// Simple light ⇄ dark toggle (no menu / System option).
class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  final String tooltip;

  const ThemeToggleButton({
    super.key,
    this.color,
    this.tooltip = 'Toggle theme',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = color ?? Theme.of(context).appBarTheme.foregroundColor;

    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: fg,
      ),
      onPressed: () => ThemeScope.read(context).toggle(context),
    );
  }
}
