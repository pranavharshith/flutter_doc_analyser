import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatefulWidget {
  final VoidCallback onNavigateToUploads;
  
  const DashboardContent({super.key, required this.onNavigateToUploads});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _uploadedCount = 0;
  int _verifiedCount = 0;
  bool _isLoading = true;
  String _userName = '';

  final List<String> _docTypes = [
    'aadhar_card',
    '10th_marksheet',
    '12th_marksheet',
    'voter_id'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch User Name
      final userDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      if (userDoc.exists) {
        _userName = userDoc.data()?['name'] ?? '';
      }

      int uploaded = 0;
      int verified = 0;

      for (String docType in _docTypes) {
        final uploads = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .collection('documents')
            .doc(docType)
            .collection('uploads')
            .orderBy('submittedAt', descending: true)
            .limit(1)
            .get();

        if (uploads.docs.isNotEmpty) {
          uploaded++;
          final status = uploads.docs.first.data()['status'];
          if (status == 'Verified') {
            verified++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _uploadedCount = uploaded;
          _verifiedCount = verified;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? Colors.white : const Color(0xFF415A77)))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: const Color(0xFF415A77),
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? const Color(0xFFB0C4DE) : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    _userName.isNotEmpty ? _userName : "Student",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1B263B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF415A77), Color(0xFF1B263B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF415A77).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Progress",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: _uploadedCount / 4,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                  Center(
                                    child: Text(
                                      "$_uploadedCount/4",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uploadedCount == 4 
                                      ? "All documents uploaded!" 
                                      : "${4 - _uploadedCount} documents remaining.",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "$_verifiedCount verified so far.",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Quick Action
                  if (_uploadedCount < 4) ...[
                    ElevatedButton.icon(
                      onPressed: widget.onNavigateToUploads,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Go to Upload Documents"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isDarkMode ? const Color(0xFF2A3A5A) : const Color(0xFFFFFFFF),
                        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1B263B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Removed Recent Alerts section as per request to keep it only in notifications page
                ],
              ),
            ),
      ),
    );
  }
}
