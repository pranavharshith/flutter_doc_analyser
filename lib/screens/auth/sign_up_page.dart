import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/auth_ui.dart';
import '/utils/name_utils.dart';
import '/utils/auth_errors.dart';
import '/utils/auth_routing.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onToggle;
  final TabController tabController;

  const SignUpPage({
    required this.onToggle,
    required this.tabController,
    super.key,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      AppSnackBar.error(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final email = _emailController.text.trim();
      final role = AuthRouting.isAdminEmail(email)
          ? AppConstants.roleAdmin
          : AppConstants.roleStudent;

      final split = NameUtils.splitFullName(_nameController.text);
      final nameFields = NameUtils.firestoreNameFields(
        firstName: split.firstName,
        lastName: split.lastName,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'name': nameFields['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'role': role,
      });

      if (role != AppConstants.roleAdmin) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          ...nameFields,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      AppSnackBar.success(context, 'Sign up successful');
      // AUTH-01: already signed in — route by role (not back to login).
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
      title: 'Sign Up',
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      togglePasswordVisibility: _togglePasswordVisibility,
      toggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
      isLoading: _isLoading,
      onSubmit: _signUp,
      buttonText: 'Sign Up',
      toggleText: 'Already have an account? Sign in',
      onToggle: widget.onToggle,
      isSignIn: false,
      tabController: widget.tabController,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
