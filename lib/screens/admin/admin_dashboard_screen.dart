import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/screens/auth/auth_page.dart';
import '/ui/dialogs.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';
import 'admin_notifications_screen.dart';
import 'admin_trash_screen.dart';
import 'document_management_screen.dart';
import 'report_generation_screen.dart';
import 'settings_screen.dart';
import 'submission_model.dart';
import 'submission_popup.dart';

export 'submission_model.dart';

/// Admin home: live submissions feed (capped collectionGroup) + student-style chrome.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _statusFilter = 'All';
  Submission? _selectedSubmission;
  bool _isRefreshing = false;
  Map<String, List<Submission>> _cachedSubmissions = {};

  late Stream<Map<String, List<Submission>>> _submissionsStream;
  late Stream<int> _unreadCountStream;
  int _streamGeneration = 0;

  static const _documentTypes = AppConstants.documentTypes;

  @override
  void initState() {
    super.initState();
    _submissionsStream = _createSubmissionsStream();
    _unreadCountStream = FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .where('isRead', isEqualTo: false)
        .limit(11)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _resolveUserId(Submission s) {
    final fromField = (s.details['userId'] as String?)?.trim() ?? '';
    if (fromField.isNotEmpty) return fromField;
    return s.userId;
  }

  Future<void> _updateStatus(
    Submission submission,
    String newStatus, {
    String? rejectionReason,
  }) async {
    final previousStatus = submission.status;
    final userId = _resolveUserId(submission);
    final docType = AppConstants.documentTypeKey(submission.documentType);
    final docId = submission.id;
    final cacheKey = userId.isNotEmpty ? userId : submission.name;

    if (userId.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, 'Cannot update: missing student userId');
      }
      return;
    }

    setState(() {
      final updated = submission.copyWith(
        status: newStatus,
        details: {
          ...submission.details,
          'status': newStatus,
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejectionReason': rejectionReason,
        },
      );
      _selectedSubmission = null;
      final list = _cachedSubmissions[cacheKey] ?? [];
      final index = list.indexWhere((s) => s.id == submission.id);
      if (index != -1) {
        list[index] = updated;
        _cachedSubmissions[cacheKey] = list;
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .collection('documents')
          .doc(docType)
          .collection('uploads')
          .doc(docId)
          .update({
        'status': newStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      });

      await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .collection('documents')
          .doc(docType)
          .set({
        'status': newStatus,
        'locked': newStatus == 'Verified',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (newStatus == 'Rejected') {
        final reason = (rejectionReason ?? '').trim();
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('userNotifications')
            .add({
          'message': reason.isEmpty
              ? 'Your ${submission.documentType} was rejected. Please re-upload.'
              : 'Your ${submission.documentType} was rejected: $reason',
          'documentType': submission.documentType,
          'userId': userId,
          'userName': submission.name,
          'uploadId': docId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': AppConstants.notifTypeReupload,
          'isRead': false,
        });
      } else if (newStatus == 'Verified') {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('userNotifications')
            .add({
          'message': 'Your ${submission.documentType} has been verified.',
          'documentType': submission.documentType,
          'userId': userId,
          'userName': submission.name,
          'uploadId': docId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': AppConstants.notifTypeUser,
          'isRead': false,
        });
        await _maybeNotifyAllDocsVerified(userId, submission.name);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final list = _cachedSubmissions[cacheKey] ?? [];
        final index = list.indexWhere((s) => s.id == submission.id);
        if (index != -1) {
          list[index] = submission.copyWith(status: previousStatus);
          _cachedSubmissions[cacheKey] = list;
        }
      });
      AppSnackBar.error(context, 'Error updating status: $e');
    }
  }

  Future<void> _maybeNotifyAllDocsVerified(
    String userId,
    String studentName,
  ) async {
    try {
      for (final key in AppConstants.documentTypeKeys) {
        final parent = await FirebaseFirestore.instance
            .collection('students')
            .doc(userId)
            .collection('documents')
            .doc(key)
            .get();
        if (parent.data()?['status'] != 'Verified') return;
      }
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .add({
        'message':
            'All documents are verified. You are fully cleared — thank you!',
        'documentType': 'All',
        'userId': userId,
        'userName': studentName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': AppConstants.notifTypeCompletion,
        'isRead': false,
      });
    } catch (_) {}
  }

  /// Cap at 200 newest uploads — keeps admin load bounded.
  Stream<Map<String, List<Submission>>> _createSubmissionsStream() {
    return FirebaseFirestore.instance
        .collectionGroup('uploads')
        .orderBy('submittedAt', descending: true)
        .limit(200)
        .snapshots()
        .map(_groupSnapshot);
  }

  Map<String, List<Submission>> _groupSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, Map<String, List<Submission>>> byUserType = {};

    for (final docSnapshot in snapshot.docs) {
      final docData = docSnapshot.data();
      final pathSegments = docSnapshot.reference.path.split('/');
      final pathUserId = pathSegments.length > 1 ? pathSegments[1] : '';
      final userId = (docData['userId'] as String?)?.trim().isNotEmpty == true
          ? (docData['userId'] as String).trim()
          : pathUserId;
      if (userId.isEmpty) continue;

      final docTypeKey = pathSegments.length > 3 ? pathSegments[3] : '';
      final documentType = AppConstants.normalizeDocumentType(
        (docData['documentType'] as String?) ??
            docTypeKey.replaceAll('_', ' '),
      );
      final userName =
          (docData['studentName'] as String?)?.trim().isNotEmpty == true
              ? docData['studentName'] as String
              : (docData['name'] as String?) ?? 'Student';

      final submission = Submission.fromMap({
        ...docData,
        'name': userName,
        'studentName': userName,
        'documentType': documentType,
        'userId': userId,
      }, docSnapshot.id);

      byUserType.putIfAbsent(userId, () => {});
      byUserType[userId]!.putIfAbsent(documentType, () => []);
      byUserType[userId]![documentType]!.add(submission);
    }

    final Map<String, List<Submission>> grouped = {};
    byUserType.forEach((userId, typeMap) {
      final list = <Submission>[];
      typeMap.forEach((_, uploads) {
        final latest = uploads.first;
        final history =
            uploads.length > 1 ? uploads.sublist(1) : <Submission>[];
        list.add(latest.copyWith(history: history));
      });
      grouped[userId] = list;
    });
    return grouped;
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _streamGeneration++;
      _submissionsStream = _createSubmissionsStream();
    });
    try {
      final grouped = await _submissionsStream.first.timeout(
        const Duration(seconds: 20),
      );
      if (!mounted) return;
      setState(() {
        _cachedSubmissions = grouped;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      AppSnackBar.error(context, 'Error refreshing data: $e');
    }
  }

  Future<void> _signOut() async {
    final ok = await AppDialogs.confirmLogout(context);
    if (!ok || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  void _open(Widget page) {
    Navigator.pop(context); // close drawer when open
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Map<String, List<Submission>> _applyFilters(
    Map<String, List<Submission>> source,
  ) {
    var result = source;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final filtered = <String, List<Submission>>{};
      result.forEach((userId, submissions) {
        final name = submissions.isNotEmpty ? submissions.first.name : userId;
        final email = submissions.isNotEmpty ? submissions.first.email : '';
        final hit = name.toLowerCase().contains(q) ||
            email.toLowerCase().contains(q) ||
            submissions.any((s) => s.documentType.toLowerCase().contains(q));
        if (hit) filtered[userId] = submissions;
      });
      result = filtered;
    }

    if (_statusFilter != 'All') {
      final filtered = <String, List<Submission>>{};
      result.forEach((userId, submissions) {
        final match =
            submissions.where((s) => s.status == _statusFilter).toList();
        if (match.isNotEmpty) filtered[userId] = match;
      });
      result = filtered;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppScaffold(
          scaffoldKey: _scaffoldKey,
          title: 'Admin',
          showBackButton: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.bgLight),
            tooltip: 'Menu',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          drawer: _buildDrawer(),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isRefreshing ? null : _refreshData,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.bgLight,
                      ),
                    )
                  : const Icon(Icons.refresh, color: AppTheme.bgLight),
            ),
            const ThemeToggleButton(color: AppTheme.bgLight),
            StreamBuilder<int>(
              stream: _unreadCountStream,
              builder: (context, snap) {
                final n = snap.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.bgLight,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (n > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            n > 9 ? '9+' : '$n',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryMid,
                  onRefresh: _refreshData,
                  child: StreamBuilder<Map<String, List<Submission>>>(
                    key: ValueKey('subs_$_streamGeneration'),
                    stream: _submissionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        _cachedSubmissions = snapshot.data!;
                      }
                      final raw = snapshot.hasData
                          ? snapshot.data!
                          : _cachedSubmissions;

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          raw.isEmpty) {
                        return const AppLoading(message: 'Loading submissions…');
                      }
                      if (snapshot.hasError && raw.isEmpty) {
                        return AppEmptyState.error(
                          title: 'Could not load submissions',
                          message: '${snapshot.error}',
                          onAction: _refreshData,
                        );
                      }

                      final filtered = _applyFilters(raw);
                      if (raw.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 48),
                            AppEmptyState(
                              icon: Icons.inbox_outlined,
                              title: 'No submissions yet',
                              message:
                                  'Student uploads appear here. Pull down to refresh.',
                            ),
                          ],
                        );
                      }

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _buildStats(filtered),
                          const SizedBox(height: 12),
                          _buildSearchField(),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            const AppEmptyState(
                              icon: Icons.filter_list_off,
                              title: 'No matches',
                              message: 'Try another search or status filter.',
                            )
                          else
                            ...filtered.entries.map(
                              (e) => _StudentSubmissionCard(
                                userId: e.key,
                                submissions: e.value,
                                documentTypes: _documentTypes,
                                onOpen: (s) =>
                                    setState(() => _selectedSubmission = s),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedSubmission != null)
          SubmissionPopup(
            submission: _selectedSubmission!,
            onClose: () => setState(() => _selectedSubmission = null),
            onUpdateStatus: (s, status, {rejectionReason}) => _updateStatus(
              s,
              status,
              rejectionReason: rejectionReason,
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Admin';
    return Drawer(
      child: AppGradientBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Home is this screen — no redundant "Dashboard" entry.
            // Notifications live in the app bar (with unread badge).
            _drawerTile(Icons.folder_outlined, 'Documents', () {
              _open(const DocumentManagementScreen());
            }),
            _drawerTile(Icons.bar_chart_outlined, 'Reports', () {
              _open(const ReportGenerationScreen());
            }),
            _drawerTile(Icons.delete_outline, 'Trash', () {
              _open(const AdminTrashScreen());
            }),
            _drawerTile(Icons.settings_outlined, 'Settings', () {
              _open(const AdminSettingsScreen());
            }),
            const Divider(),
            _drawerTile(Icons.logout, 'Sign out', _signOut, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? AppTheme.errorRed : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Pending', 'Verified', 'Rejected'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final selected = _statusFilter == f;
          return FilterChip(
            label: Text(f),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _statusFilter = f),
            selectedColor: AppTheme.primaryMid.withValues(alpha: 0.22),
            backgroundColor:
                isDark ? AppTheme.surfaceDarkAlt : AppTheme.bgLight,
            side: BorderSide(
              color: selected
                  ? AppTheme.primaryMid.withValues(alpha: 0.55)
                  : (isDark
                      ? AppTheme.accentBlue.withValues(alpha: 0.25)
                      : AppTheme.primaryMid.withValues(alpha: 0.12)),
            ),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? (isDark ? AppTheme.accentBlue : AppTheme.primaryMid)
                  : (isDark ? AppTheme.accentBlue : AppTheme.textMuted),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return AppCard(
      padding: EdgeInsets.zero,
      elevation: 0,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: FormStyles.decoration(
          context,
          hintText: 'Search name, email, or document…',
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
    );
  }

  Widget _buildStats(Map<String, List<Submission>> grouped) {
    var total = 0, pending = 0, verified = 0, rejected = 0;
    for (final list in grouped.values) {
      for (final s in list) {
        total++;
        switch (s.status) {
          case 'Pending':
            pending++;
            break;
          case 'Verified':
            verified++;
            break;
          case 'Rejected':
            rejected++;
            break;
        }
      }
    }

    Widget cell(String label, int n, Color c, IconData icon) {
      return Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          elevation: 0,
          child: Column(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(height: 6),
              Text(
                '$n',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.accentBlue
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        cell('Total', total, AppTheme.primaryMid, Icons.folder_outlined),
        const SizedBox(width: 8),
        cell('Pending', pending, AppTheme.warningAmber, Icons.pending_actions),
        const SizedBox(width: 8),
        cell('Verified', verified, AppTheme.successGreen, Icons.check_circle_outline),
        const SizedBox(width: 8),
        cell('Rejected', rejected, AppTheme.errorRed, Icons.cancel_outlined),
      ],
    );
  }
}

/// Student card with compact doc chips (icon + name + status colour).
class _StudentSubmissionCard extends StatelessWidget {
  final String userId;
  final List<Submission> submissions;
  final List<String> documentTypes;
  final ValueChanged<Submission> onOpen;

  const _StudentSubmissionCard({
    required this.userId,
    required this.submissions,
    required this.documentTypes,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.accentBlue : AppTheme.textMuted;
    final name = submissions.isNotEmpty ? submissions.first.name : 'Student';
    final email = submissions.isNotEmpty ? submissions.first.email : '';
    final uploaded =
        submissions.where((s) => s.status != 'Not Submitted').length;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryMid.withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryMid,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                  ],
                ),
              ),
              Text(
                '$uploaded/${documentTypes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Compact 2×2 chips — no heavy thumbnails on the list.
          LayoutBuilder(
            builder: (context, c) {
              const gap = 6.0;
              final w = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: documentTypes.map((docType) {
                  Submission? s;
                  for (final x in submissions) {
                    if (x.documentType == docType) {
                      s = x;
                      break;
                    }
                  }
                  return SizedBox(
                    width: w,
                    child: _DocChip(
                      title: docType,
                      submission: s,
                      onTap: s == null || s.status == 'Not Submitted'
                          ? null
                          : () => onOpen(s!),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact doc row: coloured icon + short name + status.
class _DocChip extends StatelessWidget {
  final String title;
  final Submission? submission;
  final VoidCallback? onTap;

  const _DocChip({
    required this.title,
    required this.submission,
    this.onTap,
  });

  static String _shortLabel(String title) {
    switch (title) {
      case AppConstants.docAadhar:
        return 'Aadhaar';
      case AppConstants.docVoterId:
        return 'Voter ID';
      case AppConstants.docTenth:
        return '10th';
      case AppConstants.docTwelfth:
        return '12th';
      default:
        return title
            .replaceAll(' Marksheet', '')
            .replaceAll(' Card', '');
    }
  }

  static IconData _iconFor(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'aadhar card':
        return Icons.credit_card;
      case 'voter id':
        return Icons.how_to_vote;
      case '10th marksheet':
        return Icons.menu_book_outlined;
      case '12th marksheet':
        return Icons.school_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = submission?.status ?? 'Not Submitted';
    final color = StatusBadge.colorFor(status);
    final short = _shortLabel(title);
    final canOpen = onTap != null;

    return Material(
      color: color.withValues(alpha: isDark ? 0.14 : 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(_iconFor(title), size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  short,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: canOpen
                        ? null
                        : (isDark ? AppTheme.accentBlue : AppTheme.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                status == 'Not Submitted'
                    ? '—'
                    : status == 'Verified'
                        ? 'Verified'
                        : status == 'Rejected'
                            ? 'Rejected'
                            : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
