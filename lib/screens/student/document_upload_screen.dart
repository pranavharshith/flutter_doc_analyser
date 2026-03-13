import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          onTabChange: widget.onTabChange, // FIX: consistent with VoterIdForm
        );
        break;
      case "12th Marksheet":
        form = TwelfthMarksheetForm(
          toggleDarkMode: widget.toggleDarkMode,
          isDarkMode: widget.isDarkMode,
          onTabChange: widget.onTabChange, // FIX: consistent with VoterIdForm
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
          onTabChange: widget.onTabChange, // FIX: consistent with VoterIdForm
        );
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => form));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final docType = document['title']
                        .toString()
                        .toLowerCase()
                        .replaceAll(' ', '_');
                    final userId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .doc(userId)
                          .collection('documents')
                          .doc(docType)
                          .collection('uploads')
                          .orderBy('submittedAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String status = 'Not Submitted';
                        Color statusColor = Colors.grey;
                        IconData statusIcon = Icons.hourglass_empty;

                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          final data = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          status = data['status'] ?? 'Not Submitted';

                          switch (status) {
                            case 'Pending':
                              statusColor = const Color(0xFFF59E0B);
                              statusIcon = Icons.pending_actions;
                              break;
                            case 'Verified':
                              statusColor = const Color(0xFF10B981);
                              statusIcon = Icons.check_circle;
                              break;
                            case 'Rejected':
                              statusColor = const Color(0xFFEF4444);
                              statusIcon = Icons.cancel;
                              break;
                          }
                        }

                        return GestureDetector(
                          onTap: () => navigateToForm(document['title']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? const Color(0xFF2A3A5A)
                                  : const Color(0xFFFFFFFF).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: status == 'Not Submitted'
                                    ? Colors.transparent
                                    : statusColor.withOpacity(0.5),
                                width: 1.5,
                              ),
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
                                color: widget.isDarkMode
                                    ? const Color(0xFFB0C4DE)
                                    : const Color(0xFF415A77),
                              ),
                              title: Text(
                                document['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDarkMode
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF1B263B),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}