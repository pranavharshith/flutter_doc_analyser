import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/screens/auth/auth_page.dart';
import '/ui/dialogs.dart';
import '/ui/ui.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Settings',
      actions: const [ThemeToggleButton(color: AppTheme.bgLight)],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.accentBlue : AppTheme.primaryMid,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryMid.withValues(alpha: 0.15),
                child: const Icon(Icons.admin_panel_settings,
                    color: AppTheme.primaryMid),
              ),
              title: const Text('Admin account'),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Review',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.accentBlue : AppTheme.primaryMid,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined,
                      color: AppTheme.primaryMid),
                  title: const Text('OCR match'),
                  subtitle: const Text(
                    'On-device OCR is a suggestion only — you confirm Verified or Rejected.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.timer_outlined, color: AppTheme.primaryMid),
                  title: const Text('Trash retention'),
                  subtitle: const Text(
                    'Deleted notifications are kept for 15 days.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.accentBlue : AppTheme.primaryMid,
                ),
          ),
          const SizedBox(height: 8),
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: AppTheme.primaryMid),
              title: Text('Vortex Dashboard'),
              subtitle: Text('v1.0.0 · Mobile admin'),
            ),
          ),
          const SizedBox(height: 28),
          AppPrimaryButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () async {
              final ok = await AppDialogs.confirmLogout(context);
              if (!ok || !context.mounted) return;
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
