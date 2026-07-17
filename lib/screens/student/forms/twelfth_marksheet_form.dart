import 'package:flutter/material.dart';
import '/ui/ui.dart';
import '/screens/student/upload_document_screen.dart';

class TwelfthMarksheetForm extends StatefulWidget {
  // FIX: Added for consistency with VoterIdForm
  final void Function(int)? onTabChange;

  const TwelfthMarksheetForm({
    super.key,
    this.onTabChange,
  });

  @override
  State<TwelfthMarksheetForm> createState() => _TwelfthMarksheetFormState();
}

class _TwelfthMarksheetFormState extends State<TwelfthMarksheetForm> {
  final _formKey = GlobalKey<FormState>();
  final _spacing = const SizedBox(height: 16);
  final TextEditingController _examDateController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _schoolAddressController =
      TextEditingController();
  final TextEditingController _hallTicketController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();
  bool _isLoading = false;

  String? _selectedMedium;
  String? _selectedBoard;

  // Define essential fields for verification
  final List<String> _essentialFields = [
    'hallTicket',
    'totalMarks',
    'examDate',
  ];

  // Mapping of boards to their total marks for 12th
  final Map<String, int> _boardTotalMarks = {
    'CBSE': 500,
    'Telangana Inter': 1000, // Updated from 1000 to 600
    'ICSE / ISC (CISCE)': 400,
    'Tamil Nadu HSC': 600,
    'Assam HSLC': 600,
  };

  @override
  void dispose() {
    _examDateController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _hallTicketController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _selectMonthYear() async {
    final formatted = await showMonthYearPicker(
      context,
      helpText: 'Examination month & year',
    );
    if (formatted != null && mounted) {
      setState(() => _examDateController.text = formatted);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Create expected values map from form data
      Map<String, String> expectedValues = {
        'schoolName': _schoolNameController.text.trim(),
        'address':
            _schoolAddressController.text
                .trim(), // Renamed to 'address' to match UploadDocumentScreen
        'medium': _selectedMedium ?? '',
        'board': _selectedBoard ?? '',
        'hallTicket': _hallTicketController.text.trim(),
        'totalMarks': _totalMarksController.text.trim(),
        'examDate': _examDateController.text.trim(),
      };

      // Navigate to UploadDocumentScreen with essential fields
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => UploadDocumentScreen(
                title: "12th Marksheet",
                expectedValues: expectedValues,
                essentialFields: _essentialFields, // Pass essential fields
              ))).then((_) => setState(() => _isLoading = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '12th Marksheet',
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
                            _buildFieldLabel("School Name"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _schoolNameController,
                              style: FormStyles.fieldText(context),
                              decoration: _buildInputDecoration(
                                hintText: "Enter school name"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter school name";
                                } else if (!RegExp(
                                  r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                  return "Only alphabets allowed";
                                }
                                return null;
                              }),
                            _spacing,
                            _buildFieldLabel("School Address"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _schoolAddressController,
                              maxLines: 4,
                              style: FormStyles.fieldText(context),
                              decoration: _buildInputDecoration(
                                hintText: "Enter address"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter address";
                                }
                                return null;
                              }),
                            _spacing,
                            _buildFieldLabel("Medium"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(),
                              dropdownColor: FormStyles.dropdownBg(context),
                              initialValue: _selectedMedium,
                              items:
                                  [
                                        "English",
                                        "Hindi",
                                        "Tamil",
                                        "Telugu",
                                        "Urdu",
                                        "Malayalam",
                                      ]
                                      .map(
                                        (lang) => DropdownMenuItem(
                                          value: lang,
                                          child: Text(
                                            lang,
                                            style: FormStyles.fieldText(context),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedMedium = value),
                              validator:
                                  (value) =>
                                      value == null ? "Select medium" : null,
                              style: FormStyles.fieldText(context),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: FormStyles.muted(context))),
                            _spacing,
                            _buildFieldLabel("Board"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(),
                              dropdownColor: FormStyles.dropdownBg(context),
                              initialValue: _selectedBoard,
                              items: [
                                "CBSE",
                                "Telangana Inter",
                                "ICSE / ISC (CISCE)",
                                "Tamil Nadu HSC",
                                "Assam HSLC",
                              ]
                                  .map(
                                    (board) => DropdownMenuItem(
                                      value: board,
                                      child: Text(
                                        board,
                                        style: FormStyles.fieldText(context)
                                            .copyWith(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedBoard = value),
                              validator:
                                  (value) =>
                                      value == null ? "Select board" : null,
                              style: FormStyles.fieldText(context),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: FormStyles.muted(context))),
                            _spacing,
                            _buildFieldLabel("Hall Ticket Number *"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _hallTicketController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              style: FormStyles.fieldText(context),
                              decoration: _buildInputDecoration(
                                hintText: "Enter 10-digit hall ticket number",
                                counterText: ""),
                              validator: (value) {
                                if (value == null || value.length != 10) {
                                  return "Must be exactly 10 digits";
                                } else if (!RegExp(
                                  r'^\d{10}$').hasMatch(value)) {
                                  return "Only digits allowed";
                                }
                                return null;
                              }),
                            _spacing,
                            _buildFieldLabel("Total Marks *"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _totalMarksController,
                              keyboardType: TextInputType.number,
                              style: FormStyles.fieldText(context),
                              decoration: _buildInputDecoration(
                                hintText: "Enter total marks"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter total marks";
                                }
                                final number = double.tryParse(value);
                                if (number == null || number < 0) {
                                  return "Enter a valid number";
                                }
                                if (_selectedBoard != null) {
                                  final maxMarks = _boardTotalMarks[_selectedBoard]!;
                                  if (number > maxMarks) {
                                    return "Total marks cannot exceed $maxMarks for $_selectedBoard";
                                  }
                                }
                                return null;
                              }),
                            _spacing,
                            _buildFieldLabel("Examination Held (Month-Year) *"),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectMonthYear,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _examDateController,
                                  style: FormStyles.fieldText(context),
                                  decoration: _buildInputDecoration(
                                    hintText: "Select month and year",
                                    suffixIcon: Icon(
                                      Icons.calendar_month,
                                      color: FormStyles.muted(context))),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? "Select month and year"
                                              : null))),
                            Text(
                              '* indicates required fields for verification',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: FormStyles.muted(context),
                              ),
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
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),
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
    String? counterText,
    Widget? suffixIcon,
  }) {
    return FormStyles.decoration(
      context,
      hintText: hintText,
      counterText: counterText,
      suffixIcon: suffixIcon,
    );
  }

}