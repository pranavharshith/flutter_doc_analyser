import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Colour-coded document / verification status pill.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.showIcon = true,
  });

  /// Shared status → brand color mapping.
  ///
  /// Accepts bare labels (`Verified`) and count chips (`Verified 12`).
  static Color colorFor(String status) {
    final s = status.toLowerCase().trim();
    if (s.startsWith('verified')) return AppTheme.successGreen;
    if (s.startsWith('rejected')) return AppTheme.errorRed;
    if (s.startsWith('pending')) return AppTheme.warningAmber;
    if (s.startsWith('not submitted') || s.startsWith('not_submitted')) {
      return AppTheme.textMuted;
    }
    return AppTheme.textMuted;
  }

  Color get color => colorFor(status);

  IconData get _icon {
    final s = status.toLowerCase().trim();
    if (s.startsWith('verified')) return Icons.check_circle;
    if (s.startsWith('rejected')) return Icons.cancel;
    if (s.startsWith('pending')) return Icons.pending_actions;
    return Icons.hourglass_empty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
