import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  /// Sends a notification to a specific student.
  static Future<void> sendUserNotification({
    required String uid,
    required String message,
    required String documentType,
    required String userName,
    String type = 'user', // 'user', 'reupload'
  }) async {
    await _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .add({
      'message': message,
      'documentType': documentType,
      'userId': uid,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'isRead': false,
    });
  }

  /// Sends a notification to the admin collection.
  static Future<void> sendAdminNotification({
    required String message,
    required String documentType,
    required String userId,
    required String userName,
    Map<String, dynamic> extra = const {},
  }) async {
    await _db
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .add({
      'message': message,
      'documentType': documentType,
      'userId': userId,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'admin',
      'isRead': false,
      ...extra,
    });
  }

  /// Returns a stream of unread notification count for the current user.
  static Stream<int> unreadCountStream(String uid) {
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
