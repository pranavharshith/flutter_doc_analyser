import 'package:flutter/material.dart';
import '/screens/student/upload_document_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shown when a student needs to re-upload a rejected document.
/// FIX: Now navigates directly to UploadDocumentScreen with the student's
/// actual expected values so re-uploading works in one tap.
class ReuploadScreen extends StatefulWidget {
  final String documentType;
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const ReuploadScreen({
    super.key,
    required this.documentType,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<ReuploadScreen> createState() => _ReuploadScreenState();
}

class _ReuploadScreenState extends State<ReuploadScreen> {
  Map<String, String>? _expectedValues;
  List<String> _essentialFields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      final String fullName =
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();

      Map<String, String> expected = {};
      List<String> essential = [];

      switch (widget.documentType) {
        case 'Aadhar Card':
          expected = {
            'name': fullName,
            'aadharNumber': data['aadharNumber'] ?? '',
            'dob': data['dob'] ?? '',
          };
          essential = ['aadharNumber'];
          break;
        case 'Voter ID':
          expected = {
            'name': fullName,
            'voterId': data['voterId'] ?? '',
            'dob': data['dob'] ?? '',
          };
          essential = ['voterId'];
          break;
        case '10th Marksheet':
          expected = {
            'name': fullName,
            'schoolName': data['schoolName'] ?? '',
            'board': data['board10'] ?? '',
            'percentage': data['percentage10'] ?? '',
          };
          essential = ['percentage'];
          break;
        case '12th Marksheet':
          expected = {
            'name': fullName,
            'board': data['board12'] ?? '',
            'percentage': data['percentage12'] ?? '',
          };
          essential = ['percentage'];
          break;
        default:
          expected = {'name': fullName};
      }

      setState(() {
        _expectedValues = expected;
        _essentialFields = essential;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Re-upload: ${widget.documentType}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: widget.isDarkMode
                      ? const Color(0xFFB0C4DE)
                      : const Color(0xFF415A77),
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 72,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your ${widget.documentType} was rejected.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1B263B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please upload a clearer copy of your document.',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _expectedValues == null
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UploadDocumentScreen(
                                      title: widget.documentType,
                                      toggleDarkMode: widget.toggleDarkMode,
                                      isDarkMode: widget.isDarkMode,
                                      expectedValues: _expectedValues!,
                                      essentialFields: _essentialFields,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Re-upload Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF415A77),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Go Back',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? const Color(0xFFB0C4DE)
                                : const Color(0xFF415A77),
                          ),
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
