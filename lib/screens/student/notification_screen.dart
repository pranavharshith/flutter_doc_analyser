import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting timestamps
import '/screens/student/reupload_screen.dart'; // FIX: reupload navigation

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _pendingDeleteIds = <String>{};

  // Move notification to trash
  Future<void> _moveToTrash(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Add to trash with deletedAt timestamp
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .set({
        ...notificationData,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Delete from userNotifications
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .delete();

      if (mounted) {
        setState(() {
          _pendingDeleteIds.remove(notificationId);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification moved to trash')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingDeleteIds.remove(notificationId);
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error moving to trash: $e')));
    }
  }

  // Format timestamp to a readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final dateTime = timestamp.toDate();
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
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
          child: const SafeArea(
            child: Center(
              child: Text('User not logged in', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(user.uid)
                      .collection('userNotifications')
                      .orderBy('timestamp', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications found.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }

                    final notifications = snapshot.data!.docs
                        .where((d) => !_pendingDeleteIds.contains(d.id))
                        .toList();

                    Future<void> onRefresh() async {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(user.uid)
                          .collection('userNotifications')
                          .orderBy('timestamp', descending: true)
                          .limit(100)
                          .get();
                    }

                    return RefreshIndicator(
                      onRefresh: onRefresh,
                      color: const Color(0xFF415A77),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification =
                              notifications[index].data() as Map<String, dynamic>;
                          final notificationId = notifications[index].id;
                          final isRead = notification['isRead'] ?? false;
                          final notificationType =
                              notification['type'] ?? 'user';

                          return Card(
                            key: ValueKey(notificationId),
                            color: isDarkMode
                                ? const Color(0xFF2A3A5A)
                                : const Color(0xFFFFFFFF),
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              tileColor: isRead
                                  ? null
                                  : (isDarkMode
                                      ? const Color(0xFF1B263B)
                                      : Colors.blueGrey[50]),
                              leading: Icon(
                                notificationType == 'reupload'
                                    ? Icons.upload
                                    : Icons.notifications,
                                color: isRead
                                    ? Colors.grey
                                    : (notificationType == 'reupload'
                                        ? Colors.red
                                        : Colors.blue),
                              ),
                              title: Text(
                                notification['message'] ?? 'No message',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Document: ${notification['documentType'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(
                                      notification['timestamp'] as Timestamp?,
                                    ),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  setState(() {
                                    _pendingDeleteIds.add(notificationId);
                                  });
                                  await _moveToTrash(
                                    notificationId,
                                    notification,
                                  );
                                },
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
                                      builder: (context) => ReuploadScreen(
                                        documentType:
                                            notification['documentType'] ??
                                                'Document',
                                        toggleDarkMode: () {},
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  );
                                }
                              },
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
        ),
      ),
    );
  }
}
