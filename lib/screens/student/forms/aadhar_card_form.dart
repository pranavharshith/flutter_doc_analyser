import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/student/upload_document_screen.dart';

class AadharCardForm extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const AadharCardForm({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<AadharCardForm> createState() => _AadharCardFormState();
}

class _AadharCardFormState extends State<AadharCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  String? _selectedGender;
  String? _selectedState;

  static const List<String> _states = [
    "Andhra Pradesh",
    "Bihar",
    "Delhi",
    "Gujarat",
    "Karnataka",
    "Kerala",
    "Maharashtra",
    "Rajasthan",
    "Tamil Nadu",
    "Telangana",
    "Uttar Pradesh",
    "West Bengal",
  ];

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  bool _isValidName(String name) => RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  bool _isValidAadhar(String aadhar) =>
      RegExp(r'^\d{4}\s\d{4}\s\d{4}$').hasMatch(aadhar);

  Future<void> _saveToFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final aadharNumber = _aadharController.text.trim();
      final data = {
        'aadharNumber': aadharNumber,
        'aadharLast4': aadharNumber.replaceAll(' ', '').substring(8),
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'state': _selectedState,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      };

      // Save user details
      await FirebaseFirestore.instance.collection('students').doc(user.uid).set(
        {'name': _nameController.text.trim()},
        SetOptions(merge: true),
      );

      // Save Aadhar details
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc('aadhar_card')
          .set({
            'name': _nameController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
            'locked': false,
          });

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc('aadhar_card')
          .collection('uploads')
          .add(data);

      // Send notification to admin
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .add({
            'message':
                '${_nameController.text.trim()} has submitted Aadhar details',
            'documentType': 'Aadhar Card',
            'userId': user.uid,
            'userName': _nameController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'admin',
            'isRead': false,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aadhar details saved successfully')),
      );

      // Navigate to UploadDocumentScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => UploadDocumentScreen(
                title: 'Aadhar Card',
                toggleDarkMode: widget.toggleDarkMode,
                isDarkMode: widget.isDarkMode,
                expectedValues: {
                  'aadharNumber': aadharNumber,
                  'name': _nameController.text.trim(),
                  'dob': _dobController.text.trim(),
                  'gender': _selectedGender ?? '',
                  'address': _addressController.text.trim(),
                  'state': _selectedState ?? '',
                },
                essentialFields: ['aadharNumber', 'name', 'dob', 'gender'],
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _spacing() => const SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                widget.isDarkMode
                    ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? const Color(0xFF2A3A5A)
                                : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              widget.isDarkMode ? 0.3 : 0.1,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel("Aadhar Number"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _aadharController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(14),
                                _AadharNumberInputFormatter(),
                              ],
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Aadhar Number (XXXX XXXX XXXX)",
                              ),
                              validator:
                                  (value) =>
                                      _isValidAadhar(value ?? '')
                                          ? null
                                          : "Enter valid Aadhar number (XXXX XXXX XXXX)",
                            ),
                            _spacing(),
                            _buildFieldLabel("Name"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter name",
                              ),
                              validator:
                                  (value) =>
                                      _isValidName(value ?? '')
                                          ? null
                                          : "Name should contain only letters",
                            ),
                            _spacing(),
                            _buildFieldLabel("Date of Birth"),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _dobController,
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: "DD/MM/YYYY",
                                    suffixIcon: Icon(
                                      Icons.calendar_month,
                                      color: widget.isDarkMode
                                          ? const Color(0xFFB0C4DE)
                                          : const Color(0xFF1B263B),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Select Date of Birth'
                                              : null,
                                ),
                              ),
                            ),
                            _spacing(),
                            _buildFieldLabel("Gender"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: _buildInputDecoration(),
                              dropdownColor: widget.isDarkMode
                                  ? const Color(0xFF2A3A5A)
                                  : const Color(0xFFFFFFFF),
                              items:
                                  ["Male", "Female", "Other"]
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(
                                            g,
                                            style: TextStyle(
                                              color: widget.isDarkMode
                                                  ? const Color(0xFFFFFFFF)
                                                  : const Color(0xFF1B263B),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null ? 'Select gender' : null,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: widget.isDarkMode
                                    ? const Color(0xFFB0C4DE)
                                    : const Color(0xFF1B263B),
                              ),
                            ),
                            _spacing(),
                            _buildFieldLabel("Address"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressController,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter address",
                              ),
                              maxLines: 3,
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Enter address'
                                          : null,
                            ),
                            _spacing(),
                            _buildFieldLabel("State"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedState,
                              decoration: _buildInputDecoration(),
                              dropdownColor: widget.isDarkMode
                                  ? const Color(0xFF2A3A5A)
                                  : const Color(0xFFFFFFFF),
                              items:
                                  _states
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              color: widget.isDarkMode
                                                  ? const Color(0xFFFFFFFF)
                                                  : const Color(0xFF1B263B),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedState = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null ? 'Select state' : null,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: widget.isDarkMode
                                    ? const Color(0xFFB0C4DE)
                                    : const Color(0xFF1B263B),
                              ),
                            ),
                            _spacing(),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.isDarkMode
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1B263B),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: widget.isDarkMode
            ? const Color(0xFFB0C4DE)
            : const Color(0xFF6B7280),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: widget.isDarkMode
          ? const Color(0xFF3B4A6B)
          : const Color(0xFFE6E9EF),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: widget.isDarkMode
            ? const BorderSide(color: Color(0xFFB0C4DE), width: 1.0)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: widget.isDarkMode
            ? const BorderSide(color: Color(0xFFB0C4DE), width: 1.0)
            : BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'AADHAR DETAILS',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF415A77),
            Color(0xFF1B263B),
          ],
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveToFirebase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFFFFFFF))
                : const Text(
                  'Continue to Upload',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFFFFFF),
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _AadharNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(' ', '');
    if (newText.length > 12) {
      newText = newText.substring(0, 12);
    }
    String formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      if (i == 4 || i == 8) {
        formattedText += ' ';
      }
      formattedText += newText[i];
    }
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}