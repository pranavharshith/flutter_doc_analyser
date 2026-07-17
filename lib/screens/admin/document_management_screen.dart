import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';
import 'open_submission.dart';

/// Student roster with per-document status from parent docs (cheap reads).
///
/// Paginated by document id (ADM-02) — no unordered hard 200 cap.
class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const int _pageSize = 40;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _students = [];
  DocumentSnapshot? _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (reset) {
      if (_loading) return;
      setState(() {
        _loading = true;
        _error = null;
        _students.clear();
        _cursor = null;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('students')
          .orderBy(FieldPath.documentId)
          .limit(_pageSize);

      final cursor = _cursor;
      if (!reset && cursor != null) {
        q = q.startAfterDocument(cursor);
      }

      final snap = await q.get();
      if (!mounted) return;

      setState(() {
        if (snap.docs.isNotEmpty) {
          _students.addAll(snap.docs);
          _cursor = snap.docs.last;
        }
        _hasMore = snap.docs.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = '$e';
      });
    }
  }

  Future<void> _refresh() => _loadStudents(reset: true);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filtered {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((d) {
      final data = d.data();
      final name =
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.accentBlue : AppTheme.textMuted;

    return AppScaffold(
      title: 'Documents',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppTheme.bgLight),
          onPressed: _loading ? null : _refresh,
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
                  hintText: 'Search loaded students…',
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
          Expanded(child: _buildBody(muted)),
        ],
      ),
    );
  }

  Widget _buildBody(Color muted) {
    if (_loading && _students.isEmpty) {
      return const AppLoading(message: 'Loading students…');
    }
    if (_error != null && _students.isEmpty) {
      return AppEmptyState.error(
        title: 'Could not load students',
        message: _error!,
        onAction: _refresh,
      );
    }

    final filtered = _filtered;
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
              message: _searchQuery.isEmpty
                  ? 'Students appear after sign-up and profile setup.'
                  : 'Not in loaded pages — clear search or load more, then try again.',
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
        itemCount: filtered.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == filtered.length) {
            return _buildFooter(muted);
          }
          final data = filtered[i].data();
          final uid = filtered[i].id;
          final first = (data['firstName'] ?? '').toString();
          final last = (data['lastName'] ?? '').toString();
          final name = ('$first $last').trim().isEmpty
              ? 'Student'
              : ('$first $last').trim();
          final email = (data['email'] ?? '').toString();

          return AppCard(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryMid.withValues(alpha: 0.15),
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
                        style: TextStyle(fontSize: 12, color: muted),
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
  }

  Widget _buildFooter(Color muted) {
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: _loadingMore
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton.icon(
                  onPressed: () => _loadStudents(reset: false),
                  icon: const Icon(Icons.expand_more),
                  label: Text('Load more (${_students.length} loaded)'),
                ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '${_students.length} student(s) loaded.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted),
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
            AppConstants.isAadhaarType(documentType)
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
