import 'package:flutter/material.dart';

class VerificationResultScreen extends StatelessWidget {
  final String documentType;
  final bool isVerified;
  final double overallSimilarity;
  final Map<String, dynamic> comparisonResults;
  final bool isDarkMode;

  const VerificationResultScreen({
    super.key,
    required this.documentType,
    required this.isVerified,
    required this.overallSimilarity,
    required this.comparisonResults,
    required this.isDarkMode,
  });

  Color get _statusColor =>
      isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result: $documentType'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
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
            colors: isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.pending_rounded,
                  color: _statusColor,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  isVerified ? 'Document Verified!' : 'Pending Admin Review',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall Match: ${overallSimilarity.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                if (comparisonResults.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Field Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF1B263B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...comparisonResults.entries.map((entry) {
                    final result = entry.value as Map<String, dynamic>;
                    final matched = result['matched'] ?? false;
                    return Card(
                      color: isDarkMode
                          ? const Color(0xFF2A3A5A)
                          : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          matched ? Icons.check_circle : Icons.cancel,
                          color: matched ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : const Color(0xFF1B263B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          matched
                              ? 'Matched: ${result['matchedText'] ?? result['originalValue']}'
                              : 'Not matched',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF415A77),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
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
