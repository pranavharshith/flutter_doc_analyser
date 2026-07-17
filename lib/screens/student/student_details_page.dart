import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/auth/auth_page.dart';
import '/screens/student/dashboard/dashboard_screen.dart';
import '/ui/dialogs.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import '/utils/name_utils.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';

class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({super.key});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    _prefillFromAccount();
  }

  Future<void> _prefillFromAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _emailController.text = user.email ?? '';

    try {
      final student = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      if (student.exists) {
        final data = student.data()!;
        final first = (data['firstName'] as String?)?.trim() ?? '';
        final last = (data['lastName'] as String?)?.trim() ?? '';
        if (first.isNotEmpty) _nameController.text = first;
        if (last.isNotEmpty) _lastNameController.text = last;
        if (first.isEmpty && last.isEmpty) {
          final name = (data['name'] as String?)?.trim() ?? '';
          if (name.isNotEmpty) {
            final split = NameUtils.splitFullName(name);
            _nameController.text = split.firstName;
            _lastNameController.text = split.lastName;
          }
        }
        final phone = (data['phone'] as String?)?.trim();
        if (phone != null && phone.isNotEmpty && !phone.startsWith('+')) {
          _phoneController.text = phone;
        }
      }

      if (_nameController.text.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final name = (userDoc.data()?['name'] as String?)?.trim() ?? '';
          if (name.isNotEmpty) {
            final split = NameUtils.splitFullName(name);
            _nameController.text = split.firstName;
            _lastNameController.text = split.lastName;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Prefill is best-effort
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _signOut() async {
    final confirmed = await AppDialogs.confirmLogout(context);
    if (!confirmed || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSubmittedDetails');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      final nameFields = NameUtils.firestoreNameFields(
        firstName: _nameController.text,
        lastName: _lastNameController.text,
      );

      await FirebaseFirestore.instance.collection('students').doc(user.uid).set({
        ...nameFields,
        'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
        'email': _emailController.text.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameFields['name'],
        'email': _emailController.text.trim(),
        'role': AppConstants.roleStudent,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final documentTypes = AppConstants.documentTypes
          .map((type) => type.toLowerCase().replaceAll(' ', '_'))
          .toList();

      for (final docType in documentTypes) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .collection('documents')
            .doc(docType)
            .set({
          'status': 'Not Submitted',
          'locked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      AppSnackBar.success(context, 'Details submitted successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not save details. Please try again.');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = FormStyles.fieldText(context);
    final muted = FormStyles.muted(context);

    return AppScaffold(
      title: 'Complete your profile',
      showBackButton: false,
      actions: [
        const ThemeToggleButton(color: AppTheme.bgLight),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout, color: AppTheme.bgLight),
          onPressed: _isLoading ? null : _signOut,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'VORTEX',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us a bit about yourself to continue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: muted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Student details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      style: fieldStyle,
                      decoration: FormStyles.decoration(
                        context,
                        hintText: 'First name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your first name'
                          : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      style: fieldStyle,
                      decoration: FormStyles.decoration(
                        context,
                        hintText: 'Last name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your last name'
                          : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: fieldStyle,
                      keyboardType: TextInputType.emailAddress,
                      decoration: FormStyles.decoration(
                        context,
                        hintText: 'Email',
                      ),
                      validator: _validateEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                      controller: _phoneController,
                      style: fieldStyle,
                      dropdownTextStyle: fieldStyle,
                      decoration: FormStyles.decoration(
                        context,
                        hintText: 'Phone number',
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _selectedCountryCode = phone.countryCode;
                      },
                      validator: (phone) {
                        if (phone == null || phone.number.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (_selectedCountryCode == '+91' &&
                            phone.number.length != 10) {
                          return 'Indian phone numbers must be 10 digits';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Submit details',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submitDetails,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
