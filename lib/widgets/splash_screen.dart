import 'package:flutter/material.dart';
import '/providers/theme_controller.dart';
import '/utils/theme.dart';

class CustomSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const CustomSplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final int _displayDuration = 2000;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOutQuad,
      ),
    );

    _fadeController.forward();

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
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: isDark
                ? const [AppTheme.surfaceDark, AppTheme.bgDark]
                : [AppTheme.accentBlue.withValues(alpha: 0.35), AppTheme.bgLight],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/vortex_splash.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                Text(
                  'Vortex',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDark ? AppTheme.textOnDark : AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vision-Oriented Recognition\nand Text Extraction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppTheme.accentBlue
                        : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.accentBlue : AppTheme.primaryMid,
                    ),
                    backgroundColor: (isDark ? Colors.white : AppTheme.primaryMid)
                        .withValues(alpha: 0.12),
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
