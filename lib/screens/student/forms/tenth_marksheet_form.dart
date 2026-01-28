import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/student/upload_document_screen.dart';

class TenthMarksheetForm extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const TenthMarksheetForm({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _TenthMarksheetFormState createState() => _TenthMarksheetFormState();
}

class _TenthMarksheetFormState extends State<TenthMarksheetForm> {
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
    'hallTicketNumber',
    'totalMarks',
    'examDate',
  ];

  // Mapping of boards to their total marks for 10th
  final Map<String, int> _boardTotalMarks = {
    'CBSE': 500,
    'SSC': 600,
    'ICSE': 600,
    'AISSE': 500,
    'SSLC': 625,
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select Examination Month & Year',
      fieldLabelText: 'Month/Year',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      final formatted = DateFormat('MMMM yyyy').format(picked);
      _examDateController.text = formatted;
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
        'hallTicket':
            _hallTicketController.text
                .trim(), // Renamed to match UploadDocumentScreen
        'totalMarks': _totalMarksController.text.trim(),
        'examDate': _examDateController.text.trim(),
      };

      // Navigate to UploadDocumentScreen with essential fields
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => UploadDocumentScreen(
                title: "10th Marksheet",
                toggleDarkMode: widget.toggleDarkMode,
                isDarkMode: widget.isDarkMode,
                expectedValues: expectedValues,
                essentialFields: _essentialFields, // Pass essential fields
              ),
        ),
      ).then((_) => setState(() => _isLoading = false));
    }
  }

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
                            _buildFieldLabel("School Name"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _schoolNameController,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter school name",
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter school name";
                                } else if (!RegExp(
                                  r'^[a-zA-Z\s]+$',
                                ).hasMatch(value)) {
                                  return "Only alphabets allowed";
                                }
                                return null;
                              },
                            ),
                            _spacing,
                            _buildFieldLabel("School Address"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _schoolAddressController,
                              maxLines: 4,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter address",
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Enter address";
                                }
                                return null;
                              },
                            ),
                            _spacing,
                            _buildFieldLabel("Medium"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(),
                              dropdownColor:
                                  widget.isDarkMode
                                      ? const Color(0xFF2A3A5A)
                                      : const Color(0xFFFFFFFF),
                              value: _selectedMedium,
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
                                      setState(() => _selectedMedium = value),
                              validator:
                                  (value) =>
                                      value == null ? "Select medium" : null,
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
                            _spacing,
                            _buildFieldLabel("Board"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(),
                              dropdownColor:
                                  widget.isDarkMode
                                      ? const Color(0xFF2A3A5A)
                                      : const Color(0xFFFFFFFF),
                              value: _selectedBoard,
                              items:
                                  ["CBSE", "SSC", "ICSE", "AISSE", "SSLC"]
                                      .map(
                                        (board) => DropdownMenuItem(
                                          value: board,
                                          child: Text(
                                            board,
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
                                      setState(() => _selectedBoard = value),
                              validator:
                                  (value) =>
                                      value == null ? "Select board" : null,
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
                            _spacing,
                            _buildFieldLabel("Hall Ticket Number *"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _hallTicketController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter 10-digit hall ticket number",
                                counterText: "",
                              ),
                              validator: (value) {
                                if (value == null || value.length != 10) {
                                  return "Must be exactly 10 digits";
                                } else if (!RegExp(
                                  r'^\d{10}$',
                                ).hasMatch(value)) {
                                  return "Only digits allowed";
                                }
                                return null;
                              },
                            ),
                            _spacing,
                            _buildFieldLabel("Total Marks *"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _totalMarksController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                              decoration: _buildInputDecoration(
                                hintText: "Enter total marks",
                              ),
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
                              },
                            ),
                            _spacing,
                            _buildFieldLabel("Examination Held (Month-Year) *"),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectMonthYear,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: _examDateController,
                                  style: TextStyle(
                                    color:
                                        widget.isDarkMode
                                            ? const Color(0xFFFFFFFF)
                                            : const Color(0xFF1B263B),
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: "Select month and year",
                                    suffixIcon: Icon(
                                      Icons.calendar_month,
                                      color:
                                          widget.isDarkMode
                                              ? const Color(0xFFB0C4DE)
                                              : const Color(0xFF1B263B),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? "Select month and year"
                                              : null,
                                ),
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
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFFFFFF),
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
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
                            const SizedBox(height: 16),
                            Text(
                              "* indicates required fields for verification",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color:
                                    widget.isDarkMode
                                        ? Colors.amber
                                        : Colors.deepOrange,
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
                '10TH DETAILS',
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color:
            widget.isDarkMode
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF1B263B),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    String? counterText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color:
            widget.isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF6B7280),
      ),
      counterText: counterText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor:
          widget.isDarkMode ? const Color(0xFF3B4A6B) : const Color(0xFFE6E9EF),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide:
            widget.isDarkMode
                ? const BorderSide(color: Color(0xFFB0C4DE), width: 1.0)
                : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide:
            widget.isDarkMode
                ? const BorderSide(color: Color(0xFFB0C4DE), width: 1.0)
                : BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}