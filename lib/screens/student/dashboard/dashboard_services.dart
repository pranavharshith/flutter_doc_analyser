import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  static final _db = FirebaseFirestore.instance;

  /// Fetches a summary of a student's document statuses.
  static Future<Map<String, String>> getDocumentStatuses(String uid) async {
    final Map<String, String> statuses = {};
    const docTypes = ['aadhar_card', 'voter_id', '10th_marksheet', '12th_marksheet'];
    for (final type in docTypes) {
      try {
        final docSnap = await _db
            .collection('students')
            .doc(uid)
            .collection('documents')
            .doc(type)
            .get();
        if (!docSnap.exists) {
          statuses[type] = 'Not Submitted';
          continue;
        }
        final uplSnap = await _db
            .collection('students')
            .doc(uid)
            .collection('documents')
            .doc(type)
            .collection('uploads')
            .orderBy('submittedAt', descending: true)
            .limit(1)
            .get();
        if (uplSnap.docs.isEmpty) {
          statuses[type] = 'Not Submitted';
        } else {
          statuses[type] = uplSnap.docs.first.data()['status'] ?? 'Pending';
        }
      } catch (_) {
        statuses[type] = 'Unknown';
      }
    }
    return statuses;
  }

  /// Returns the student's display name.
  static Future<String> getStudentName(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    if (!doc.exists) return 'Student';
    final data = doc.data()!;
    final first = data['firstName'] ?? '';
    final last = data['lastName'] ?? '';
    return '${first.trim()} ${last.trim()}'.trim().isEmpty ? 'Student' : '${first.trim()} ${last.trim()}';
  }
}
