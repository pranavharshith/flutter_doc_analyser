import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/auth_ui.dart';
import '/screens/auth/forgot_password_screen.dart';
import '/screens/student/student_details_page.dart';
import '/screens/student/dashboard/dashboard_screen.dart';
import '/screens/admin/admin_dashboard_screen.dart';

class SignInPage extends StatefulWidget {
  final VoidCallback onToggle;
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final TabController tabController;

  const SignInPage({
    super.key,
    required this.onToggle,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.tabController,
  });

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
          backgroundColor: Colors.green,
        ),
      );

      // Check user role and navigate accordingly
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
      final role = userDoc.exists ? userDoc.data()!['role'] : 'student';

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboardScreen(
              toggleDarkMode: widget.toggleDarkMode,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      } else {
        // Check if user has submitted details (first sign-in check)
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(userCredential.user!.uid)
                .get();
        final hasSubmittedDetails = studentDoc.exists && studentDoc.data()!.containsKey('firstName');

        if (!hasSubmittedDetails) {
          // First sign-in after sign-up, redirect to StudentDetailsPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsPage(
                toggleDarkMode: widget.toggleDarkMode,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        } else {
          // Subsequent sign-ins, redirect to StudentDashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboard(
                toggleDarkMode: widget.toggleDarkMode,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        }
      }
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
      title: "Sign In",
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      togglePasswordVisibility:
          () => setState(() => _obscurePassword = !_obscurePassword),
      isLoading: _isLoading,
      onSubmit: _signIn,
      buttonText: "Sign In",
      toggleText: "Don't have an account? Sign Up",
      onToggle: widget.onToggle,
      isSignIn: true,
      tabController: widget.tabController,
      onForgotPassword: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
        );
      },
    );
  }
}