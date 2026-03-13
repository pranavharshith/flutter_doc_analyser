import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/auth/auth_page.dart';

class AdminSettingsScreen extends StatelessWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const AdminSettingsScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Account Info ──
            _sectionHeader('Account', isDarkMode),
            _settingsTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin Account',
              subtitle:
                  FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),

            // ── Appearance ──
            _sectionHeader('Appearance', isDarkMode),
            _settingsTile(
              icon: isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              title: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              subtitle: 'Current: ${isDarkMode ? 'Dark' : 'Light'}',
              isDarkMode: isDarkMode,
              onTap: toggleDarkMode,
            ),
            const SizedBox(height: 12),

            // ── Document Review ──
            _sectionHeader('Review Thresholds', isDarkMode),
            _settingsTile(
              icon: Icons.percent,
              title: 'Auto-verify Threshold',
              subtitle: '90% similarity triggers auto-verify',
              isDarkMode: isDarkMode,
            ),
            _settingsTile(
              icon: Icons.timer,
              title: 'Trash Retention',
              subtitle: 'Deleted notifications retained for 15 days',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),

            // ── About ──
            _sectionHeader('About', isDarkMode),
            _settingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'Vortex Dashboard v1.0.0',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),

            // ── Sign out ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthPage(
                          toggleDarkMode: toggleDarkMode,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDarkMode
              ? const Color(0xFFB0C4DE)
              : const Color(0xFF415A77),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    VoidCallback? onTap,
  }) {
    return Card(
      color: isDarkMode ? const Color(0xFF2A3A5A) : Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDarkMode
              ? const Color(0xFFB0C4DE)
              : const Color(0xFF415A77),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1B263B),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        onTap: onTap,
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right,
                color: isDarkMode
                    ? const Color(0xFFB0C4DE)
                    : const Color(0xFF6B7280),
              )
            : null,
      ),
    );
  }
}
