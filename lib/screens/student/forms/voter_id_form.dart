import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/student/upload_document_screen.dart';
import '/screens/student/document_upload_screen.dart';

class VoterIdForm extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final void Function(int) onTabChange; // Callback to change the tab

  const VoterIdForm({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.onTabChange, // Add the callback as a required parameter
  });

  @override
  State<VoterIdForm> createState() => _VoterIdFormState();
}

class _VoterIdFormState extends State<VoterIdForm> {
  final _formKey = GlobalKey<FormState>();
  final _spacing = const SizedBox(height: 16);
  final TextEditingController _voterIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _selectedGender;
  bool _showForm = false; // To control form visibility after popup

  String? _validateVoterId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter Voter ID Number";
    } else if (!RegExp(r'^[a-zA-Z0-9]{10}$').hasMatch(value)) {
      return "Voter ID should be exactly 10 alphanumeric characters";
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter Name";
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Only alphabets allowed";
    }
    return null;
  }

  String? _validateFatherName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter Father's/Husband's Name";
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Only alphabets allowed";
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Select Date of Birth";
    }
    return null;
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
      fieldLabelText: 'Date of Birth',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      _dobController.text = formatted;
    }
  }

  @override
  void initState() {
    super.initState();
    // Show the popup when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVoterIdPopup();
    });
  }

  Future<void> _showVoterIdPopup() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A3A5A) : const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon for visual appeal
                const Icon(
                  Icons.how_to_vote,
                  size: 48,
                  color: Color(0xFF415A77),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Do you have a Voter ID?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1B263B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Yes Button
                    Container(
                      width: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true), // Yes
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // No Button
                    Container(
                      width: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Close the dialog
                          widget.onTabChange(1); // Switch to Documents tab (assumed index 1)
                          Navigator.of(context).pop(); // Pop the VoterIdForm screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      // If "Yes" is clicked, show the form
      setState(() {
        _showForm = true;
      });
    }
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
    if (!_showForm) {
      // Return an empty scaffold until the popup decision is made
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                            Text(
                              "Voter ID Number",
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _voterIdController,
                              keyboardType: TextInputType.text, // Changed to allow alphanumeric input
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter 10 digit Voter ID (e.g., ABC1234567)",
                                hintStyle: TextStyle(
                                  color:
                                      widget.isDarkMode
                                          ? const Color(0xFFB0C4DE)
                                          : const Color(0xFF6B7280),
                                ),
                                filled: true,
                                fillColor:
                                    widget.isDarkMode
                                        ? const Color(0xFF3B4A6B)
                                        : const Color(0xFFE6E9EF),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: _validateVoterId,
                            ),
                            _spacing,
                            Text(
                              "Name",
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter full name",
                                hintStyle: TextStyle(
                                  color:
                                      widget.isDarkMode
                                          ? const Color(0xFFB0C4DE)
                                          : const Color(0xFF6B7280),
                                ),
                                filled: true,
                                fillColor:
                                    widget.isDarkMode
                                        ? const Color(0xFF3B4A6B)
                                        : const Color(0xFFE6E9EF),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: _validateName,
                            ),
                            _spacing,
                            Text(
                              "Father's/Husband's Name",
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fatherNameController,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter father's/husband's name",
                                hintStyle: TextStyle(
                                  color:
                                      widget.isDarkMode
                                          ? const Color(0xFFB0C4DE)
                                          : const Color(0xFF6B7280),
                                ),
                                filled: true,
                                fillColor:
                                    widget.isDarkMode
                                        ? const Color(0xFF3B4A6B)
                                        : const Color(0xFFE6E9EF),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: _validateFatherName,
                            ),
                            _spacing,
                            Text(
                              "Date of Birth",
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDob,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _dobController,
                                  style: TextStyle(
                                    color:
                                        widget.isDarkMode
                                            ? const Color(0xFFFFFFFF)
                                            : const Color(0xFF1B263B),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "DD/MM/YYYY",
                                    hintStyle: TextStyle(
                                      color:
                                          widget.isDarkMode
                                              ? const Color(0xFFB0C4DE)
                                              : const Color(0xFF6B7280),
                                    ),
                                    suffixIcon: Icon(
                                      Icons.calendar_month,
                                      color:
                                          widget.isDarkMode
                                              ? const Color(0xFFB0C4DE)
                                              : const Color(0xFF1B263B),
                                    ),
                                    filled: true,
                                    fillColor:
                                        widget.isDarkMode
                                            ? const Color(0xFF3B4A6B)
                                            : const Color(0xFFE6E9EF),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      borderSide:
                                          widget.isDarkMode
                                              ? const BorderSide(
                                                color: Color(0xFFB0C4DE),
                                                width: 1.0,
                                              )
                                              : BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      borderSide:
                                          widget.isDarkMode
                                              ? const BorderSide(
                                                color: Color(0xFFB0C4DE),
                                                width: 1.0,
                                              )
                                              : BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: _validateDob,
                                ),
                              ),
                            ),
                            _spacing,
                            Text(
                              "Gender",
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    widget.isDarkMode
                                        ? const Color(0xFF3B4A6B)
                                        : const Color(0xFFE6E9EF),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide:
                                      widget.isDarkMode
                                          ? const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                            width: 1.0,
                                          )
                                          : BorderSide.none,
                                ),
                              ),
                              dropdownColor:
                                  widget.isDarkMode
                                      ? const Color(0xFF2A3A5A)
                                      : const Color(0xFFFFFFFF),
                              value: _selectedGender,
                              items:
                                  ["Male", "Female", "Other"]
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(
                                            gender,
                                            style: TextStyle(
                                              color:
                                                  widget.isDarkMode
                                                      ? const Color(0xFFFFFFFF)
                                                      : const Color(0xFF1B263B),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedGender = value),
                              validator:
                                  (value) =>
                                      value == null ? "Select gender" : null,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
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
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // Create expected values map from form data
                                    Map<String, String> expectedValues = {
                                      'voterId': _voterIdController.text.trim(),
                                      'name': _nameController.text.trim(),
                                      'fatherName':
                                          _fatherNameController.text.trim(),
                                      'dob': _dobController.text.trim(),
                                      'gender': _selectedGender ?? '',
                                    };

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UploadDocumentScreen(
                                          title: "Voter ID",
                                          toggleDarkMode: widget.toggleDarkMode,
                                          isDarkMode: widget.isDarkMode,
                                          expectedValues: expectedValues,
                                          essentialFields: const [],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  "Continue to Upload",
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
                            ),
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
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'VOTERID DETAILS',
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
}