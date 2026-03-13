import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// FIX: Changed from add() (random ID) to set(uid) so that
/// students/{uid} lookups from sign-in and dashboard work correctly.
/// Also restructured as a service class for consistency with other services.
class StudentService {
  static final _db = FirebaseFirestore.instance;

  /// Saves student details to students/{uid} using set() with merge.
  static Future<void> submitStudentDetails({
    required String uid,
    required Map<String, dynamic> studentData,
  }) async {
    await _db.collection('students').doc(uid).set(
      {
        ...studentData,
        'timestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Fetches the student document for [uid].
  static Future<Map<String, dynamic>?> getStudentData(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}

/// Helper used in form screens — shows success/error dialogs.
/// FIX: BuildContext is used synchronously in showDialog, no async gap risk.
Future<void> submitStudentForm({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required Function(bool) isLoadingSetter,
  required Map<String, dynamic> studentData,
  required VoidCallback onSuccess,
}) async {
  if (!formKey.currentState!.validate()) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  isLoadingSetter(true);

  try {
    await StudentService.submitStudentDetails(
      uid: user.uid,
      studentData: studentData,
    );

    if (!context.mounted) return; // FIX: mounted check before context use

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Success'),
        content: const Text('Details submitted successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    onSuccess();
  } catch (e) {
    if (!context.mounted) return; // FIX: mounted check before context use

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('❌ Error'),
        content: const Text('Failed to submit. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } finally {
    isLoadingSetter(false);
  }
}
