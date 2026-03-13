import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrashScreen extends StatefulWidget {
  final bool isDarkMode;
  const TrashScreen({super.key, required this.isDarkMode});

  @override
  _TrashScreenState createState() => _TrashScreenState();
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

  // FIX: Restore uses add() to get a NEW document ID, matching how
  // userNotifications were originally created, so the ID is always valid.
  Future<void> _restoreNotification(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Build the restored data without the trash-specific 'deletedAt' field
    final restoredData = Map<String, dynamic>.from(notificationData);
    restoredData.remove('deletedAt');
    restoredData['isRead'] = false;

    try {
      // FIX: Use add() — ensures a valid new document ID in userNotifications
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .add(restoredData);

      // Remove from trash
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification restored')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring notification: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permanently deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
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
        if (daysSince >= 15) {
          _scheduledForDeletion.add(doc.id);
          _permanentlyDeleteNotification(doc.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trash',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF415A77), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTrashedNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black)),
                );
              }

              final notifications = snapshot.data?.docs ?? [];

              // Clean up expired items
              _cleanExpiredItems(notifications);

              final remaining = notifications.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final deletedAt = data['deletedAt'] as Timestamp?;
                if (deletedAt == null) return true;
                return DateTime.now()
                        .difference(deletedAt.toDate())
                        .inDays <
                    15;
              }).toList();

              if (remaining.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 72,
                          color: isDarkMode
                              ? const Color(0xFFB0C4DE)
                              : const Color(0xFF415A77).withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Trash is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF1B263B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deleted notifications appear here\nfor 15 days before being removed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFB0C4DE)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: remaining.length,
                itemBuilder: (context, index) {
                  final doc = remaining[index];
                  final notification = doc.data() as Map<String, dynamic>;
                  final notificationId = doc.id;
                  final deletedAt =
                      notification['deletedAt'] as Timestamp?;
                  final daysLeft = deletedAt != null
                      ? 15 -
                          DateTime.now()
                              .difference(deletedAt.toDate())
                              .inDays
                      : 15;

                  // FIX: Wrap in Dismissible for swipe-to-delete UX
                  return Dismissible(
                    key: Key(notificationId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete_forever,
                              color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Permanently?'),
                          content: const Text(
                              'This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) =>
                        _permanentlyDeleteNotification(notificationId),
                    child: Card(
                      color: isDarkMode
                          ? const Color(0xFF2A3A5A)
                          : const Color(0xFFFFFFFF),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Icon(Icons.delete_outline,
                            color: Colors.grey.shade400),
                        title: Text(
                          notification['message'] ?? 'No message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['documentType'] ?? '',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              'Deletes in $daysLeft day${daysLeft != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          tooltip: 'Restore',
                          onPressed: () => _restoreNotification(
                              notificationId, notification),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
