import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/app_snackbar.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';

class AdminTrashScreen extends StatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  State<AdminTrashScreen> createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends State<AdminTrashScreen> {
  late Stream<QuerySnapshot> _trashStream;
  int _streamGeneration = 0;
  bool _isRefreshing = false;
  bool _purgedExpired = false;

  @override
  void initState() {
    super.initState();
    _trashStream = _createStream();
  }

  Stream<QuerySnapshot> _createStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('trash')
        .orderBy('deletedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _streamGeneration++;
      _purgedExpired = false;
      _trashStream = _createStream();
    });
    try {
      await _trashStream.first.timeout(const Duration(seconds: 15));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _restore(String id, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .doc(id)
          .set({...data, 'isRead': false, 'deletedAt': null});
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('trash')
          .doc(id)
          .delete();
      if (mounted) AppSnackBar.success(context, 'Notification restored');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not restore');
    }
  }

  Future<void> _deleteForever(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('trash')
          .doc(id)
          .delete();
      if (mounted) AppSnackBar.success(context, 'Permanently deleted');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Trash',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isRefreshing ? null : _refresh,
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
      ],
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey('trash_$_streamGeneration'),
        stream: _trashStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AppLoading(message: 'Loading trash…');
          }
          if (snapshot.hasError) {
            return AppEmptyState.error(
              title: 'Could not load trash',
              message: '${snapshot.error}',
              onAction: _refresh,
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (!_purgedExpired && docs.isNotEmpty) {
            _purgedExpired = true;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final deletedAt = data['deletedAt'] as Timestamp?;
              if (deletedAt != null &&
                  DateTime.now().difference(deletedAt.toDate()).inDays >= 15) {
                _deleteForever(doc.id);
              }
            }
          }

          final remaining = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final deletedAt = data['deletedAt'] as Timestamp?;
            if (deletedAt == null) return true;
            return DateTime.now().difference(deletedAt.toDate()).inDays < 15;
          }).toList();

          if (remaining.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppTheme.primaryMid,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 64),
                  AppEmptyState(
                    icon: Icons.delete_outline,
                    title: 'Trash is empty',
                    message: 'Deleted notifications stay here for 15 days.',
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
              padding: const EdgeInsets.all(16),
              itemCount: remaining.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final data = remaining[i].data() as Map<String, dynamic>;
                final id = remaining[i].id;
                final deletedAt = data['deletedAt'] as Timestamp?;
                final daysLeft = deletedAt != null
                    ? 15 -
                        DateTime.now().difference(deletedAt.toDate()).inDays
                    : 15;

                return AppCard(
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.errorRed.withValues(alpha: 0.12),
                      child: const Icon(Icons.delete_outline,
                          color: AppTheme.errorRed),
                    ),
                    title: Text(
                      data['message'] as String? ?? 'No message',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${data['documentType'] ?? ''} · $daysLeft day(s) left',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Restore',
                          icon: const Icon(Icons.restore,
                              color: AppTheme.successGreen),
                          onPressed: () => _restore(id, data),
                        ),
                        IconButton(
                          tooltip: 'Delete forever',
                          icon: const Icon(Icons.delete_forever,
                              color: AppTheme.errorRed),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text('Delete permanently?'),
                                content: const Text(
                                  'This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Delete',
                                      style:
                                          TextStyle(color: AppTheme.errorRed),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && mounted) {
                              await _deleteForever(id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
