import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/auth/auth_page.dart';
import '/screens/student/dashboard/dashboard_screen.dart';
import '/screens/student/student_details_page.dart';
import '/screens/admin/admin_dashboard_screen.dart';
import 'firebase_options.dart';
import 'widgets/splash_screen.dart';
import 'utils/profile_image_notifier.dart';
import 'utils/app_constants.dart';
import 'utils/theme.dart'; // FIX: use custom AppTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ProfileImageNotifier.init();
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
  bool _showSplashScreen = true;
  bool _isFreshLaunch = true;

  // Cache only the "where should we land" decision (not the widget instance),
  // so theme toggles rebuild pages with the latest `isDarkMode`.
  Future<_InitialDestination>? _initialDestinationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDarkModePref();
  }

  Future<void> _loadDarkModePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool(AppConstants.prefDarkMode) ?? false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isFreshLaunch = false;
      });
    } else if (state == AppLifecycleState.detached) {
      setState(() {
        _isFreshLaunch = true;
        _showSplashScreen = true;
        _initialDestinationFuture = null; // Reset cache on full app close
      });
    }
  }

  void toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      // Do NOT reset the destination cache; only theme changes.
    });
    await prefs.setBool(AppConstants.prefDarkMode, _isDarkMode);
  }

  Future<_InitialDestination> _getInitialDestination() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ProfileImageNotifier.init();
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = userDoc.exists ? userDoc.data()!['role'] : 'student';

        if (role == 'admin') {
          return _InitialDestination.adminDashboard;
        }

        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists &&
            (studentDoc.data() as Map<String, dynamic>)
                .containsKey('firstName')) {
          return _InitialDestination.studentDashboard;
        } else {
          return _InitialDestination.studentDetails;
        }
      }
      return _InitialDestination.auth;
    } catch (e) {
      print('Error in _getInitialScreen: $e');
      return _InitialDestination.error;
    }
  }

  void _onSplashAnimationComplete() {
    setState(() {
      _showSplashScreen = false;
      _initialDestinationFuture ??= _getInitialDestination();
    });
  }

  Widget _buildHomeForDestination(_InitialDestination dest) {
    switch (dest) {
      case _InitialDestination.adminDashboard:
        return AdminDashboardScreen(
          toggleDarkMode: toggleDarkMode,
          isDarkMode: _isDarkMode,
        );
      case _InitialDestination.studentDashboard:
        return StudentDashboard(
          toggleDarkMode: toggleDarkMode,
          isDarkMode: _isDarkMode,
        );
      case _InitialDestination.studentDetails:
        return StudentDetailsPage(
          toggleDarkMode: toggleDarkMode,
          isDarkMode: _isDarkMode,
        );
      case _InitialDestination.auth:
        return AuthPage(toggleDarkMode: toggleDarkMode, isDarkMode: _isDarkMode);
      case _InitialDestination.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Error loading app'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    setState(() {
                      _initialDestinationFuture = null;
                    });
                  },
                  child: const Text('Return to Login'),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vortex Dashboard',
      // FIX: Use AppTheme instead of raw ThemeData.dark()/light()
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isFreshLaunch && _showSplashScreen
          ? CustomSplashScreen(
              isDarkMode: _isDarkMode,
              onAnimationComplete: _onSplashAnimationComplete,
            )
          : FutureBuilder<_InitialDestination>(
              future: _initialDestinationFuture ??= _getInitialDestination(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CustomSplashScreen(isDarkMode: _isDarkMode);
                }
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }
                final dest = snapshot.data ?? _InitialDestination.auth;
                return _buildHomeForDestination(dest);
              },
            ),
    );
  }
}

enum _InitialDestination {
  auth,
  adminDashboard,
  studentDashboard,
  studentDetails,
  error,
}
