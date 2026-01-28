import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '/screens/student/dashboard/dashboard_screen.dart';

class StudentDetailsPage extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const StudentDetailsPage({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = '+91'; // Default to India

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
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

  // Email validation regex
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Create a new document in the students collection
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .set({
        'firstName': _nameController.text,
        'lastName': _lastNameController.text,
        'phone': '$_selectedCountryCode${_phoneController.text.trim()}',
        'email': _emailController.text.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create document placeholders for each document type
      final documentTypes = [
        'aadhar_card',
        'voter_id',
        '10th_marksheet',
        '12th_marksheet',
      ];

      for (var docType in documentTypes) {
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
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Details submitted successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboard(
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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

                    // Container for the form
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
                          // Title
                          const Text(
                            'Student Details',
                            style: TextStyle(
                              color: Color(0xFF1B263B),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // First Name
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'First Name',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  buildCounter: (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) =>
                                      null,
                                ),

                                const SizedBox(height: 16),

                                // Last Name
                                TextFormField(
                                  controller: _lastNameController,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Last Name',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your last name';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  buildCounter: (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) =>
                                      null,
                                ),

                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  validator: _validateEmail,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  buildCounter: (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) =>
                                      null,
                                ),

                                const SizedBox(height: 16),

                                // Phone Number with Country Code Dropdown
                                IntlPhoneField(
                                  controller: _phoneController,
                                  style: const TextStyle(
                                    color: Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  initialCountryCode: 'IN', // Default to India
                                  onChanged: (phone) {
                                    setState(() {
                                      _selectedCountryCode = phone.countryCode;
                                    });
                                  },
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    // Validate length based on country code
                                    if (_selectedCountryCode == '+91' &&
                                        phone.number.length != 10) {
                                      return 'Indian phone numbers must be 10 digits';
                                    }
                                    if (_selectedCountryCode == '+1' &&
                                        phone.number.length != 10) {
                                      return 'US/Canada phone numbers must be 10 digits';
                                    }
                                    if (_selectedCountryCode == '+44' &&
                                        phone.number.length != 10) {
                                      return 'UK phone numbers must be 10 digits';
                                    }
                                    if (_selectedCountryCode == '+61' &&
                                        phone.number.length != 10) {
                                      return 'Australian phone numbers must be 10 digits';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
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
                                    onPressed:
                                        _isLoading ? null : _submitDetails,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            'Submit Details',
                                            style: TextStyle(
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
}
