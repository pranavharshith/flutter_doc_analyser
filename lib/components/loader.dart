import 'package:flutter/material.dart';

/// A full-screen centred loading spinner with an optional message.
class AppLoader extends StatelessWidget {
  final String? message;
  final bool isDarkMode;

  const AppLoader({super.key, this.message, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF415A77),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: isDarkMode
                    ? const Color(0xFFB0C4DE)
                    : const Color(0xFF6B7280),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
