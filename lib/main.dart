import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/auth/auth_page.dart';
import '/screens/student/dashboard/dashboard_screen.dart';
import '/screens/student/student_details_page.dart';
import '/screens/admin/admin_dashboard_screen.dart';
import 'firebase_options.dart';
import 'widgets/splash_screen.dart';
import 'utils/profile_image_notifier.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ProfileImageNotifier.init(); // Initialize the profile image notifier
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize app: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDarkMode = false;
  bool _showSplashScreen = true; // Flag to show splash screen on fresh launch
  bool _isFreshLaunch = true; // Flag to track fresh launch vs. resume

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App is resumed from background
      setState(() {
        _isFreshLaunch = false;
      });
    } else if (state == AppLifecycleState.detached) {
      // App is closed, reset for next launch
      setState(() {
        _isFreshLaunch = true;
        _showSplashScreen = true;
      });
    }
  }

  void toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<Widget> _getInitialScreen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ProfileImageNotifier.init(); // Reinitialize after sign-in
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = userDoc.exists ? userDoc.data()!['role'] : 'student';

        if (role == 'admin') {
          return AdminDashboardScreen(
            toggleDarkMode: toggleDarkMode,
            isDarkMode: _isDarkMode,
          );
        }

        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          return StudentDashboard(
            toggleDarkMode: toggleDarkMode,
            isDarkMode: _isDarkMode,
          );
        } else {
          return StudentDetailsPage(
            toggleDarkMode: toggleDarkMode,
            isDarkMode: _isDarkMode,
          );
        }
      }
      return AuthPage(toggleDarkMode: toggleDarkMode, isDarkMode: _isDarkMode);
    } catch (e) {
      print('Error in _getInitialScreen: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading app'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  setState(() {});
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _onSplashAnimationComplete() {
    setState(() {
      _showSplashScreen = false; // Hide splash screen after animation
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vortex Dashboard',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: _isFreshLaunch && _showSplashScreen
          ? CustomSplashScreen(
              isDarkMode: _isDarkMode,
              onAnimationComplete: _onSplashAnimationComplete,
            )
          : FutureBuilder<Widget>(
              future: _getInitialScreen(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CustomSplashScreen(isDarkMode: _isDarkMode);
                }
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }
                return snapshot.data ??
                    AuthPage(
                        toggleDarkMode: toggleDarkMode,
                        isDarkMode: _isDarkMode);
              },
            ),
    );
  }
}
