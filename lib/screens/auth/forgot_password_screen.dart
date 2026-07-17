import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/validators.dart';
import '/utils/auth_errors.dart';
import '/utils/app_snackbar.dart';
import '/ui/ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      AppSnackBar.success(context, 'Password reset link sent');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, AuthErrors.message(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Forgot Password',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset your password',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to receive a password reset link.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: FormStyles.decoration(
                    context,
                    hintText: 'Email',
                  ),
                  validator: Validators.email,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _sendPasswordResetEmail,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
