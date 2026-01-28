import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF2A3A5A)
                              : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.3 : 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      children: [
                        Text(
                          "Step-by-Step Guides",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGuideTile(
                          context,
                          title: "How to navigate the Dashboard",
                          content:
                              "1. Home: View your document upload status.\n2. Notifications: See recent updates.\n3. Documents: Upload required documents.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildGuideTile(
                          context,
                          title: "How to upload documents",
                          content:
                              "1. Go to 'Documents' page.\n2. Tap on the document you want to upload.\n3. Follow the instructions to complete the upload.",
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Contact Support",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSupportTile(
                          context,
                          title: "Email Support",
                          subtitle: "support@example.com",
                          isDarkMode: isDarkMode,
                        ),
                        _buildSupportTile(
                          context,
                          title: "Phone Support",
                          subtitle: "+91 123 456 7890",
                          isDarkMode: isDarkMode,
                        ),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'HELP',
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

  Widget _buildGuideTile(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1B263B),
          ),
        ),
        trailing: Icon(
          Icons.expand_more,
          color: isDarkMode ? const Color(0xFFB0C4DE) : const Color(0xFF415A77),
          size: 20,
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          isDarkMode
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF1B263B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1B263B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color:
                isDarkMode ? const Color(0xFFB0C4DE) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
