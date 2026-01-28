import 'package:flutter/material.dart';

Widget buildAuthUI({
  required String title,
  required GlobalKey<FormState> formKey,
  TextEditingController? nameController, // Added for name input
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
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Name
                  const Text(
                    'VORTEX',
                    style: TextStyle(
                      color: Color(0xFF1B263B),
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Container for the login form
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: TabBar(
                            controller: tabController,
                            labelColor: const Color(0xFFFFFFFF),
                            unselectedLabelColor: const Color(0xFF6B7280),
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: const Color(0xFF1B263B),
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

                        // Form
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              // Name Input (Sign Up only)
                              if (!isSignIn && nameController != null) ...[
                                TextFormField(
                                  controller: nameController,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Full Name',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    errorStyle: TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters long';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  buildCounter:
                                      (
                                        context, {
                                        required currentLength,
                                        required isFocused,
                                        maxLength,
                                      }) => null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email Input
                              TextFormField(
                                controller: emailController,
                                style: const TextStyle(
                                  color: Color(0xFF1B263B),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  errorStyle: TextStyle(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => null,
                              ),

                              const SizedBox(height: 16),

                              // Password Input
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                style: const TextStyle(
                                  color: Color(0xFF1B263B),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    onPressed: togglePasswordVisibility,
                                  ),
                                  errorStyle: const TextStyle(
                                    color: Color(0xFFEF4444),
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => null,
                              ),

                              // Confirm Password (for Sign Up only)
                              if (confirmPasswordController != null &&
                                  obscureConfirmPassword != null &&
                                  toggleConfirmPasswordVisibility != null) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: obscureConfirmPassword,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Confirm Password',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      onPressed:
                                          toggleConfirmPasswordVisibility,
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  buildCounter:
                                      (
                                        context, {
                                        required currentLength,
                                        required isFocused,
                                        maxLength,
                                      }) => null,
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Forgot Password (Sign In only)
                              if (isSignIn && onForgotPassword != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: onForgotPassword,
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Color(0xFF415A77),
                                      ),
                                    ),
                                  ),
                                ),

                              // Toggle Links (Sign In: "Don't have an account? Sign Up", Sign Up: "Already have an account? Sign in")
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    onToggle();
                                    tabController.animateTo(isSignIn ? 1 : 0);
                                  },
                                  child: Text(
                                    toggleText,
                                    style: const TextStyle(
                                      color: Color(0xFF415A77),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Submit Button
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF415A77),
                                      Color(0xFF1B263B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : onSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      isLoading
                                          ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                          : Text(
                                            buttonText,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFFFFFF),
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
      ),
    ),
  );
}
