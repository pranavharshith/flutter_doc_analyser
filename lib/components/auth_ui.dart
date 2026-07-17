import 'package:flutter/material.dart';
import '/providers/theme_controller.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';

/// Shared Sign In / Sign Up chrome. Fully theme-aware — no light-only colors.
Widget buildAuthUI({
  required String title,
  required GlobalKey<FormState> formKey,
  TextEditingController? nameController,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  TextEditingController? confirmPasswordController,
  required bool obscurePassword,
  bool? obscureConfirmPassword,
  required VoidCallback togglePasswordVisibility,
  VoidCallback? toggleConfirmPasswordVisibility,
  required bool isLoading,
  required VoidCallback onSubmit,
  required String buttonText,
  required String toggleText,
  required VoidCallback onToggle,
  required bool isSignIn,
  required TabController tabController,
  VoidCallback? onForgotPassword,
}) {
  return Builder(
    builder: (context) {
      final isDark = context.isDarkMode;
      final scheme = context.colorScheme;
      final muted = isDark ? AppTheme.accentBlue : AppTheme.textMuted;
      final onSurface = scheme.onSurface;
      final cardColor = isDark ? AppTheme.surfaceDarkAlt : AppTheme.bgLight;
      final fieldFill = isDark ? AppTheme.inputDark : AppTheme.inputLight;
      final tabTrack = isDark ? AppTheme.surfaceDark : AppTheme.inputLight;

      InputDecoration fieldDecoration({
        required String hint,
        Widget? suffixIcon,
      }) {
        return InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: muted),
          filled: true,
          fillColor: fieldFill,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
          errorStyle: TextStyle(color: scheme.error),
        );
      }

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppTheme.scaffoldGradient(isDark),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 8,
                  child: ThemeToggleButton(
                    color: isDark ? AppTheme.accentBlue : AppTheme.primaryDark,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/vortex_icon.jpg',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.verified_user_outlined,
                                size: 64,
                                color: onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'VORTEX',
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.35 : 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: tabTrack,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: TabBar(
                                    controller: tabController,
                                    labelColor: AppTheme.bgLight,
                                    unselectedLabelColor: muted,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.primaryMid
                                          : AppTheme.primaryDark,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    dividerColor: Colors.transparent,
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    tabs: const [
                                      Tab(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          child: Text('Sign In'),
                                        ),
                                      ),
                                      Tab(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          child: Text('Sign Up'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Form(
                                  key: formKey,
                                  child: Column(
                                    children: [
                                      if (!isSignIn &&
                                          nameController != null) ...[
                                        TextFormField(
                                          controller: nameController,
                                          style: TextStyle(color: onSurface),
                                          decoration: fieldDecoration(
                                            hint: 'Full Name',
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your full name';
                                            }
                                            if (value.trim().length < 2) {
                                              return 'Name must be at least 2 characters long';
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      TextFormField(
                                        controller: emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: TextStyle(color: onSurface),
                                        decoration:
                                            fieldDecoration(hint: 'Email'),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                              .hasMatch(value)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                        autovalidateMode: AutovalidateMode
                                            .onUserInteraction,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: passwordController,
                                        obscureText: obscurePassword,
                                        style: TextStyle(color: onSurface),
                                        decoration: fieldDecoration(
                                          hint: 'Password',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscurePassword
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: muted,
                                            ),
                                            onPressed:
                                                togglePasswordVisibility,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters long';
                                          }
                                          return null;
                                        },
                                        autovalidateMode: AutovalidateMode
                                            .onUserInteraction,
                                      ),
                                      if (confirmPasswordController != null &&
                                          obscureConfirmPassword != null &&
                                          toggleConfirmPasswordVisibility !=
                                              null) ...[
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller:
                                              confirmPasswordController,
                                          obscureText:
                                              obscureConfirmPassword,
                                          style: TextStyle(color: onSurface),
                                          decoration: fieldDecoration(
                                            hint: 'Confirm Password',
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                obscureConfirmPassword
                                                    ? Icons
                                                        .visibility_off_outlined
                                                    : Icons
                                                        .visibility_outlined,
                                                color: muted,
                                              ),
                                              onPressed:
                                                  toggleConfirmPasswordVisibility,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value !=
                                                passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      if (isSignIn &&
                                          onForgotPassword != null)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: onForgotPassword,
                                            child: Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppTheme.accentBlue
                                                    : AppTheme.primaryMid,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            onToggle();
                                            tabController
                                                .animateTo(isSignIn ? 1 : 0);
                                          },
                                          child: Text(
                                            toggleText,
                                            style: TextStyle(
                                              color: isDark
                                                  ? AppTheme.accentBlue
                                                  : AppTheme.primaryMid,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.appBarGradient,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              isLoading ? null : onSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppTheme.bgLight,
                                                  ),
                                                )
                                              : Text(
                                                  buttonText,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: AppTheme.bgLight,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
