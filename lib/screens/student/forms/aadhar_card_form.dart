import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/student/upload_document_screen.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import '/utils/document_validators.dart';

class AadharCardForm extends StatefulWidget {
  // FIX: Added onTabChange for consistency with VoterIdForm
  final void Function(int)? onTabChange;

  const AadharCardForm({
    super.key,
    this.onTabChange, // optional — caller may provide it
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

  static const List<String> _states = AppConstants.indianStatesAndUTs;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now());
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  bool _isValidName(String name) => RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);

  /// Format + Verhoeff check-digit (structural validity, not UIDAI lookup).
  bool _isValidAadhar(String aadhar) {
    if (!RegExp(r'^\d{4}\s\d{4}\s\d{4}$').hasMatch(aadhar.trim())) {
      return false;
    }
    return DocumentValidators.validateAadhaar(aadhar);
  }

  Future<void> _saveToFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackBar.error(context, 'User not logged in');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final aadharNumber = _aadharController.text.trim();
      final aadharDigits = aadharNumber.replaceAll(' ', '');
      final documentName = _nameController.text.trim();
      final expectedValues = <String, String>{
        'aadharNumber': aadharNumber,
        'name': documentName,
        'dob': _dobController.text.trim(),
        'gender': _selectedGender ?? '',
        'address': _addressController.text.trim(),
        'state': _selectedState ?? '',
      };

      // SUB-01: form draft only — no uploads/* row and no admin notify until
      // the student finishes image OCR upload in UploadDocumentScreen.
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc('aadhar_card')
          .set({
        'documentName': documentName,
        // SEC-02: do not persist full Aadhaar on the draft — last4 + hash only.
        'formDraft': {
          'name': documentName,
          'dob': expectedValues['dob'],
          'gender': expectedValues['gender'],
          'address': expectedValues['address'],
          'state': expectedValues['state'],
          'aadharLast4': aadharDigits.length >= 4
              ? aadharDigits.substring(aadharDigits.length - 4)
              : '',
          'aadharHash': DocumentValidators.hashDocumentNumber(aadharNumber),
        },
        'formSavedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Do not set status Pending here — that means a real upload exists.
        'locked': false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      AppSnackBar.success(context, 'Details saved — continue to upload photo');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadDocumentScreen(
            title: 'Aadhar Card',
            expectedValues: expectedValues,
            essentialFields: const ['aadharNumber', 'name', 'dob', 'gender'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final fieldStyle = FormStyles.fieldText(context);
    final iconColor = FormStyles.muted(context);
    final dropdownBg = FormStyles.dropdownBg(context);

    return AppScaffold(
      title: 'Aadhar Details',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const WizardStepper(currentStep: 0),
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
                  style: fieldStyle,
                  decoration: _buildInputDecoration(
                    hintText: "Aadhar Number (XXXX XXXX XXXX)",
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (!RegExp(r'^\d{4}\s\d{4}\s\d{4}$').hasMatch(v)) {
                      return 'Enter Aadhar as XXXX XXXX XXXX';
                    }
                    if (!_isValidAadhar(v)) {
                      return 'Invalid Aadhar number (check digit failed)';
                    }
                    return null;
                  },
                ),
                _spacing(),
                _buildFieldLabel("Name"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: fieldStyle,
                  decoration: _buildInputDecoration(hintText: "Enter name"),
                  validator: (value) => _isValidName(value ?? '')
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
                      style: fieldStyle,
                      decoration: _buildInputDecoration(
                        hintText: "DD/MM/YYYY",
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: iconColor,
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
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
                  dropdownColor: dropdownBg,
                  items: ["Male", "Female", "Other"]
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, style: fieldStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select gender' : null,
                  style: fieldStyle,
                  icon: Icon(Icons.arrow_drop_down, color: iconColor),
                ),
                _spacing(),
                _buildFieldLabel("Address"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  style: fieldStyle,
                  decoration: _buildInputDecoration(hintText: "Enter address"),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Enter address' : null,
                ),
                _spacing(),
                _buildFieldLabel("State"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: _buildInputDecoration(),
                  dropdownColor: dropdownBg,
                  items: _states
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, style: fieldStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select state' : null,
                  style: fieldStyle,
                  icon: Icon(Icons.arrow_drop_down, color: iconColor),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSubmitButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: FormStyles.labelText(context));
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return FormStyles.decoration(
      context,
      hintText: hintText,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSubmitButton() {
    return AppPrimaryButton(
      label: 'Continue to Upload',
      isLoading: _isLoading,
      onPressed: _saveToFirebase,
    );
  }
}

class _AadharNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue) {
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
      selection: TextSelection.collapsed(offset: formattedText.length));
  }
}