import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';

/// Lightweight admin reports — uses parent document status when present
/// (1 read per student doc type max) to avoid N×upload fan-out where possible.
class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  late Future<Map<String, Map<String, int>>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  /// Prefer parent `documents/{type}.status` (cheap). Fall back to latest upload
  /// only when parent status is missing.
  Future<Map<String, Map<String, int>>> _fetchStats() async {
    final students =
        await FirebaseFirestore.instance.collection('students').limit(300).get();

    final counts = {
      for (final dt in AppConstants.documentTypes)
        dt: {
          'Pending': 0,
          'Verified': 0,
          'Rejected': 0,
          'Not Submitted': 0,
        }
    };

    final futures = <Future<void>>[];
    for (final student in students.docs) {
      for (var i = 0; i < AppConstants.documentTypes.length; i++) {
        final title = AppConstants.documentTypes[i];
        final key = AppConstants.documentTypeKeys[i];
        futures.add(() async {
          final parent = await FirebaseFirestore.instance
              .collection('students')
              .doc(student.id)
              .collection('documents')
              .doc(key)
              .get();
          var status = parent.data()?['status'] as String?;
          if (status == null || status.isEmpty) {
            status = 'Not Submitted';
          }
          // Normalize unknown statuses
          if (!counts[title]!.containsKey(status)) {
            status = 'Pending';
          }
          counts[title]![status] = (counts[title]![status] ?? 0) + 1;
        }());
      }
    }
    await Future.wait(futures);
    return counts;
  }

  Future<void> _reload() async {
    final next = _fetchStats();
    setState(() => _statsFuture = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reports',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppTheme.bgLight),
          onPressed: _reload,
        ),
        const ThemeToggleButton(color: AppTheme.bgLight),
      ],
      body: FutureBuilder<Map<String, Map<String, int>>>(
        future: _statsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Building report…');
          }
          if (snap.hasError) {
            return AppEmptyState.error(
              title: 'Could not load reports',
              message: '${snap.error}',
              onAction: _reload,
            );
          }
          final stats = snap.data!;
          return RefreshIndicator(
            color: AppTheme.primaryMid,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Submission overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Per-document counts from student records (capped). Pull to refresh.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.accentBlue
                            : AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 16),
                ...stats.entries.map((e) {
                  final c = e.value;
                  final total = c.values.fold<int>(0, (a, b) => a + b);
                  final verified = c['Verified'] ?? 0;
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_icon(e.key), color: AppTheme.primaryMid),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '$verified / $total',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.accentBlue
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : verified / total,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.primaryMid.withValues(alpha: 0.15),
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusBadge(
                              status: 'Verified · ${c['Verified'] ?? 0}',
                              showIcon: true,
                              fontSize: 11,
                            ),
                            StatusBadge(
                              status: 'Pending · ${c['Pending'] ?? 0}',
                              showIcon: true,
                              fontSize: 11,
                            ),
                            StatusBadge(
                              status: 'Rejected · ${c['Rejected'] ?? 0}',
                              showIcon: true,
                              fontSize: 11,
                            ),
                            StatusBadge(
                              status:
                                  'Not Submitted · ${c['Not Submitted'] ?? 0}',
                              showIcon: false,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _icon(String docType) {
    switch (docType.toLowerCase()) {
      case 'aadhar card':
      case 'aadhaar card':
        return Icons.credit_card;
      case 'voter id':
        return Icons.how_to_vote;
      default:
        return Icons.school_outlined;
    }
  }
}
