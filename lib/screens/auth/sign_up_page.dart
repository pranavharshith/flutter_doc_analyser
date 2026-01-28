import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/auth_ui.dart';
import '/screens/auth/auth_page.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final TabController tabController;

  const SignUpPage({
    required this.onToggle,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.tabController,
    super.key,
  });

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Determine role based on email domain
      String role = 'student';
      if (_emailController.text.trim().endsWith('@admin.vortexapp.com')) {
        role = 'admin';
      }

      // Store user data in 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _emailController.text.trim(),
            'createdAt': Timestamp.now(),
            'role': role,
          });

      // Store user data in 'students' collection (if not admin)
      if (role != 'admin') {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(userCredential.user!.uid)
            .set({
              'email': _emailController.text.trim(),
              'role': role,
              'createdAt': Timestamp.now(),
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign Up Successful"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to SignInPage (via AuthPage)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => AuthPage(
                toggleDarkMode: widget.toggleDarkMode,
                isDarkMode: widget.isDarkMode,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return buildAuthUI(
      title: "Sign Up",
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      togglePasswordVisibility: _togglePasswordVisibility,
      toggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
      isLoading: _isLoading,
      onSubmit: _signUp,
      buttonText: "Sign Up",
      toggleText: "Already have an account? Sign in",
      onToggle: widget.onToggle,
      isSignIn: false,
      tabController: widget.tabController,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}