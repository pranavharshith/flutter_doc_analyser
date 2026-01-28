import 'package:flutter/material.dart';
import '/screens/student/forms/aadhar_card_form.dart';
import '/screens/student/forms/tenth_marksheet_form.dart';
import '/screens/student/forms/twelfth_marksheet_form.dart';
import '/screens/student/forms/voter_id_form.dart';

class DocumentUploadScreen extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final void Function(int) onTabChange; // Add the onTabChange callback

  const DocumentUploadScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.onTabChange, // Make it a required parameter
  });

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<Map<String, dynamic>> documents = [
    {"title": "Aadhar Card", "icon": Icons.credit_card},
    {"title": "10th Marksheet", "icon": Icons.school},
    {"title": "12th Marksheet", "icon": Icons.school_outlined},
    {"title": "Voter ID", "icon": Icons.how_to_vote},
  ];

  void navigateToForm(String documentTitle) {
    Widget form;

    switch (documentTitle) {
      case "10th Marksheet":
        form = TenthMarksheetForm(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
        );
        break;
      case "12th Marksheet":
        form = TwelfthMarksheetForm(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
        );
        break;
      case "Voter ID":
        form = VoterIdForm(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
          onTabChange: widget.onTabChange, // Pass the onTabChange callback
        );
        break;
      case "Aadhar Card":
      default:
        form = AadharCardForm(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
        );
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => form));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Explicitly disable any implied leading widget (like the drawer icon)
        title: const Text(
          "Upload Documents",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: documents.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return GestureDetector(
                        onTap: () => navigateToForm(document['title']),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                widget.isDarkMode
                                    ? const Color(0xFF2A3A5A)
                                    : const Color(0xFFFFFFFF).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Icon(
                              document['icon'],
                              size: 28,
                              color:
                                  widget.isDarkMode
                                      ? const Color(0xFFB0C4DE)
                                      : const Color(0xFF415A77),
                            ),
                            title: Text(
                              document['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}