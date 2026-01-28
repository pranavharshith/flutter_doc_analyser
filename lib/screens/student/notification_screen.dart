import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Stream to fetch unread notifications count
  Stream<int> _getUnreadNotificationsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification moved to trash')),
      );
    } catch (e) {
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF415A77), Color(0xFF1B263B)],
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: _getUnreadNotificationsCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return Stack(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 24,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 10
                                        ? '10+'
                                        : unreadCount.toString(),
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
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(user.uid)
                      .collection('userNotifications')
                      .orderBy('timestamp', descending: true)
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

                    final notifications = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notifications[index].data() as Map<String, dynamic>;
                        final notificationId = notifications[index].id;
                        final isRead = notification['isRead'] ?? false;
                        final notificationType = notification['type'] ?? 'user';

                        return Card(
                          color: isDarkMode
                              ? const Color(0xFF2A3A5A)
                              : const Color(0xFFFFFFFF),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: isRead ? null : Colors.blueGrey[50],
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
                                color: isDarkMode ? Colors.white : Colors.black,
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _moveToTrash(
                                notificationId,
                                notification,
                              ),
                            ),
                            onTap: () async {
                              // Mark as read when tapped
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(user.uid)
                                  .collection('userNotifications')
                                  .doc(notificationId)
                                  .update({'isRead': true});

                              // Optionally, handle reupload navigation here
                              // For example, if the notification is a reupload type, you could navigate to the UploadDocumentScreen
                              // if (notificationType == 'reupload') {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) => UploadDocumentScreen(
                              //         title: notification['documentType'],
                              //         toggleDarkMode: () {},
                              //         isDarkMode: isDarkMode,
                              //         expectedValues: {}, // Pass relevant data
                              //         essentialFields: [], // Pass relevant fields
                              //       ),
                              //     ),
                              //   );
                              // }
                            },
                          ),
                        );
                      },
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
