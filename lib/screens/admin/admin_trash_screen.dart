import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTrashScreen extends StatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  _AdminTrashScreenState createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends State<AdminTrashScreen> {
  // Stream to fetch trashed notifications for admin
  Stream<QuerySnapshot> _getTrashedNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('trash')
        .orderBy('deletedAt', descending: true)
        .snapshots();
  }

  // Restore a notification
  Future<void> _restoreNotification(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    try {
      // Add back to adminNotifications
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .doc(notificationId)
          .set({...notificationData, 'isRead': false, 'deletedAt': null});

      // Remove from trash
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
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
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Trash",
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
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
                return const Center(child: Text('Error fetching trash'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "Trash is empty.",
                      style: TextStyle(color: Color(0xFF1B263B), fontSize: 18),
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
                      color: const Color(0xFFFFFFFF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "Trash is empty.",
                      style: TextStyle(color: Color(0xFF1B263B), fontSize: 18),
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
                    color: const Color(0xFFFFFFFF),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.grey),
                      title: Text(
                        notification['message'] ?? 'No message',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['documentType'] ?? '',
                            style: const TextStyle(color: Colors.grey),
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
