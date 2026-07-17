import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'providers/theme_controller.dart';
import 'ui/ui.dart';
import 'utils/auth_routing.dart';
import 'utils/profile_image_notifier.dart';
import 'utils/theme.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  await themeController.load();

  // Product is mobile-only (Android / iOS). Keep `web/` scaffold for a future
  // port, but do not run auth/OCR/upload flows in the browser.
  if (kIsWeb) {
    runApp(
      ThemeScope(
        controller: themeController,
        child: ListenableBuilder(
          listenable: themeController,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeController.themeMode,
              home: const Scaffold(
                body: AppEmptyState(
                  icon: Icons.phone_android,
                  title: 'Vortex is a mobile app',
                  message:
                      'Use the Android or iOS build for document scanning, '
                      'OCR, and admin review. Web is not supported.',
                ),
              ),
            );
          },
        ),
      ),
    );
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await ProfileImageNotifier.init();

    runApp(MyApp(themeController: themeController));
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
    runApp(
      ThemeScope(
        controller: themeController,
        child: ListenableBuilder(
          listenable: themeController,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeController.themeMode,
              home: const Scaffold(
                body: AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Failed to initialize app',
                  message:
                      'Please check your connection and fully restart the app.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final ThemeController themeController;

  const MyApp({super.key, required this.themeController});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _showSplashScreen = true;
  bool _isFreshLaunch = true;
  Future<AppHomeDestination>? _initialDestinationFuture;
  StreamSubscription<User?>? _authSub;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // AUTH-04: re-route when session changes / expires.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == _lastUid) return;
      _lastUid = uid;
      if (!mounted) return;
      setState(() {
        _initialDestinationFuture = null;
        if (user != null) {
          ProfileImageNotifier.init();
        } else {
          ProfileImageNotifier.clear();
        }
        // After first frame, skip splash on session switches.
        if (!_isFreshLaunch || !_showSplashScreen) {
          _showSplashScreen = false;
          _initialDestinationFuture = AuthRouting.resolveHomeDestination();
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() => _isFreshLaunch = false);
    } else if (state == AppLifecycleState.detached) {
      setState(() {
        _isFreshLaunch = true;
        _showSplashScreen = true;
        _initialDestinationFuture = null;
      });
    }
  }

  void _onSplashAnimationComplete() {
    setState(() {
      _showSplashScreen = false;
      _initialDestinationFuture ??= AuthRouting.resolveHomeDestination();
    });
  }

  void _retryDestination() {
    setState(() => _initialDestinationFuture = null);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = widget.themeController;

    return ThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Vortex Dashboard',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.themeMode,
            home: _isFreshLaunch && _showSplashScreen
                ? CustomSplashScreen(
                    onAnimationComplete: _onSplashAnimationComplete,
                  )
                : FutureBuilder<AppHomeDestination>(
                    future: _initialDestinationFuture ??=
                        AuthRouting.resolveHomeDestination(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CustomSplashScreen();
                      }
                      if (snapshot.hasError) {
                        return Scaffold(
                          body: AppEmptyState.error(
                            title: 'Error loading app',
                            message: '${snapshot.error}',
                            actionLabel: 'Retry',
                            onAction: _retryDestination,
                          ),
                        );
                      }
                      final dest =
                          snapshot.data ?? AppHomeDestination.auth;
                      return AuthRouting.buildHome(
                        dest,
                        onRetry: _retryDestination,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
