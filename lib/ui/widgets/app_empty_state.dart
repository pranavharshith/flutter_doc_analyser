import 'package:flutter/material.dart';
import '/utils/theme.dart';
import 'app_primary_button.dart';

/// Consistent empty / error placeholder for lists and pages.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Convenience for load failures.
  factory AppEmptyState.error({
    Key? key,
    String title = 'Something went wrong',
    String? message,
    String actionLabel = 'Retry',
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      key: key,
      icon: Icons.error_outline,
      title: title,
      message: message,
      actionLabel: onAction != null ? actionLabel : null,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.accentBlue : AppTheme.textMuted;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: muted.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
