import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/auth_ui.dart';
import '/screens/auth/forgot_password_screen.dart';
import '/utils/auth_errors.dart';
import '/utils/auth_routing.dart';
import '/utils/app_snackbar.dart';

class SignInPage extends StatefulWidget {
  final VoidCallback onToggle;
  final TabController tabController;

  const SignInPage({
    super.key,
    required this.onToggle,
    required this.tabController,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;

      AppSnackBar.success(context, 'Login successful');
      await AuthRouting.navigateToResolvedHome(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, AuthErrors.message(e));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return buildAuthUI(
      title: 'Sign In',
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      togglePasswordVisibility: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      isLoading: _isLoading,
      onSubmit: _signIn,
      buttonText: 'Sign In',
      toggleText: "Don't have an account? Sign Up",
      onToggle: widget.onToggle,
      isSignIn: true,
      tabController: widget.tabController,
      onForgotPassword: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
      });
  }
}
