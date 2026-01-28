import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

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
                          "Frequently Asked Questions",
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1B263B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFAQItem(
                          context,
                          question: "How do I upload my documents?",
                          answer:
                              "To upload your documents, go to the 'Documents' section, select the document you want to upload, and follow the instructions on the screen. Make sure the document is clear and readable.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildFAQItem(
                          context,
                          question:
                              "What should I do if my Aadhaar number is not recognized?",
                          answer:
                              "If your Aadhaar number is not recognized, please ensure that it is entered correctly. If the issue persists, contact support through the 'Help' section.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildFAQItem(
                          context,
                          question: "How can I change my profile details?",
                          answer:
                              "Currently, profile details cannot be changed through the app. Please contact your institution's admin for any updates to your profile.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildFAQItem(
                          context,
                          question:
                              "What should I do if I face issues uploading documents?",
                          answer:
                              "If you're facing issues uploading documents, make sure you're connected to a stable internet connection. If the issue persists, try restarting the app or contact support for assistance.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildFAQItem(
                          context,
                          question: "How can I contact support?",
                          answer:
                              "You can contact support by navigating to the 'Help' section from the side menu. If you're still unable to resolve your issue, please reach out to your institution's support team.",
                          isDarkMode: isDarkMode,
                        ),
                        _buildFAQItem(
                          context,
                          question:
                              "What documents are required for verification?",
                          answer:
                              "The required documents for verification are your Aadhaar card, 10th and 12th marksheets, and Voter ID (if available). Please ensure these documents are uploaded in the specified order.",
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
                'FAQ',
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

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          question,
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
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
