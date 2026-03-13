import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin report screen with live stats and per-document submission breakdown.
class ReportGenerationScreen extends StatelessWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const ReportGenerationScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  static const _documentTypes = [
    'Aadhar Card',
    'Voter ID',
    '10th Marksheet',
    '12th Marksheet',
  ];

  Future<Map<String, Map<String, int>>> _fetchStats() async {
    final students =
        await FirebaseFirestore.instance.collection('students').get();

    // counts[docType][status] = count
    final Map<String, Map<String, int>> counts = {
      for (final dt in _documentTypes)
        dt: {'Pending': 0, 'Verified': 0, 'Rejected': 0, 'Not Submitted': 0}
    };

    final futures = <Future<void>>[];

    for (final studentDoc in students.docs) {
      for (final docType in _documentTypes) {
        final docKey = docType.toLowerCase().replaceAll(' ', '_');
        futures.add(Future(() async {
          final uploads = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentDoc.id)
              .collection('documents')
              .doc(docKey)
              .collection('uploads')
              .orderBy('submittedAt', descending: true)
              .limit(1)
              .get();
          if (uploads.docs.isNotEmpty) {
            final status = uploads.docs.first['status'] ?? 'Pending';
            counts[docType]![status] =
                (counts[docType]![status] ?? 0) + 1;
          } else {
            counts[docType]!['Not Submitted'] =
                (counts[docType]!['Not Submitted'] ?? 0) + 1;
          }
        }));
      }
    }
    await Future.wait(futures);
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
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
              isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
              color: Colors.white,
            ),
            onPressed: toggleDarkMode,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: FutureBuilder<Map<String, Map<String, int>>>(
          future: _fetchStats(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final stats = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Submission Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : const Color(0xFF1B263B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live counts per document type',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                ...stats.entries.map((entry) {
                  final docType = entry.key;
                  final c = entry.value;
                  final total = (c['Pending'] ?? 0) +
                      (c['Verified'] ?? 0) +
                      (c['Rejected'] ?? 0) +
                      (c['Not Submitted'] ?? 0);
                  final verified = c['Verified'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2A3A5A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_docIcon(docType),
                                color: const Color(0xFF415A77)),
                            const SizedBox(width: 10),
                            Text(
                              docType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1B263B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : verified / total,
                            minHeight: 8,
                            backgroundColor: isDarkMode
                                ? const Color(0xFF415A77).withOpacity(0.2)
                                : const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statChip('Verified', c['Verified'] ?? 0,
                                const Color(0xFF10B981)),
                            _statChip('Pending', c['Pending'] ?? 0,
                                const Color(0xFFF59E0B)),
                            _statChip('Rejected', c['Rejected'] ?? 0,
                                const Color(0xFFEF4444)),
                            _statChip('Not Submitted',
                                c['Not Submitted'] ?? 0,
                                const Color(0xFF6B7280)),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
