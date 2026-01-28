// import 'package:cloud_firestore/cloud_firestore.dart';

// class StudentService {
//   static Future<void> submitStudentDetails(
//     Map<String, dynamic> studentData,
//   ) async {
//     try {
//       await FirebaseFirestore.instance.collection('students').add(studentData);
//     } catch (e) {
//       throw Exception('Error submitting student details');
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> submitStudentForm({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required Function(bool) isLoadingSetter,
  required Map<String, dynamic> studentData,
  required VoidCallback onSuccess,
}) async {
  if (!formKey.currentState!.validate()) return;

  isLoadingSetter(true);

  try {
    await FirebaseFirestore.instance.collection('students').add({
      ...studentData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('✅ Success'),
            content: Text('Details submitted successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    ).then((_) => onSuccess());
  } catch (e) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('❌ Error'),
            content: Text('Failed to submit. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  } finally {
    isLoadingSetter(false);
  }
}
