import 'package:flutter/material.dart';

class CustomSplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onAnimationComplete;

  const CustomSplashScreen({
    super.key,
    this.isDarkMode = false,
    this.onAnimationComplete,
  });

  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final int _displayDuration = 2000; // 2 seconds as requested

  @override
  void initState() {
    super.initState();

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Smooth fade over 1 second
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOutQuad,
      ),
    );

    // Start animation once
    _fadeController.forward();

    // Ensure the splash screen displays for exactly 2 seconds
    Future.delayed(Duration(milliseconds: _displayDuration), () {
      if (mounted && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: widget.isDarkMode
                ? [
                    Colors.blueGrey[900]!,
                    Colors.black87,
                  ]
                : [
                    Colors.blue[100]!,
                    Colors.white,
                  ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo without container, matching the image
                Image.asset(
                  'assets/vortex_splash.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                // App title
                Text(
                  'Vortex',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: widget.isDarkMode ? Colors.white : Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Vision-Oriented Recognition\nand Text Extraction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    letterSpacing: 0.8,
                    color: widget.isDarkMode
                        ? Colors.white70
                        : Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 40),
                // Loading indicator
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isDarkMode ? Colors.blue[300]! : Colors.blue[600]!,
                    ),
                    backgroundColor: widget.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
