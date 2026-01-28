import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationsScreen extends StatefulWidget {
  final bool isDarkMode;

  const AdminNotificationsScreen({super.key, required this.isDarkMode});

  @override
  _AdminNotificationsScreenState createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  // Stream to fetch unread notifications count for admin
  Stream<int> _getUnreadNotificationsCount() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Move notification to trash
  Future<void> _moveToTrash(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    try {
      // Add to trash with deletedAt timestamp
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('trash')
          .doc(notificationId)
          .set({
            ...notificationData,
            'deletedAt': FieldValue.serverTimestamp(),
          });

      // Delete from adminNotifications
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                widget.isDarkMode
                    ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc('admin')
                          .collection('adminNotifications')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No notifications found.'),
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

                        return Card(
                          color:
                              widget.isDarkMode
                                  ? const Color(0xFF2A3A5A)
                                  : const Color(0xFFFFFFFF),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: isRead ? null : Colors.blueGrey[50],
                            leading: Icon(
                              Icons.notifications,
                              color: isRead ? Colors.grey : Colors.blue,
                            ),
                            title: Text(
                              notification['message'] ?? 'No message',
                              style: TextStyle(
                                fontWeight:
                                    isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              notification['documentType'] ?? '',
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.grey,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification['timestamp'] != null
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                        notification['timestamp']
                                            .millisecondsSinceEpoch,
                                      ).toLocal().toString().split('.')[0]
                                      : 'Unknown time',
                                  style: TextStyle(
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white70
                                            : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _moveToTrash(
                                        notificationId,
                                        notification,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc('admin')
                                  .collection('adminNotifications')
                                  .doc(notificationId)
                                  .update({'isRead': true});
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'ADMIN NOTIFICATIONS',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ],
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
                          unreadCount > 10 ? '10+' : unreadCount.toString(),
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
    );
  }
}
