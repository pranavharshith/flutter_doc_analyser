import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/app_snackbar.dart';
import '/utils/theme.dart';
import '/widgets/theme_toggle_button.dart';
import 'open_submission.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final Set<String> _pendingDeleteIds = <String>{};
  late Stream<QuerySnapshot> _notificationsStream;
  int _streamGeneration = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _createStream();
  }

  Stream<QuerySnapshot> _createStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _streamGeneration++;
      _notificationsStream = _createStream();
    });
    try {
      await _notificationsStream.first.timeout(const Duration(seconds: 15));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _moveToTrash(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    setState(() => _pendingDeleteIds.add(notificationId));
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('trash')
          .doc(notificationId)
          .set({
        ...notificationData,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .doc(notificationId)
          .delete();
      if (mounted) {
        setState(() => _pendingDeleteIds.remove(notificationId));
        AppSnackBar.success(context, 'Moved to trash');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingDeleteIds.remove(notificationId));
        AppSnackBar.error(context, 'Could not move to trash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AppScaffold(
        title: 'Notifications',
        body: AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Not signed in',
          message: 'Sign in as admin to view notifications.',
        ),
      );
    }

    return AppScaffold(
      title: 'Notifications',
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
        key: ValueKey('admin_notifs_$_streamGeneration'),
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AppLoading(message: 'Loading…');
          }
          if (snapshot.hasError) {
            return AppEmptyState.error(
              title: 'Could not load',
              message: '${snapshot.error}',
              onAction: _refresh,
            );
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((d) => !_pendingDeleteIds.contains(d.id))
              .toList();

          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppTheme.primaryMid,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 64),
                  AppEmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    message:
                        'New student uploads will show up here. Pull to refresh.',
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
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                final isRead = data['isRead'] == true;
                final message = data['message'] as String? ?? 'No message';
                final docType = data['documentType'] as String? ?? '';
                final ts = data['timestamp'];
                String timeLabel = '';
                if (ts is Timestamp) {
                  final d = ts.toDate().toLocal();
                  timeLabel =
                      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                }

                return AppCard(
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  color: isRead
                      ? null
                      : AppTheme.primaryMid.withValues(alpha: 0.08),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryMid.withValues(alpha: 0.15),
                      child: Icon(
                        isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: AppTheme.primaryMid,
                      ),
                    ),
                    title: Text(
                      message,
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      [docType, if (timeLabel.isNotEmpty) timeLabel]
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorRed),
                      onPressed: () => _moveToTrash(id, data),
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc('admin')
                          .collection('adminNotifications')
                          .doc(id)
                          .update({'isRead': true});
                      final uid = data['userId'] as String? ?? '';
                      final uploadId = data['uploadId'] as String? ?? '';
                      final type = data['documentType'] as String? ?? '';
                      if (uid.isEmpty || uploadId.isEmpty || type.isEmpty) {
                        return;
                      }
                      if (!context.mounted) return;
                      await openSubmissionByIds(
                        context,
                        userId: uid,
                        documentType: type,
                        uploadId: uploadId,
                      );
                    },
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
