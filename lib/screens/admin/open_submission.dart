import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import 'submission_model.dart';
import 'submission_popup.dart';

/// Load an upload and present [SubmissionPopup] (ADM-04 / ADM-06).
Future<void> openSubmissionByIds(
  BuildContext context, {
  required String userId,
  required String documentType,
  required String uploadId,
}) async {
  final docKey = AppConstants.documentTypeKey(documentType);
  try {
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .doc(userId)
        .collection('documents')
        .doc(docKey)
        .collection('uploads')
        .doc(uploadId)
        .get();

    if (!snap.exists) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Upload not found');
      }
      return;
    }

    final data = snap.data()!;
    final submission = Submission.fromMap({
      ...data,
      'userId': userId,
      'documentType':
          AppConstants.normalizeDocumentType(documentType),
    }, snap.id);

    // Prior history (optional)
    List<Submission> history = [];
    try {
      final hist = await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .collection('documents')
          .doc(docKey)
          .collection('uploads')
          .orderBy('submittedAt', descending: true)
          .limit(8)
          .get();
      history = hist.docs
          .where((d) => d.id != uploadId)
          .map((d) => Submission.fromMap({
                ...d.data(),
                'userId': userId,
              }, d.id))
          .toList();
    } catch (_) {}

    final withHistory = submission.copyWith(history: history);

    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SubmissionPopup(
              submission: withHistory,
              onClose: () => Navigator.pop(ctx),
              onUpdateStatus: (s, status, {rejectionReason}) async {
                await _applyStatus(
                  s,
                  status,
                  rejectionReason: rejectionReason,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          );
        },
      ),
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackBar.error(context, 'Could not open submission: $e');
    }
  }
}

Future<void> _applyStatus(
  Submission submission,
  String newStatus, {
  String? rejectionReason,
}) async {
  final userId = submission.userId;
  final docType = AppConstants.documentTypeKey(submission.documentType);
  final docId = submission.id;
  if (userId.isEmpty) return;

  await FirebaseFirestore.instance
      .collection('students')
      .doc(userId)
      .collection('documents')
      .doc(docType)
      .collection('uploads')
      .doc(docId)
      .update({
    'status': newStatus,
    'reviewedAt': FieldValue.serverTimestamp(),
    if (rejectionReason != null && rejectionReason.isNotEmpty)
      'rejectionReason': rejectionReason,
  });

  await FirebaseFirestore.instance
      .collection('students')
      .doc(userId)
      .collection('documents')
      .doc(docType)
      .set({
    'status': newStatus,
    'locked': newStatus == 'Verified',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  if (newStatus == 'Rejected') {
    final reason = (rejectionReason ?? '').trim();
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .add({
      'message': reason.isEmpty
          ? 'Your ${submission.documentType} was rejected. Please re-upload.'
          : 'Your ${submission.documentType} was rejected: $reason',
      'documentType': submission.documentType,
      'userId': userId,
      'userName': submission.name,
      'uploadId': docId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': AppConstants.notifTypeReupload,
      'isRead': false,
    });
  } else if (newStatus == 'Verified') {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .add({
      'message': 'Your ${submission.documentType} has been verified.',
      'documentType': submission.documentType,
      'userId': userId,
      'userName': submission.name,
      'uploadId': docId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': AppConstants.notifTypeUser,
      'isRead': false,
    });
  }
}
