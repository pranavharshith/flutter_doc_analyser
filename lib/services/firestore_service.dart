import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --------------- User ---------------

  static Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  // --------------- Student ---------------

  static Future<void> setStudentData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('students').doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getStudentData(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // --------------- Documents ---------------

  static Future<void> saveDocument(
    String uid,
    String docTypeKey,
    Map<String, dynamic> lockData,
    String uploadDocId,
    Map<String, dynamic> uploadData,
  ) async {
    final docRef = _db
        .collection('students')
        .doc(uid)
        .collection('documents')
        .doc(docTypeKey);

    await docRef.set(lockData);
    await docRef.collection('uploads').doc(uploadDocId).set(uploadData);
  }

  static Stream<QuerySnapshot> getDocumentUploads(
    String uid,
    String docTypeKey,
  ) {
    return _db
        .collection('students')
        .doc(uid)
        .collection('documents')
        .doc(docTypeKey)
        .collection('uploads')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  static Future<void> updateDocumentStatus(
    String uid,
    String docTypeKey,
    String uploadId,
    String status,
    bool locked,
  ) async {
    final docRef = _db
        .collection('students')
        .doc(uid)
        .collection('documents')
        .doc(docTypeKey);

    await docRef.update({'locked': locked});
    await docRef.collection('uploads').doc(uploadId).update({'status': status});
  }

  // --------------- Notifications ---------------

  static Future<void> addUserNotification(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .add(data);
  }

  static Future<void> addAdminNotification(
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .add(data);
  }

  static Stream<int> getUnreadUserNotificationsCount(String uid) {
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .limit(11) // Optimizing read count to match UI display (10+)
        .snapshots()
        .map((s) => s.docs.length);
  }

  static Stream<QuerySnapshot> getUserNotifications(String uid) {
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  static Future<void> markNotificationRead(
    String uid,
    String notificationId,
  ) async {
    await _db
        .collection('notifications')
        .doc(uid)
        .collection('userNotifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
