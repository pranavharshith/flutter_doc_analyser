import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import '/utils/theme.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final Set<String> _scheduledForDeletion = {};

  Stream<QuerySnapshot> _getTrashedNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('trash')
        .orderBy('deletedAt', descending: true)
        .snapshots();
  }

  Future<void> _restoreNotification(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final restoredData = Map<String, dynamic>.from(notificationData);
    restoredData.remove('deletedAt');
    restoredData['isRead'] = false;

    try {
      // Restore with the same id (matches Notifications undo behavior).
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .set(restoredData);

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
        AppSnackBar.error(context, 'Could not restore notification');
      }
    }
  }

  Future<void> _permanentlyDeleteNotification(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .delete();

      if (mounted) {
        AppSnackBar.success(context, 'Notification permanently deleted');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not delete notification');
      }
    }
  }

  void _cleanExpiredItems(List<QueryDocumentSnapshot> docs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final doc in docs) {
        if (_scheduledForDeletion.contains(doc.id)) continue;
        final data = doc.data() as Map<String, dynamic>;
        final deletedAt = data['deletedAt'] as Timestamp?;
        if (deletedAt == null) continue;
        final daysSince =
            DateTime.now().difference(deletedAt.toDate()).inDays;
        if (daysSince >= AppConstants.trashRetentionDays) {
          _scheduledForDeletion.add(doc.id);
          _permanentlyDeleteNotification(doc.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Trash',
      body: StreamBuilder<QuerySnapshot>(
        stream: _getTrashedNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snapshot.hasError) {
            return AppEmptyState.error(message: '${snapshot.error}');
          }

          final notifications = snapshot.data?.docs ?? [];
          _cleanExpiredItems(notifications);

          final remaining = notifications.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final deletedAt = data['deletedAt'] as Timestamp?;
            if (deletedAt == null) return true;
            return DateTime.now().difference(deletedAt.toDate()).inDays <
                AppConstants.trashRetentionDays;
          }).toList();

          if (remaining.isEmpty) {
            return AppEmptyState(
              icon: Icons.delete_outline,
              title: 'Trash is empty',
              message:
                  'Deleted notifications appear here for '
                  '${AppConstants.trashRetentionDays} days before removal.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: remaining.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Items are permanently deleted after '
                    '${AppConstants.trashRetentionDays} days.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              final doc = remaining[index - 1];
              final notification = doc.data() as Map<String, dynamic>;
              final notificationId = doc.id;
              final deletedAt = notification['deletedAt'] as Timestamp?;
              final daysLeft = deletedAt != null
                  ? AppConstants.trashRetentionDays -
                      DateTime.now().difference(deletedAt.toDate()).inDays
                  : AppConstants.trashRetentionDays;

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete_forever, color: AppTheme.bgLight),
                      SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppTheme.bgLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete permanently?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) =>
                    _permanentlyDeleteNotification(notificationId),
                child: AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.accentBlue
                          : AppTheme.textMuted,
                    ),
                    title: Text(
                      notification['message'] ?? 'No message',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['documentType'] ?? ''),
                        Text(
                          'Deletes in $daysLeft day${daysLeft != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Restore',
                      icon: const Icon(Icons.restore),
                      onPressed: () => _restoreNotification(
                        notificationId,
                        notification,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
