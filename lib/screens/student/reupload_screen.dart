import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/student/upload_document_screen.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/theme.dart';
import '/utils/name_utils.dart';

/// Shown when a student needs to re-upload a rejected document.
class ReuploadScreen extends StatefulWidget {
  final String documentType;

  const ReuploadScreen({
    super.key,
    required this.documentType,
  });

  @override
  State<ReuploadScreen> createState() => _ReuploadScreenState();
}

class _ReuploadScreenState extends State<ReuploadScreen> {
  Map<String, String>? _expectedValues;
  List<String> _essentialFields = [];
  bool _isLoading = true;

  /// UX-01: normalize messy notification strings → canonical title + key.
  String get _normalizedTitle =>
      AppConstants.normalizeDocumentType(widget.documentType);

  String get _docTypeKey => AppConstants.documentTypeKey(_normalizedTitle);

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// Merge non-empty string fields from a map into [target].
  void _mergeFields(Map<String, String> target, Map<String, dynamic>? source) {
    if (source == null) return;
    source.forEach((key, value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      // Prefer existing non-empty values (newer uploads merged first).
      if ((target[key] ?? '').isEmpty) {
        target[key] = text;
      }
    });
  }

  Future<Map<String, dynamic>> _loadLatestUploadFields(String uid) async {
    final uploadsRef = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('documents')
        .doc(_docTypeKey)
        .collection('uploads');

    QuerySnapshot snap;
    try {
      snap = await uploadsRef
          .orderBy('submittedAt', descending: true)
          .limit(5)
          .get();
    } catch (_) {
      try {
        snap = await uploadsRef
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();
      } catch (_) {
        snap = await uploadsRef.limit(5).get();
      }
    }

    final merged = <String, String>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _mergeFields(merged, data);
      final verified = data['verifiedFields'];
      if (verified is Map) {
        _mergeFields(
          merged,
          verified.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    }
    return merged;
  }

  Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final studentSnap = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      final studentData = studentSnap.data() ?? <String, dynamic>{};
      final fullName = NameUtils.displayNameFromMap(
        studentData,
        fallback: '',
      );

      final uploadFields = await _loadLatestUploadFields(user.uid);

      String pick(String key, [String fallback = '']) {
        final fromUpload = uploadFields[key]?.toString().trim() ?? '';
        if (fromUpload.isNotEmpty) return fromUpload;
        final fromStudent = studentData[key]?.toString().trim() ?? '';
        if (fromStudent.isNotEmpty) return fromStudent;
        return fallback;
      }

      Map<String, String> expected;
      List<String> essential;

      switch (_normalizedTitle) {
        case 'Aadhar Card':
          expected = {
            'name': pick('name', fullName),
            'aadharNumber': pick('aadharNumber'),
            'dob': pick('dob'),
            'gender': pick('gender'),
            'address': pick('address'),
            'state': pick('state'),
          };
          essential = ['aadharNumber', 'name', 'dob', 'gender'];
          break;
        case 'Voter ID':
          expected = {
            'name': pick('name', fullName),
            'voterId': pick('voterId'),
            'dob': pick('dob'),
            'gender': pick('gender'),
            'fatherName': pick('fatherName'),
          };
          essential = ['voterId', 'name'];
          break;
        case '10th Marksheet':
          expected = {
            'name': pick('name', fullName),
            'schoolName': pick('schoolName'),
            'address': pick('address'),
            'medium': pick('medium'),
            'board': pick('board'),
            'hallTicket': pick('hallTicket'),
            'totalMarks': pick('totalMarks'),
            'percentage': pick('percentage'),
            'examDate': pick('examDate'),
          };
          essential = ['hallTicket', 'totalMarks', 'examDate'];
          break;
        case '12th Marksheet':
          expected = {
            'name': pick('name', fullName),
            'medium': pick('medium'),
            'board': pick('board'),
            'hallTicket': pick('hallTicket'),
            'totalMarks': pick('totalMarks'),
            'percentage': pick('percentage'),
            'examDate': pick('examDate'),
          };
          essential = ['hallTicket', 'totalMarks', 'examDate'];
          break;
        default:
          expected = {'name': pick('name', fullName)};
          essential = ['name'];
      }

      // Drop empty values so OCR matcher is not fed blank expectations.
      expected.removeWhere((_, v) => v.trim().isEmpty);

      if (!mounted) return;
      setState(() {
        _expectedValues = expected.isEmpty ? {'name': fullName} : expected;
        _essentialFields = essential;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Re-upload: $_normalizedTitle',
      body: _isLoading
          ? const AppLoading()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 72,
                        color: AppTheme.warningAmber,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your $_normalizedTitle was rejected.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please upload a clearer copy of your document.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppPrimaryButton(
                        label: 'Re-upload Document',
                        icon: Icons.upload_file,
                        onPressed: _expectedValues == null
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadDocumentScreen(
                                      title: _normalizedTitle,
                                      expectedValues: _expectedValues!,
                                      essentialFields: _essentialFields,
                                    ),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      AppSecondaryButton(
                        label: 'Go Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
