import 'package:flutter/material.dart';
import '/ui/ui.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _items = [
    (
      q: 'How do I upload my documents?',
      a: 'Go to the Documents tab, select a document type, fill in the details, then upload a clear photo or scan of the document.',
    ),
    (
      q: 'What should I do if my Aadhaar number is not recognized?',
      a: 'Double-check the number format (XXXX XXXX XXXX). If OCR still fails, re-upload a sharper image or contact support from Help.',
    ),
    (
      q: 'How can I change my profile details?',
      a: 'Open the Profile tab (or drawer → Profile). You can update your name and phone number. Email is tied to your account and cannot be changed here.',
    ),
    (
      q: 'What should I do if I face issues uploading documents?',
      a: 'Check your internet connection, try a smaller image, or restart the app. If the problem continues, use Help to contact support.',
    ),
    (
      q: 'How can I contact support?',
      a: 'Open Help from the side menu for guides and contact options, or reach out to your institution’s support team.',
    ),
    (
      q: 'What documents are required for verification?',
      a: 'Aadhaar card, 10th marksheet, 12th marksheet, and Voter ID (if available). Upload clear, readable copies of each.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({String q, String a})> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.q.toLowerCase().contains(q) ||
              item.a.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final muted = FormStyles.muted(context);

    return AppScaffold(
      title: 'FAQ',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: FormStyles.decoration(
                context,
                hintText: 'Search questions…',
                suffixIcon: _query.isEmpty
                    ? Icon(Icons.search, color: muted)
                    : IconButton(
                        tooltip: 'Clear',
                        icon: Icon(Icons.clear, color: muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No matches',
                    message: 'Try a different keyword.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            child: ExpansionTile(
                              tilePadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              title: Text(
                                item.q,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.a,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
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
}
