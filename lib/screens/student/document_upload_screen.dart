import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/student/forms/aadhar_card_form.dart';
import '/screens/student/forms/tenth_marksheet_form.dart';
import '/screens/student/forms/twelfth_marksheet_form.dart';
import '/screens/student/forms/voter_id_form.dart';
import '/screens/student/reupload_screen.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/theme.dart';
import '/utils/app_snackbar.dart';

class DocumentUploadScreen extends StatefulWidget {
  final void Function(int) onTabChange;

  const DocumentUploadScreen({
    super.key,
    required this.onTabChange,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<Map<String, dynamic>> documents = [
    {'title': AppConstants.docAadhar, 'icon': Icons.credit_card},
    {'title': AppConstants.docTenth, 'icon': Icons.school},
    {'title': AppConstants.docTwelfth, 'icon': Icons.school_outlined},
    {'title': AppConstants.docVoterId, 'icon': Icons.how_to_vote},
  ];

  bool _isLockedStatus(String status, bool parentLocked) {
    if (status == 'Rejected') return false;
    if (status == 'Pending' || status == 'Verified') return true;
    return parentLocked;
  }

  String _subtitleFor(String status, bool locked) {
    switch (status) {
      case 'Verified':
        return 'Verified — no changes needed';
      case 'Pending':
        return 'Under review — wait for admin';
      case 'Rejected':
        return 'Rejected — tap to re-upload';
      case 'Not Submitted':
        return 'Tap to start';
      default:
        return locked ? 'Locked' : 'Tap to open';
    }
  }

  void _onDocumentTap(String title, String status, bool locked) {
    if (status == 'Verified') {
      AppSnackBar.show(
        context,
        message: 'This document is verified and locked.',
      );
      return;
    }
    if (status == 'Pending' || locked) {
      AppSnackBar.show(
        context,
        message: 'Upload is locked while under review.',
      );
      return;
    }
    if (status == 'Rejected') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReuploadScreen(documentType: title),
        ),
      );
      return;
    }
    _navigateToForm(title);
  }

  void _navigateToForm(String documentTitle) {
    final title = AppConstants.normalizeDocumentType(documentTitle);
    final Widget form;
    switch (title) {
      case AppConstants.docTenth:
        form = TenthMarksheetForm(onTabChange: widget.onTabChange);
        break;
      case AppConstants.docTwelfth:
        form = TwelfthMarksheetForm(onTabChange: widget.onTabChange);
        break;
      case AppConstants.docVoterId:
        form = VoterIdForm(onTabChange: widget.onTabChange);
        break;
      case AppConstants.docAadhar:
      default:
        form = AadharCardForm(onTabChange: widget.onTabChange);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => form));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.accentBlue : AppTheme.primaryMid;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppGradientBody(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final document = documents[index];
          final title = document['title'] as String;
          final docType = title.toLowerCase().replaceAll(' ', '_');
          final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(userId)
                .collection('documents')
                .doc(docType)
                .snapshots(),
            builder: (context, parentSnap) {
              final parentData = parentSnap.hasData && parentSnap.data!.exists
                  ? parentSnap.data!.data() as Map<String, dynamic>?
                  : null;
              final parentLocked = parentData?['locked'] == true;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .doc(userId)
                    .collection('documents')
                    .doc(docType)
                    .collection('uploads')
                    .orderBy('submittedAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  String status = 'Not Submitted';
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final data = snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    status = data['status'] ?? 'Not Submitted';
                  }

                  final locked = _isLockedStatus(status, parentLocked);
                  final statusColor = StatusBadge.colorFor(status);
                  final dimmed = locked && status != 'Rejected';

                  return Semantics(
                    button: true,
                    enabled: !dimmed || status == 'Rejected',
                    label: '$title, $status',
                    child: AppCard(
                      onTap: () => _onDocumentTap(title, status, locked),
                      border: Border.all(
                        color: status == 'Not Submitted'
                            ? Colors.transparent
                            : statusColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      child: Opacity(
                        opacity: dimmed ? 0.72 : 1,
                        child: Row(
                          children: [
                            Icon(
                              document['icon'] as IconData,
                              size: 28,
                              color: accent,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                                  ),
                                  Text(
                                    _subtitleFor(status, locked),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: mutedColor(context)),
                                  ),
                                ],
                              ),
                            ),
                            if (dimmed)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: mutedColor(context),
                                ),
                              ),
                            StatusBadge(status: status),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color mutedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.accentBlue
          : AppTheme.textMuted;
}
