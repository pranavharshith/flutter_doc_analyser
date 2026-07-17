import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/student/upload_document_screen.dart';
import '/ui/dialogs.dart';
import '/ui/ui.dart';
import '/utils/document_validators.dart';

class VoterIdForm extends StatefulWidget {
  final void Function(int) onTabChange;

  const VoterIdForm({
    super.key,
    required this.onTabChange,
  });

  @override
  State<VoterIdForm> createState() => _VoterIdFormState();
}

class _VoterIdFormState extends State<VoterIdForm> {
  final _formKey = GlobalKey<FormState>();
  final _voterIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedGender;
  bool _showForm = false;
  bool _deciding = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askHasVoterId());
  }

  Future<void> _askHasVoterId() async {
    final result = await AppDialogs.confirmVoterId(context);
    if (!mounted) return;

    if (result == true) {
      setState(() {
        _showForm = true;
        _deciding = false;
      });
      return;
    }

    // No / dismissed → back to Documents tab
    widget.onTabChange(1);
    Navigator.of(context).pop();
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  String? _validateVoterId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter Voter ID Number';
    }
    final id = value.trim().toUpperCase();
    if (!DocumentValidators.isValidVoterIdFormat(id)) {
      return 'Enter a valid EPIC / Voter ID (e.g. ABC1234567)';
    }
    return null;
  }

  String? _validateName(String? value, String emptyMsg) {
    if (value == null || value.trim().isEmpty) return emptyMsg;
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Only alphabets allowed';
    }
    return null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final expectedValues = {
      'voterId': _voterIdController.text.trim().toUpperCase(),
      'name': _nameController.text.trim(),
      'fatherName': _fatherNameController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _selectedGender ?? '',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadDocumentScreen(
          title: 'Voter ID',
          expectedValues: expectedValues,
          essentialFields: const ['voterId', 'name'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voterIdController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deciding || !_showForm) {
      return const AppScaffold(
        title: 'Voter ID',
        body: AppLoading(message: 'Checking…'),
      );
    }

    final fieldStyle = FormStyles.fieldText(context);
    final iconColor = FormStyles.muted(context);

    return AppScaffold(
      title: 'Voter ID',
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
                const SizedBox(height: 8),
                Text('Voter ID Number', style: FormStyles.labelText(context)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _voterIdController,
                  style: fieldStyle,
                  textCapitalization: TextCapitalization.characters,
                  decoration: FormStyles.decoration(
                    context,
                    hintText: 'Enter 10-character Voter ID (e.g. ABC1234567)',
                  ),
                  validator: _validateVoterId,
                ),
                const SizedBox(height: 16),
                Text('Name', style: FormStyles.labelText(context)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: fieldStyle,
                  decoration: FormStyles.decoration(
                    context,
                    hintText: 'Enter full name',
                  ),
                  validator: (v) => _validateName(v, 'Enter Name'),
                ),
                const SizedBox(height: 16),
                Text(
                  "Father's / Husband's Name",
                  style: FormStyles.labelText(context),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fatherNameController,
                  style: fieldStyle,
                  decoration: FormStyles.decoration(
                    context,
                    hintText: "Enter father's/husband's name",
                  ),
                  validator: (v) =>
                      _validateName(v, "Enter Father's/Husband's Name"),
                ),
                const SizedBox(height: 16),
                Text('Date of Birth', style: FormStyles.labelText(context)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDob,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dobController,
                      style: fieldStyle,
                      decoration: FormStyles.decoration(
                        context,
                        hintText: 'DD/MM/YYYY',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: iconColor,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Select Date of Birth'
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Gender', style: FormStyles.labelText(context)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: FormStyles.decoration(context),
                  dropdownColor: FormStyles.dropdownBg(context),
                  style: fieldStyle,
                  icon: Icon(Icons.arrow_drop_down, color: iconColor),
                  items: ['Male', 'Female', 'Other']
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, style: fieldStyle),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? 'Select gender' : null,
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
              child: AppPrimaryButton(
                label: 'Continue to Upload',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
