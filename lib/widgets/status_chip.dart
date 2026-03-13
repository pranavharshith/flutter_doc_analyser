import 'package:flutter/material.dart';

/// Displays a colour-coded status badge for document verification states.
class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusChip({super.key, required this.status, this.fontSize = 12});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF10B981); // green
      case 'rejected':
        return const Color(0xFFEF4444); // red
      case 'pending':
        return const Color(0xFFF59E0B); // amber
      case 'not submitted':
        return const Color(0xFF6B7280); // grey
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
