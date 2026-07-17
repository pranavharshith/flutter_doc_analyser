import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/storage_service.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';
import '/utils/app_snackbar.dart';
import '/utils/document_validators.dart';
import '/utils/name_utils.dart';
import '/utils/theme.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String title;
  final Map<String, String> expectedValues;
  final List<String> essentialFields;

  const UploadDocumentScreen({
    super.key,
    required this.title,
    required this.expectedValues,
    this.essentialFields = const [],
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  String? selectedFileName;
  File? selectedImage;
  bool isProcessing = false;
  bool isUploading = false;
  bool isLocked = false;
  String extractedText = '';
  Map<String, dynamic> comparisonResults = {};
  bool isVerified = false;
  double overallSimilarity = 0.0;

  List<Map<String, dynamic>> _ocrBlocks = [];
  double _imageWidth = 0;
  double _imageHeight = 0;
  double? _sharpnessScore;
  ImageQuality? _imageQuality;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  Color get _muted => FormStyles.muted(context);
  Color get _onSurface => FormStyles.onSurface(context);

  @override
  void initState() {
    super.initState();
    _checkUploadLock();
  }

  Future<void> _checkUploadLock() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc(widget.title.toLowerCase().replaceAll(' ', '_'));

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data()!;
        setState(() {
          isLocked = data['locked'] ?? false;
        });
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not check upload status. Please try again.');
      }
    }
  }

  Future<void> _showSourceSheet() async {
    if (isLocked) {
      AppSnackBar.error(
        context,
        'Upload is locked. Wait for admin review or rejection.',
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                minVerticalPadding: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                minVerticalPadding: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Browse files (JPG/PNG)'),
                minVerticalPadding: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromFiles();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) return;
      await _handlePickedXFile(image);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Could not open the camera. Check permissions and try again.',
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) return;
      await _handlePickedXFile(image);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not open the gallery. Please try again.');
      }
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final name = file.name;
      final lower = name.toLowerCase();
      if (lower.endsWith('.pdf')) {
        AppSnackBar.error(
          context,
          'PDF is not supported for OCR. Please upload a JPG or PNG photo.',
        );
        return;
      }

      final path = file.path;
      if (path == null) {
        AppSnackBar.error(context, 'Unable to access that file. Please try again.');
        return;
      }
      final imageFile = File(path);
      setState(() {
        selectedFileName = name;
        selectedImage = imageFile;
      });
      await _processImage(imageFile);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not pick a file. Please try again.');
      }
    }
  }

  Future<void> _handlePickedXFile(XFile image) async {
    if (image.path.isEmpty) {
      AppSnackBar.error(context, 'Unable to access that image. Please try again.');
      return;
    }
    final file = File(image.path);
    setState(() {
      selectedImage = file;
      selectedFileName = image.name;
    });
    await _processImage(file);
  }

  Future<void> _processImage(File image) async {
    setState(() {
      isProcessing = true;
      extractedText = '';
      comparisonResults.clear();
      _ocrBlocks = [];
      isVerified = false;
      overallSimilarity = 0;
      _sharpnessScore = null;
      _imageQuality = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decoded = frame.image;
      final imgWidth = decoded.width.toDouble();
      final imgHeight = decoded.height.toDouble();

      // On-device sharpness check before OCR (Laplacian variance).
      final score = await DocumentValidators.calculateSharpness(decoded);
      final quality = DocumentValidators.qualityFromScore(score);
      decoded.dispose();

      if (!mounted) return;
      setState(() {
        _sharpnessScore = score;
        _imageQuality = quality;
      });

      if (quality == ImageQuality.blurry) {
        AppSnackBar.error(
          context,
          'Image looks blurry. Retake a clearer photo for better results.',
        );
      } else if (quality == ImageQuality.fair) {
        AppSnackBar.show(
          context,
          message: 'Image quality is only fair — some fields may be missed.',
        );
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      final blocks = <Map<String, dynamic>>[];
      if (imgWidth > 0 && imgHeight > 0) {
        for (final block in recognizedText.blocks) {
          final r = block.boundingBox;
          blocks.add({
            'text': block.text,
            'left': r.left / imgWidth,
            'top': r.top / imgHeight,
            'width': r.width / imgWidth,
            'height': r.height / imgHeight,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _imageWidth = imgWidth;
        _imageHeight = imgHeight;
        _ocrBlocks = blocks;
        extractedText = text.isNotEmpty ? text : 'No text found';
        comparisonResults = _compareTextWithExpected(text);

        int matchedEssential = 0;
        for (final field in widget.essentialFields) {
          if (comparisonResults[field]?['matched'] == true) {
            matchedEssential++;
          }
        }
        isVerified = widget.essentialFields.isNotEmpty &&
            matchedEssential == widget.essentialFields.length;

        if (comparisonResults.isNotEmpty) {
          var totalMatched = 0;
          for (final result in comparisonResults.values) {
            if (result is Map && result['matched'] == true) totalMatched++;
          }
          overallSimilarity = totalMatched / comparisonResults.length * 100;
        }
      });

      if (isVerified && mounted) {
        AppSnackBar.success(context, 'Verified successfully');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          extractedText = 'Could not read text from this image.';
        });
        AppSnackBar.error(
          context,
          'Processing failed. Try a clearer photo and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Map<String, dynamic> _compareTextWithExpected(String ocrText) {
    final Map<String, dynamic> result = {};
    final String ocrTextLower = ocrText.toLowerCase();

    widget.expectedValues.forEach((key, value) {
      // Skip the address field for all document types
      if (key == 'address') {
        return;
      }

      // Skip schoolName for 12th Marksheet
      if (widget.title == '12th Marksheet' && key == 'schoolName') {
        return;
      }

      String formattedValue = value.trim().toLowerCase();
      if (formattedValue.isEmpty) {
        return;
      }

      bool exactMatch = false;
      bool partialMatch = false;
      String matchedText = '';

      switch (widget.title) {
        case 'Aadhar Card':
          if (key == 'aadharNumber') {
            final aadharPattern = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b');
            if (aadharPattern.hasMatch(ocrText)) {
              final extractedAadhar =
                  aadharPattern
                      .firstMatch(ocrText)
                      ?.group(0)
                      ?.replaceAll(' ', '') ??
                  '';
              final expectedLast4 = formattedValue
                  .replaceAll(' ', '')
                  .substring(formattedValue.length - 4);
              exactMatch = extractedAadhar.endsWith(expectedLast4);
              matchedText =
                  exactMatch ? '**** **** ${extractedAadhar.substring(8)}' : '';
            }
          } else if (key == 'name' || key == 'state') {
            exactMatch = ocrTextLower.contains(formattedValue);
            if (!exactMatch) {
              List<String> parts = formattedValue.split(' ');
              int matchedParts = 0;
              for (String part in parts) {
                if (part.length > 2 && ocrTextLower.contains(part)) {
                  matchedParts++;
                  if (matchedText.isNotEmpty) matchedText += ', ';
                  matchedText += part;
                }
              }
              partialMatch =
                  parts.isNotEmpty && matchedParts / parts.length >= 0.7;
            } else {
              matchedText = formattedValue;
            }
          } else if (key == 'dob' || key == 'gender') {
            exactMatch = ocrTextLower.contains(formattedValue);
            matchedText = exactMatch ? formattedValue : '';
          }
          break;
        case 'Voter ID':
          if (key == 'voterId') {
            // Multi-state EPIC formats via DocumentValidators; fallback loose match.
            final extractedVoterId =
                DocumentValidators.extractVoterId(ocrText.toUpperCase()) ??
                    (() {
                      final m = RegExp(r'\b[A-Z0-9]{8,13}\b')
                          .firstMatch(ocrText.toUpperCase());
                      return m?.group(0);
                    })() ??
                    '';
            if (extractedVoterId.isNotEmpty) {
              exactMatch = extractedVoterId.toLowerCase() ==
                  formattedValue.toLowerCase();
              if (exactMatch && extractedVoterId.length >= 4) {
                matchedText =
                    '${extractedVoterId.substring(0, extractedVoterId.length - 4).replaceAll(RegExp(r'.'), '*')}${extractedVoterId.substring(extractedVoterId.length - 4)}';
              } else {
                matchedText = '';
              }
            }
          } else if (key == 'name' || key == 'fatherName' || key == 'gender') {
            exactMatch = ocrTextLower.contains(formattedValue);
            if (!exactMatch && key == 'name') {
              List<String> nameParts = formattedValue.split(' ');
              int matchedParts = 0;
              for (String part in nameParts) {
                if (part.length > 2 && ocrTextLower.contains(part)) {
                  matchedParts++;
                  if (matchedText.isNotEmpty) matchedText += ', ';
                  matchedText += part;
                }
              }
              partialMatch =
                  nameParts.isNotEmpty &&
                  matchedParts / nameParts.length >= 0.7;
            } else {
              matchedText = exactMatch ? formattedValue : '';
            }
          } else if (key == 'dob') {
            List<RegExp> datePatterns = [
              RegExp(r'\d{2}[/\-\.]\d{2}[/\-\.]\d{4}'),
              RegExp(r'\d{2}[/\-\.]\d{2}[/\-\.]\d{2}'),
              RegExp(
                r'\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}',
                caseSensitive: false),
            ];
            for (RegExp pattern in datePatterns) {
              Iterable<RegExpMatch> dateMatches = pattern.allMatches(ocrText);
              if (dateMatches.isNotEmpty) {
                matchedText = dateMatches.first.group(0)!;
                String simplifiedExpected = formattedValue.replaceAll(
                  RegExp(r'[/\-\.]'),
                  '');
                String simplifiedFound = matchedText.replaceAll(
                  RegExp(r'[/\-\.]'),
                  '');
                exactMatch = simplifiedExpected == simplifiedFound;
                partialMatch =
                    !exactMatch &&
                    simplifiedExpected.contains(
                      simplifiedFound.substring(0, 4));
                break;
              }
            }
          }
          break;
        case '10th Marksheet':
          if (key == 'schoolName' || key == 'medium' || key == 'board') {
            exactMatch = ocrTextLower.contains(formattedValue);
            if (!exactMatch) {
              List<String> parts = formattedValue.split(' ');
              int matchedParts = 0;
              for (String part in parts) {
                if (part.length > 3 && ocrTextLower.contains(part)) {
                  matchedParts++;
                  if (matchedText.isNotEmpty) matchedText += ', ';
                  matchedText += part;
                }
              }
              partialMatch =
                  parts.isNotEmpty && matchedParts / parts.length >= 0.5;
            } else {
              matchedText = formattedValue;
            }
          } else if (key == 'hallTicket' ||
              key == 'percentage' ||
              key == 'totalMarks' ||
              key == 'examDate') {
            exactMatch = ocrText.contains(formattedValue);
            matchedText = exactMatch ? formattedValue : '';
          }
          break;
        case '12th Marksheet':
          if (key == 'medium' || key == 'board') {
            exactMatch = ocrTextLower.contains(formattedValue);
            if (!exactMatch) {
              List<String> parts = formattedValue.split(' ');
              int matchedParts = 0;
              for (String part in parts) {
                if (part.length > 3 && ocrTextLower.contains(part)) {
                  matchedParts++;
                  if (matchedText.isNotEmpty) matchedText += ', ';
                  matchedText += part;
                }
              }
              partialMatch =
                  parts.isNotEmpty && matchedParts / parts.length >= 0.5;
            } else {
              matchedText = formattedValue;
            }
          } else if (key == 'hallTicket' ||
              key == 'percentage' ||
              key == 'totalMarks' ||
              key == 'examDate') {
            exactMatch = ocrText.contains(formattedValue);
            matchedText = exactMatch ? formattedValue : '';
          }
          break;
        default:
          exactMatch = ocrTextLower.contains(formattedValue);
          matchedText = exactMatch ? formattedValue : '';
      }

      bool isEssential = widget.essentialFields.contains(key);
      bool matched = exactMatch || (partialMatch && !isEssential);

      result[key] = {
        'matched': matched,
        'exactMatch': exactMatch,
        'partialMatch': partialMatch,
        'matchedText': matchedText,
        'isEssential': isEssential,
        'originalValue': value,
      };
    });

    return result;
  }


  Future<void> _uploadDocument() async {
    final imageFile = selectedImage;
    if (imageFile == null) {
      AppSnackBar.error(context, 'No image selected');
      return;
    }

    setState(() => isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppSnackBar.error(context, 'You are not signed in');
        setState(() => isUploading = false);
        return;
      }

      final safeFileName = (selectedFileName?.isNotEmpty == true)
          ? selectedFileName!.replaceAll(RegExp(r'\s+'), '_')
          : 'document';
      final documentId =
          '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      final verifiedFields = <String, String>{};
      comparisonResults.forEach((key, value) {
        if (value is Map &&
            value['matched'] == true &&
            value['originalValue'] != null) {
          verifiedFields[key] = value['originalValue'].toString();
        }
      });

      String? fileUrl;
      try {
        fileUrl = await StorageService.uploadDocument(
          uid: user.uid,
          documentType: widget.title,
          fileName: selectedFileName ?? 'document',
          file: imageFile,
        );
      } catch (_) {
        AppSnackBar.show(
          context,
          message: 'File upload incomplete — saving metadata without file URL.',
        );
      }

      // Profile display name/email (not the form "name on document").
      String studentName = 'Student';
      String studentEmail = user.email ?? '';
      try {
        final studentSnap = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        final data = studentSnap.data();
        studentName = NameUtils.displayNameFromMap(data, fallback: studentName);
        final emailFromProfile = (data?['email'] as String?)?.trim();
        if (emailFromProfile != null && emailFromProfile.isNotEmpty) {
          studentEmail = emailFromProfile;
        }
      } catch (_) {
        // Best-effort profile enrichment.
      }

      final documentName =
          (widget.expectedValues['name'] ?? '').trim().isNotEmpty
              ? widget.expectedValues['name']!.trim()
              : studentName;
      // SUB-07: always Pending for admin review; OCR match is a suggestion.
      const status = 'Pending';
      final autoVerified = isVerified;

      // Form values for Firestore — redact sensitive IDs (SEC-02).
      final persistedFields = Map<String, String>.from(widget.expectedValues);
      final rawAadhaar = persistedFields['aadharNumber'];
      if (rawAadhaar != null && rawAadhaar.isNotEmpty) {
        final digits = rawAadhaar.replaceAll(RegExp(r'\D'), '');
        final last4 =
            digits.length >= 4 ? digits.substring(digits.length - 4) : '';
        persistedFields['aadharNumber'] =
            last4.isEmpty ? '****' : '**** **** $last4';
        persistedFields['aadharLast4'] = last4;
      }

      // SUB-02: canonical upload schema for admin collectionGroup queries.
      final documentData = <String, dynamic>{
        'userId': user.uid,
        'documentType': widget.title,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'documentName': documentName,
        'name': studentName,
        'fileName': selectedFileName,
        'submittedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'verified': false,
        'autoVerified': autoVerified,
        'ocrMatch': autoVerified,
        'overallSimilarity': overallSimilarity,
        'verifiedFields': verifiedFields,
        'extractedText': extractedText,
        'status': status,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (_ocrBlocks.isNotEmpty) 'ocrBlocks': _ocrBlocks,
        if (_imageWidth > 0) 'imageWidth': _imageWidth,
        if (_imageHeight > 0) 'imageHeight': _imageHeight,
        if (_sharpnessScore != null) 'imageSharpness': _sharpnessScore,
        if (_imageQuality != null) 'imageQuality': _imageQuality!.name,
        ...persistedFields,
      };

      switch (widget.title) {
        case 'Aadhar Card':
          final num = widget.expectedValues['aadharNumber'] ?? '';
          final digits = num.replaceAll(RegExp(r'\D'), '');
          documentData['aadharLast4'] =
              digits.length >= 4 ? digits.substring(digits.length - 4) : '';
          if (digits.isNotEmpty) {
            documentData['aadharHash'] =
                DocumentValidators.hashDocumentNumber(num);
            documentData['documentNumberHash'] = documentData['aadharHash'];
          }
          break;
        case 'Voter ID':
          final voterId = verifiedFields['voterId'] ??
              widget.expectedValues['voterId'] ??
              '';
          documentData['voterId'] = voterId;
          if (voterId.isNotEmpty) {
            documentData['documentNumberHash'] =
                DocumentValidators.hashDocumentNumber(voterId);
          }
          documentData['fatherName'] = verifiedFields['fatherName'] ??
              widget.expectedValues['fatherName'] ??
              '';
          documentData['dob'] =
              verifiedFields['dob'] ?? widget.expectedValues['dob'] ?? '';
          documentData['gender'] =
              verifiedFields['gender'] ?? widget.expectedValues['gender'] ?? '';
          break;
        case '10th Marksheet':
          documentData['schoolName'] = verifiedFields['schoolName'] ??
              widget.expectedValues['schoolName'] ??
              '';
          documentData['medium'] =
              verifiedFields['medium'] ?? widget.expectedValues['medium'] ?? '';
          documentData['board'] =
              verifiedFields['board'] ?? widget.expectedValues['board'] ?? '';
          final hall10 = verifiedFields['hallTicket'] ??
              widget.expectedValues['hallTicket'] ??
              '';
          documentData['hallTicket'] = hall10;
          if (hall10.isNotEmpty) {
            documentData['documentNumberHash'] =
                DocumentValidators.hashDocumentNumber(hall10);
          }
          documentData['percentage'] = verifiedFields['percentage'] ??
              widget.expectedValues['percentage'] ??
              '';
          documentData['examDate'] = verifiedFields['examDate'] ??
              widget.expectedValues['examDate'] ??
              '';
          break;
        case '12th Marksheet':
          documentData['medium'] =
              verifiedFields['medium'] ?? widget.expectedValues['medium'] ?? '';
          documentData['board'] =
              verifiedFields['board'] ?? widget.expectedValues['board'] ?? '';
          final hall12 = verifiedFields['hallTicket'] ??
              widget.expectedValues['hallTicket'] ??
              '';
          documentData['hallTicket'] = hall12;
          if (hall12.isNotEmpty) {
            documentData['documentNumberHash'] =
                DocumentValidators.hashDocumentNumber(hall12);
          }
          documentData['percentage'] = verifiedFields['percentage'] ??
              widget.expectedValues['percentage'] ??
              '';
          documentData['examDate'] = verifiedFields['examDate'] ??
              widget.expectedValues['examDate'] ??
              '';
          break;
      }

      final docKey = widget.title.toLowerCase().replaceAll(' ', '_');

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc(docKey)
          .set({
        'name': studentName,
        'documentName': documentName,
        'status': status,
        'locked': true, // under review until admin rejects
        'updatedAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'latestUploadId': documentId,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc(docKey)
          .collection('uploads')
          .doc(documentId)
          .set(documentData);

      final matchNote = autoVerified
          ? ' OCR matched essential fields — awaiting admin confirmation.'
          : '';

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .add({
        'message':
            'Your ${widget.title} was uploaded and is pending admin review.$matchNote',
        'documentType': widget.title,
        'userId': user.uid,
        'userName': studentName,
        'uploadId': documentId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': AppConstants.notifTypeUser,
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .add({
        'message': autoVerified
            ? '$studentName uploaded ${widget.title} (OCR match — review)'
            : '$studentName uploaded a ${widget.title}',
        'documentType': widget.title,
        'userId': user.uid,
        'userName': studentName,
        'uploadId': documentId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': AppConstants.notifTypeAdmin,
        'isRead': false,
      });

      if (mounted) {
        AppSnackBar.success(
          context,
          autoVerified
              ? 'Uploaded — OCR matched; pending admin confirmation'
              : 'Document uploaded — pending admin review',
        );
        setState(() => isLocked = true);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Upload failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Color _statusColor({required bool matched, bool exact = false, bool partial = false}) {
    if (exact || matched && !partial) return AppTheme.successGreen;
    if (partial) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  Color _similarityColor(double similarity) {
    if (similarity >= 80) return AppTheme.successGreen;
    if (similarity >= 60) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  /// After OCR comparison results are available.
  bool get _canSubmit {
    if (isLocked) return false;
    return comparisonResults.isNotEmpty && selectedImage != null;
  }

  @override
  Widget build(BuildContext context) {
    final helper = isLocked
        ? 'Upload is locked. Please wait for admin review or rejection.'
        : 'Upload a clear JPG or PNG of your ${widget.title}. PDF is not supported for OCR.';

    return AppScaffold(
      title: 'Upload ${widget.title}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                const WizardStepper(currentStep: 1),
                const SizedBox(height: 12),
                Text(
                  helper,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _muted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPicker(),
                    if (selectedImage != null) _buildPreview(),
                    if (_imageQuality != null && _sharpnessScore != null) ...[
                      const SizedBox(height: 12),
                      _buildQualityBanner(),
                    ],
                    if (isProcessing) ...[
                      const SizedBox(height: 20),
                      const AppLoading(message: 'Extracting text…'),
                    ],
                    if (extractedText.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Extracted information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildExtractedText(),
                      if (comparisonResults.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Verification status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildResults(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_canSubmit && !isLocked)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppPrimaryButton(
                  label: isLocked ? 'Upload locked' : 'Upload document',
                  icon: Icons.cloud_upload_outlined,
                  isLoading: isUploading,
                  onPressed: isUploading || isLocked ? null : _uploadDocument,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPicker() {
    return Semantics(
      button: true,
      label: 'Select document image',
      child: AppCard(
        elevation: 0,
        color: FormStyles.fieldFill(context),
        onTap: isLocked ? null : _showSourceSheet,
        child: Column(
          children: [
            Icon(Icons.add_a_photo_outlined, size: 48, color: _muted),
            const SizedBox(height: 12),
            Text(
              selectedFileName ?? 'Select image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Camera · Gallery · Files  ·  JPG/PNG',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: double.infinity,
          color: FormStyles.fieldFill(context),
          child: Image.file(selectedImage!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildQualityBanner() {
    final score = _sharpnessScore ?? 0;
    final color = Color(DocumentValidators.qualityColorValue(score));
    final label = DocumentValidators.qualityLabel(score);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            _imageQuality == ImageQuality.sharp
                ? Icons.check_circle_outline
                : _imageQuality == ImageQuality.fair
                    ? Icons.info_outline
                    : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Image quality: $label',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FormStyles.fieldFill(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        extractedText,
        style: TextStyle(fontSize: 14, color: _onSurface, height: 1.35),
      ),
    );
  }

  Widget _buildResults() {
    final headerColor =
        isVerified ? AppTheme.successGreen : AppTheme.warningAmber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.warning_amber_rounded,
              color: headerColor,
            ),
            const SizedBox(width: 8),
            Text(
              isVerified ? 'Verification successful' : 'Verification incomplete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FormStyles.fieldFill(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Similarity: ${overallSimilarity.toStringAsFixed(1)}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _similarityColor(overallSimilarity),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...comparisonResults.entries.map((entry) {
          final result = entry.value as Map;
          final matched = result['matched'] as bool? ?? false;
          final exactMatch = result['exactMatch'] as bool? ?? false;
          final partialMatch = result['partialMatch'] as bool? ?? false;
          var matchedText = (result['matchedText'] as String?) ?? '';
          final isEssential = result['isEssential'] as bool? ?? false;
          final color = _statusColor(
            matched: matched,
            exact: exactMatch,
            partial: partialMatch,
          );

          if ((entry.key == 'aadharNumber' || entry.key == 'voterId') &&
              matched &&
              matchedText.length >= 4) {
            matchedText =
                '**** **** ${matchedText.substring(matchedText.length - 4)}';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      matched ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key.toUpperCase()}${isEssential ? ' *' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exactMatch
                            ? 'Exact'
                            : partialMatch
                                ? 'Partial'
                                : 'Missing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    'Expected: ${widget.expectedValues[entry.key] ?? 'N/A'}',
                    style: TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
                if (matched && partialMatch)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 2),
                    child: Text(
                      'Found: $matchedText',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ),
                if (isEssential)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 2),
                    child: Text(
                      'Required field',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _muted,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        if (widget.essentialFields.isNotEmpty)
          Text(
            '* Required fields must match for automatic verification',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _muted,
            ),
          ),
      ],
    );
  }
}
