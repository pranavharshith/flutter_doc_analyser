import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/screens/student/reupload_screen.dart';
import '/ui/ui.dart';
import '/utils/theme.dart';
import '/utils/app_snackbar.dart';

class NotificationsScreen extends StatefulWidget {
  /// When true, used as a dashboard tab (no outer scaffold chrome).
  final bool embedded;

  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _pendingDeleteIds = <String>{};

  /// Soft-delete with Undo snackbar.
  Future<void> _moveToTrash(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic remove from list
    setState(() => _pendingDeleteIds.add(notificationId));

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .set({
        ...notificationData,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .delete();

      if (!mounted) return;
      setState(() => _pendingDeleteIds.remove(notificationId));

      AppSnackBar.show(
        context,
        message: 'Notification moved to trash',
        actionLabel: 'Undo',
        duration: const Duration(seconds: 5),
        onAction: () => _restoreFromTrash(notificationId, notificationData),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _pendingDeleteIds.remove(notificationId));
        AppSnackBar.error(context, 'Could not move to trash. Please try again.');
      }
    }
  }

  Future<void> _restoreFromTrash(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final restored = Map<String, dynamic>.from(notificationData)
        ..remove('deletedAt');

      // Restore with original id when possible
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .set(restored);

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .delete();

      if (mounted) {
        AppSnackBar.success(context, 'Notification restored');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not undo. Please try again.');
      }
    }
  }

  Future<void> _markAllRead(User user) async {
    try {
      final unread = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (unread.docs.isEmpty) {
        if (mounted) {
          AppSnackBar.show(context, message: 'No unread notifications');
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        AppSnackBar.success(context, 'Marked all as read');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not mark all as read. Please try again.');
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final body = user == null
        ? const AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Not signed in',
            message: 'Sign in to see your notifications.',
          )
        : _buildList(user);

    if (widget.embedded) {
      return AppGradientBody(child: body);
    }
    return AppScaffold(title: 'Notifications', body: body);
  }

  Widget _buildList(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading(message: 'Loading notifications…');
        }
        if (snapshot.hasError) {
          return AppEmptyState.error(
            message: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications',
            message: 'Updates about your documents will show up here.',
          );
        }

        final notifications = snapshot.data!.docs
            .where((d) => !_pendingDeleteIds.contains(d.id))
            .toList();

        if (notifications.isEmpty) {
          return const AppEmptyState(
            icon: Icons.notifications_none,
            title: 'No notifications',
          );
        }

        final unreadCount = notifications.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['isRead'] ?? false) == false;
        }).length;

        return Column(
          children: [
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text(
                      '$unreadCount unread',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _markAllRead(user),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(user.uid)
                      .collection('userNotifications')
                      .orderBy('timestamp', descending: true)
                      .limit(100)
                      .get();
                },
                color: AppTheme.primaryMid,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        notifications[index].data() as Map<String, dynamic>;
                    final notificationId = notifications[index].id;
                    final isRead = notification['isRead'] ?? false;
                    final notificationType = notification['type'] ?? 'user';
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    return AppCard(
                      key: ValueKey(notificationId),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.zero,
                      color: !isRead
                          ? (isDark
                              ? AppTheme.primaryDark
                              : AppTheme.accentBlue.withValues(alpha: 0.18))
                          : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          notificationType == 'reupload'
                              ? Icons.upload
                              : Icons.notifications,
                          color: isRead
                              ? (isDark
                                  ? AppTheme.accentBlue
                                  : AppTheme.textMuted)
                              : (notificationType == 'reupload'
                                  ? AppTheme.errorRed
                                  : AppTheme.primaryMid),
                        ),
                        title: Text(
                          notification['message'] ?? 'No message',
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document: ${notification['documentType'] ?? 'Unknown'}',
                            ),
                            Text(
                              _formatTimestamp(
                                notification['timestamp'] as Timestamp?,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: 'Move to trash',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorRed,
                          ),
                          onPressed: () => _moveToTrash(
                            notificationId,
                            notification,
                          ),
                        ),
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(user.uid)
                              .collection('userNotifications')
                              .doc(notificationId)
                              .update({'isRead': true});

                          if (!context.mounted) return;
                          if (notificationType == 'reupload') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReuploadScreen(
                                  documentType:
                                      notification['documentType'] ??
                                          'Document',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
