import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Elevated surface card used across student lists and forms.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.borderRadius = 12,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = color ??
        (isDark ? AppTheme.surfaceDarkAlt : AppTheme.bgLight);

    final decoration = BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: elevation <= 0
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );

    final content = Padding(padding: padding, child: child);

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: content,
              ),
            ),
    );
  }
}
