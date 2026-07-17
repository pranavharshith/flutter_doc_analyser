import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/auth/auth_page.dart';
import '/screens/student/dashboard/dashboard_content.dart';
import '/screens/student/document_upload_screen.dart';
import '/screens/student/notification_screen.dart';
import '/screens/student/faq_screen.dart';
import '/screens/student/help_screen.dart';
import '/screens/student/trash_screen.dart';
import '/screens/student/profile_screen.dart';
import '/widgets/profile_image_widget.dart';
import '/providers/theme_controller.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';
import '/ui/ui.dart';
import '/ui/dialogs.dart';
import '/utils/name_utils.dart';

/// Student shell: app bar + drawer + 4-tab bottom navigation.
///
/// Tabs: Home · Documents · Notifications · Profile
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _titles = [
    'Dashboard',
    'Upload Documents',
    'Alerts',
    'Profile',
  ];

  /// Bumped when returning to Home so progress reloads after uploads.
  int _homeRefreshToken = 0;

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0 && _selectedIndex != 0) {
        _homeRefreshToken++;
      }
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final confirmed = await AppDialogs.confirmLogout(context);
    if (!confirmed || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSubmittedDetails');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardContent(
          refreshToken: _homeRefreshToken,
          onNavigateToUploads: () => _onItemTapped(1),
          onNavigateToNotifications: () => _onItemTapped(2),
        );
      case 1:
        return DocumentUploadScreen(onTabChange: _onItemTapped);
      case 2:
        return const NotificationsScreen(embedded: true);
      case 3:
        return const ProfileScreen(embedded: true);
      default:
        return DashboardContent(
          refreshToken: _homeRefreshToken,
          onNavigateToUploads: () => _onItemTapped(1),
          onNavigateToNotifications: () => _onItemTapped(2),
        );
    }
  }

  Stream<int> _getUnreadNotificationsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<Map<String, String?>> _studentIdentityStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(const {'name': null, 'email': null});
    }
    return FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final display = NameUtils.displayNameFromMap(data, fallback: '');
      return {
        'name': display.isNotEmpty ? display : null,
        'email': (data?['email'] as String?) ?? user.email,
      };
    });
  }

  void _openRoute(Widget page) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppScaffold.buildAppBar(
        context: context,
        title: _titles[_selectedIndex],
        showBackButton: false,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.bgLight),
          tooltip: 'Open menu',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          const ThemeToggleButton(color: AppTheme.bgLight),
          // Avatar jumps to Profile tab (no duplicate logout menu).
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              label: 'Open profile',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onItemTapped(3),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: ProfileImageWidget(radius: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppTheme.scaffoldGradient(isDark),
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Identity only (not a third Profile entry). Open Profile via
              // bottom tab or app-bar avatar.
              StreamBuilder<Map<String, String?>>(
                stream: _studentIdentityStream(),
                builder: (context, snapshot) {
                  final name = snapshot.data?['name'] ?? 'Student';
                  final email = snapshot.data?['email'] ??
                      FirebaseAuth.instance.currentUser?.email ??
                      '';
                  return DrawerHeader(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.appBarGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const ProfileImageWidget(radius: 32),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.bgLight,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.bgLight.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              _drawerItem(
                Icons.help_outline,
                'FAQ',
                () => _openRoute(const FAQScreen()),
              ),
              _drawerItem(
                Icons.contact_support_outlined,
                'Help',
                () => _openRoute(const HelpScreen()),
              ),
              _drawerItem(
                Icons.delete_outline,
                'Trash',
                () => _openRoute(const TrashScreen()),
              ),
              const Divider(height: 24),
              _drawerItem(
                Icons.logout,
                'Logout',
                () {
                  Navigator.pop(context);
                  _signOut();
                },
                color: AppTheme.errorRed,
              ),
            ],
          ),
        ),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _getUnreadNotificationsCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.upload_file),
                label: 'Documents',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            unreadCount > 10 ? '10+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.bgLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Alerts',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }

  ListTile _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final isDark = context.isDarkMode;
    final effective =
        color ?? (isDark ? AppTheme.accentBlue : AppTheme.primaryMid);
    final textColor =
        color ?? (isDark ? AppTheme.textOnDark : AppTheme.textLight);

    return ListTile(
      leading: Icon(icon, color: effective),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}
