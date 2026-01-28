import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  // Stream to fetch trashed notifications for the student
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

  // Restore a notification
  Future<void> _restoreNotification(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Add back to userNotifications
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .set({...notificationData, 'isRead': false, 'deletedAt': null});

      // Remove from trash
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('trash')
          .doc(notificationId)
          .delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification restored')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring notification: $e')),
      );
    }
  }

  // Permanently delete a notification
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permanently deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trash",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
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
            colors:
                isDarkMode
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
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF2A3A5A)
                              : const Color(0xFFFFFFFF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.3 : 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Trash is empty.",
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF1B263B),
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              }

              final notifications = snapshot.data!.docs;

              // Filter out notifications older than 15 days and delete them
              for (var doc in notifications) {
                final data = doc.data() as Map<String, dynamic>;
                final deletedAt = data['deletedAt'] as Timestamp?;
                if (deletedAt != null) {
                  final deletedDate = deletedAt.toDate();
                  final daysSinceDeletion =
                      DateTime.now().difference(deletedDate).inDays;
                  if (daysSinceDeletion >= 15) {
                    _permanentlyDeleteNotification(doc.id);
                  }
                }
              }

              // Display remaining notifications
              final remainingNotifications =
                  notifications.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final deletedAt = data['deletedAt'] as Timestamp?;
                    if (deletedAt == null) return true;
                    final deletedDate = deletedAt.toDate();
                    return DateTime.now().difference(deletedDate).inDays < 15;
                  }).toList();

              if (remainingNotifications.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF2A3A5A)
                              : const Color(0xFFFFFFFF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.3 : 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Trash is empty.",
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF1B263B),
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: remainingNotifications.length,
                itemBuilder: (context, index) {
                  final notification =
                      remainingNotifications[index].data()
                          as Map<String, dynamic>;
                  final notificationId = remainingNotifications[index].id;
                  final deletedAt = notification['deletedAt'] as Timestamp?;
                  final daysLeft =
                      deletedAt != null
                          ? 15 -
                              DateTime.now()
                                  .difference(deletedAt.toDate())
                                  .inDays
                          : 15;

                  return Card(
                    color:
                        isDarkMode
                            ? const Color(0xFF2A3A5A)
                            : const Color(0xFFFFFFFF),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.grey),
                      title: Text(
                        notification['message'] ?? 'No message',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['documentType'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey,
                            ),
                          ),
                          Text(
                            'Will be deleted in $daysLeft day${daysLeft != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.restore,
                              color: Colors.green,
                            ),
                            onPressed:
                                () => _restoreNotification(
                                  notificationId,
                                  notification,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed:
                                () => _permanentlyDeleteNotification(
                                  notificationId,
                                ),
                          ),
                        ],
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
