import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';
import 'open_submission.dart';

/// Student roster with per-document status from parent docs (cheap reads).
class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _generation = 0;
  late Stream<QuerySnapshot> _studentsStream;

  @override
  void initState() {
    super.initState();
    _studentsStream = FirebaseFirestore.instance
        .collection('students')
        .limit(200)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _generation++;
      _studentsStream = FirebaseFirestore.instance
          .collection('students')
          .limit(200)
          .snapshots();
    });
    try {
      await _studentsStream.first.timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Documents',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppTheme.bgLight),
          onPressed: _refresh,
        ),
        const ThemeToggleButton(color: AppTheme.bgLight),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppCard(
              padding: EdgeInsets.zero,
              elevation: 0,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: FormStyles.decoration(
                  context,
                  hintText: 'Search students…',
                  prefixIcon: const Icon(Icons.search),
                ).copyWith(
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey('students_$_generation'),
              stream: _studentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const AppLoading(message: 'Loading students…');
                }
                if (snapshot.hasError) {
                  return AppEmptyState.error(
                    title: 'Could not load students',
                    message: '${snapshot.error}',
                    onAction: _refresh,
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final q = _searchQuery.toLowerCase();
                final filtered = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                          .toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return q.isEmpty || name.contains(q) || email.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppTheme.primaryMid,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 64),
                        AppEmptyState(
                          icon: Icons.person_search,
                          title: 'No students found',
                          message: q.isEmpty
                              ? 'Students appear after sign-up and profile setup.'
                              : 'Try another search. Pull to refresh.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppTheme.primaryMid,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final data =
                          filtered[i].data() as Map<String, dynamic>;
                      final uid = filtered[i].id;
                      final first = (data['firstName'] ?? '').toString();
                      final last = (data['lastName'] ?? '').toString();
                      final name = ('$first $last').trim().isEmpty
                          ? 'Student'
                          : ('$first $last').trim();
                      final email = (data['email'] ?? '').toString();

                      return AppCard(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryMid.withValues(alpha: 0.15),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryMid,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: email.isEmpty
                                ? null
                                : Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppTheme.accentBlue
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                            children: AppConstants.documentTypes
                                .map(
                                  (docType) => _DocStatusRow(
                                    uid: uid,
                                    documentType: docType,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One stream per expanded row only — parent status first (cheap).
class _DocStatusRow extends StatelessWidget {
  final String uid;
  final String documentType;

  const _DocStatusRow({
    required this.uid,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final key = AppConstants.documentTypeKey(documentType);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('documents')
          .doc(key)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final status = (data?['status'] as String?) ?? 'Not Submitted';
        final latestId = data?['latestUploadId'] as String?;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            documentType.toLowerCase().contains('aadhar')
                ? Icons.credit_card
                : documentType.toLowerCase().contains('voter')
                    ? Icons.how_to_vote
                    : Icons.school_outlined,
            color: AppTheme.primaryMid,
            size: 22,
          ),
          title: Text(documentType),
          trailing: StatusBadge(status: status, fontSize: 11),
          onTap: latestId == null || status == 'Not Submitted'
              ? null
              : () => openSubmissionByIds(
                    context,
                    userId: uid,
                    documentType: documentType,
                    uploadId: latestId,
                  ),
        );
      },
    );
  }
}
