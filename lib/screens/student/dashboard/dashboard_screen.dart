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
import '/screens/student/trash_screen.dart'; // Corrected import path
import '/screens/student/profile_screen.dart';
import 'package:vortex_dashboard/widgets/profile_image_widget.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const StudentDashboard({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSubmittedDetails');
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AuthPage(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardContent();
      case 1:
        return DocumentUploadScreen(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
          onTabChange: _onItemTapped,
        );
      case 2:
        return const NotificationsScreen();
      default:
        return DashboardContent();
    }
  }

  // Stream to fetch unread notifications count for the student
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: const Color(0xFFFFFFFF),
            ),
            tooltip: "Toggle Theme",
            onPressed: widget.toggleDarkMode,
          ),
          PopupMenuButton<int>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      toggleDarkMode: widget.toggleDarkMode,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                );
              } else if (value == 3) {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: Icon(
                    Icons.person,
                    color: widget.isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF415A77),
                  ),
                  title: Text(
                    "Profile",
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                    ),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 3,
                child: ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Color(0xFFEF4444),
                  ),
                  title: const Text(
                    "Sign Out",
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ProfileImageWidget(
                radius: 20, // Matches the default CircleAvatar size
                isDarkMode: widget.isDarkMode,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isDarkMode
                  ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF415A77), Color(0xFF1B263B)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProfileImageWidget(
                      radius: 40, // Larger size for the DrawerHeader
                      isDarkMode: widget.isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "\ud83d\udcda Menu",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              _drawerItem(Icons.help, "FAQ", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              }, widget.isDarkMode),
              _drawerItem(Icons.delete_outline, "Trash", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrashScreen()),
                );
              }, widget.isDarkMode),
              _drawerItem(Icons.contact_support, "Help", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpScreen()),
                );
              }, widget.isDarkMode),
              const Divider(),
              _drawerItem(
                Icons.logout,
                "Logout",
                _signOut,
                widget.isDarkMode,
                color: const Color(0xFFEF4444),
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
            selectedItemColor: const Color(0xFF415A77),
            unselectedItemColor: widget.isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF6B7280),
            backgroundColor: widget.isDarkMode
                ? const Color(0xFF1B263B)
                : const Color(0xFFF5F7FA),
            onTap: _onItemTapped,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.upload_file),
                label: "Documents",
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 10 ? '10+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Notifications",
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
    VoidCallback onTap,
    bool isDarkMode, {
    Color color = Colors.black,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color != Colors.black
            ? color
            : (isDarkMode ? const Color(0xFFB0C4DE) : const Color(0xFF415A77)),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color != Colors.black
              ? color
              : (isDarkMode
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF1B263B)),
        ),
      ),
      onTap: onTap,
    );
  }
}
