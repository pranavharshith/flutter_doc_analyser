import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // List of required documents
    final requiredDocuments = [
      'Aadhar Card',
      '10th Marksheet',
      '12th Marksheet',
      'Voter ID',
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                "Upload Instructions",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF1B263B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please upload your documents in the specified order.",
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFFB0C4DE)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Upload your documents in the 'Document Upload Page', you can see an icon below 'Documents', click it, now you can see the forms to fill details of documents, fill the details and upload the documents in PNG/JPG format.",
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFFB0C4DE)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Required Documents",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF1B263B),
                ),
              ),
              ListTile(
                title: Text(
                  "• Aadhar Card",
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF1B263B),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  "• 10th Marksheet",
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF1B263B),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  "• 12th Marksheet",
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF1B263B),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  "• Voter ID (if available)",
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF1B263B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
