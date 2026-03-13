import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_constants.dart';

/// Admin screen showing a searchable list of all students and their
/// document submission status.
class DocumentManagementScreen extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const DocumentManagementScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  String _searchQuery = '';

  static const List<String> _documentTypes = AppConstants.documentTypes;

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: Colors.white,
            ),
            onPressed: widget.toggleDarkMode,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(
                    color: _isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF6B7280),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF415A77),
                  ),
                  filled: true,
                  fillColor: _isDarkMode
                      ? const Color(0xFF2A3A5A)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filtered = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                            .toLowerCase();
                    final email = (data['email'] ?? '').toLowerCase();
                    return _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search,
                              size: 64,
                              color: _isDarkMode
                                  ? const Color(0xFFB0C4DE).withOpacity(0.4)
                                  : const Color(0xFF415A77).withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No students found',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1B263B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final data =
                          filtered[i].data() as Map<String, dynamic>;
                      final uid = filtered[i].id;
                      final firstName = data['firstName'] ?? '';
                      final lastName = data['lastName'] ?? '';
                      final email = data['email'] ?? '';

                      return Card(
                        color: _isDarkMode
                            ? const Color(0xFF2A3A5A)
                            : Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF415A77).withOpacity(0.2),
                            child: const Icon(Icons.person,
                                color: Color(0xFF415A77)),
                          ),
                          title: Text(
                            firstName.isEmpty && lastName.isEmpty
                                ? 'Unknown'
                                : '$firstName $lastName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1B263B),
                            ),
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              color: _isDarkMode
                                  ? const Color(0xFFB0C4DE)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          children: _documentTypes.map((docType) {
                            return _buildDocStatusRow(uid, docType);
                          }).toList(),
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
    );
  }

  Widget _buildDocStatusRow(String uid, String docType) {
    final docKey = docType.toLowerCase().replaceAll(' ', '_');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('documents')
          .doc(docKey)
          .collection('uploads')
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        String status = 'Not Submitted';
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final docData =
              snap.data!.docs.first.data() as Map<String, dynamic>;
          status = docData['status'] ?? 'Pending';
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(_docIcon(docType),
                  size: 18, color: const Color(0xFF415A77)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  docType,
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white70
                        : const Color(0xFF1B263B),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _docIcon(String docType) {
    switch (docType.toLowerCase()) {
      case 'aadhar card':
        return Icons.credit_card;
      case 'voter id':
        return Icons.how_to_vote;
      default:
        return Icons.school;
    }
  }
}
