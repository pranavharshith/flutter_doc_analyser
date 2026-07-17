import 'package:flutter/material.dart';
import '/utils/theme.dart';

/// Shared confirm dialogs for student flows.
class AppDialogs {
  AppDialogs._();

  /// Returns `true` if the user confirms logout.
  static Future<bool> confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your documents.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Voter ID optional document prompt.
  /// Returns `true` = has Voter ID, `false` = skip, `null` if dismissed.
  static Future<bool?> confirmVoterId(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final muted = Theme.of(ctx).brightness == Brightness.dark
            ? AppTheme.accentBlue
            : AppTheme.textMuted;
        return AlertDialog(
          icon: const Icon(Icons.how_to_vote_outlined, size: 40),
          title: const Text('Do you have a Voter ID?'),
          content: Text(
            'Voter ID is optional. Choose Yes to enter details, or No to skip.',
            style: TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.bgLight,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
