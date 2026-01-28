import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String title;
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;
  final Map<String, String> expectedValues;
  final List<String> essentialFields;

  const UploadDocumentScreen({
    super.key,
    required this.title,
    required this.toggleDarkMode,
    required this.isDarkMode,
    required this.expectedValues,
    this.essentialFields = const [],
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  String? selectedFileName;
  File? selectedImage;
  Uint8List? webImageBytes;
  bool isProcessing = false;
  bool isUploading = false;
  bool isLocked = false;
  String extractedText = '';
  Map<String, dynamic> comparisonResults = {};
  bool isVerified = false;
  double overallSimilarity = 0.0;

  final TextRecognizer _textRecognizer = TextRecognizer();

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
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          isLocked = data['locked'] ?? false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error checking upload status: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _pickImage() async {
    if (isLocked) {
      Fluttertoast.showToast(
        msg: 'Upload is locked. Wait for admin review or rejection.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.single.bytes;
        final name = result.files.single.name;

        if (bytes != null) {
          setState(() {
            selectedFileName = name;
            webImageBytes = bytes;
          });

          if (kIsWeb) {
            setState(() {
              extractedText =
                  'Web text recognition requires additional setup.\nTry using the mobile app instead.';
              isProcessing = false;
            });
          } else {
            String? path = result.files.single.path;
            if (path != null) {
              File file = File(path);
              setState(() {
                selectedImage = file;
              });
              await _processImage(file);
            } else {
              Fluttertoast.showToast(
                msg: "Unable to access file path. Please try again.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }
        } else {
          Fluttertoast.showToast(
            msg: "No valid file data found.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
        );

        if (image != null) {
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            setState(() {
              selectedFileName = image.name;
              webImageBytes = bytes;
              extractedText =
                  'Web text recognition requires additional setup.\nTry using the mobile app instead.';
              isProcessing = false;
            });
          } else {
            if (image.path.isNotEmpty) {
              File file = File(image.path);
              setState(() {
                selectedImage = file;
                selectedFileName = image.name;
              });
              await _processImage(file);
            } else {
              Fluttertoast.showToast(
                msg: "Unable to access image path. Please try again.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            }
          }
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error picking image: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _processImage(File image) async {
    setState(() {
      isProcessing = true;
      extractedText = '';
      comparisonResults.clear();
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      String text = recognizedText.text;

      setState(() {
        extractedText = text.isNotEmpty ? text : 'No text found';
        comparisonResults = _compareTextWithExpected(text);

        int essentialFieldCount = widget.essentialFields.length;
        int matchedEssentialFields = 0;

        for (String field in widget.essentialFields) {
          if (comparisonResults.containsKey(field) &&
              comparisonResults[field]['matched']) {
            matchedEssentialFields++;
          }
        }

        isVerified = matchedEssentialFields == essentialFieldCount;

        if (comparisonResults.isNotEmpty) {
          int totalMatched = 0;
          for (var result in comparisonResults.values) {
            if (result is Map && result['matched']) totalMatched++;
          }
          overallSimilarity = totalMatched / comparisonResults.length * 100;
        }
      });

      if (isVerified && mounted) {
        Fluttertoast.showToast(
          msg: 'Verified Successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        extractedText = 'Error: $e';
      });
      Fluttertoast.showToast(
        msg: 'Processing failed: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
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
            final voterIdPattern = RegExp(r'\b\d{10,12}\b');
            if (voterIdPattern.hasMatch(ocrText)) {
              final extractedVoterId =
                  voterIdPattern.firstMatch(ocrText)?.group(0) ?? '';
              exactMatch = extractedVoterId == formattedValue;
              matchedText =
                  exactMatch
                      ? '**** **** ${extractedVoterId.substring(extractedVoterId.length - 4)}'
                      : '';
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
                caseSensitive: false,
              ),
            ];
            for (RegExp pattern in datePatterns) {
              Iterable<RegExpMatch> dateMatches = pattern.allMatches(ocrText);
              if (dateMatches.isNotEmpty) {
                matchedText = dateMatches.first.group(0)!;
                String simplifiedExpected = formattedValue.replaceAll(
                  RegExp(r'[/\-\.]'),
                  '',
                );
                String simplifiedFound = matchedText.replaceAll(
                  RegExp(r'[/\-\.]'),
                  '',
                );
                exactMatch = simplifiedExpected == simplifiedFound;
                partialMatch =
                    !exactMatch &&
                    simplifiedExpected.contains(
                      simplifiedFound.substring(0, 4),
                    );
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
    if (selectedImage == null && webImageBytes == null) {
      Fluttertoast.showToast(
        msg: 'No image selected',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: 'User not logged in',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        setState(() {
          isUploading = false;
        });
        return;
      }

      String documentId =
          '${DateTime.now().millisecondsSinceEpoch}_${selectedFileName ?? "document"}';

      Map<String, String> verifiedFields = {};
      comparisonResults.forEach((key, value) {
        if (value['matched'] && value['originalValue'] != null) {
          verifiedFields[key] = value['originalValue'];
        }
      });

      Map<String, dynamic> documentData = {
        'fileName': selectedFileName,
        'uploadDate': FieldValue.serverTimestamp(),
        'verified': isVerified,
        'overallSimilarity': overallSimilarity,
        'verifiedFields': verifiedFields,
        'extractedText': extractedText,
        'status': isVerified ? 'Verified' : 'Pending',
        'name': widget.expectedValues['name'] ?? 'Unknown',
        'documentType': widget.title,
        'userId': user.uid,
      };

      switch (widget.title) {
        case 'Aadhar Card':
          documentData['aadharLast4'] =
              verifiedFields['aadharNumber']?.substring(
                verifiedFields['aadharNumber']!.length - 4,
              ) ??
              '';
          break;
        case 'Voter ID':
          documentData['voterId'] = verifiedFields['voterId'] ?? '';
          documentData['fatherName'] = verifiedFields['fatherName'] ?? '';
          documentData['dob'] = verifiedFields['dob'] ?? '';
          documentData['gender'] = verifiedFields['gender'] ?? '';
          break;
        case '10th Marksheet':
          documentData['schoolName'] = verifiedFields['schoolName'] ?? '';
          documentData['medium'] = verifiedFields['medium'] ?? '';
          documentData['board'] = verifiedFields['board'] ?? '';
          documentData['hallTicket'] = verifiedFields['hallTicket'] ?? '';
          documentData['percentage'] = verifiedFields['percentage'] ?? '';
          documentData['examDate'] = verifiedFields['examDate'] ?? '';
          break;
        case '12th Marksheet':
          documentData['medium'] = verifiedFields['medium'] ?? '';
          documentData['board'] = verifiedFields['board'] ?? '';
          documentData['hallTicket'] = verifiedFields['hallTicket'] ?? '';
          documentData['percentage'] = verifiedFields['percentage'] ?? '';
          documentData['examDate'] = verifiedFields['examDate'] ?? '';
          break;
      }

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc(widget.title.toLowerCase().replaceAll(' ', '_'))
          .set({
            'name': widget.expectedValues['name'] ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
            'locked': isVerified,
          });

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .collection('documents')
          .doc(widget.title.toLowerCase().replaceAll(' ', '_'))
          .collection('uploads')
          .doc(documentId)
          .set(documentData);

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(user.uid)
          .collection('userNotifications')
          .add({
            'message':
                'Your ${widget.title} has been uploaded and is ${isVerified ? "verified" : "pending review"}',
            'documentType': widget.title,
            'userId': user.uid,
            'userName': widget.expectedValues['name'] ?? 'Unknown',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'user',
            'isRead': false,
          });

      Map<String, dynamic> adminNotificationData = {
        'message':
            '${widget.expectedValues['name'] ?? 'Unknown'} uploaded a ${widget.title}',
        'documentType': widget.title,
        'userId': user.uid,
        'userName': widget.expectedValues['name'] ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'admin',
        'isRead': false,
      };

      switch (widget.title) {
        case 'Aadhar Card':
          adminNotificationData['aadharLast4'] =
              verifiedFields['aadharNumber']?.substring(
                verifiedFields['aadharNumber']!.length - 4,
              ) ??
              '';
          adminNotificationData['name'] = verifiedFields['name'] ?? '';
          break;
        case 'Voter ID':
          adminNotificationData['name'] = verifiedFields['name'] ?? '';
          adminNotificationData['voterId'] =
              verifiedFields['voterId'] != null
                  ? '**** **** ${verifiedFields['voterId']!.substring(verifiedFields['voterId']!.length - 4)}'
                  : '';
          break;
        case '10th Marksheet':
          adminNotificationData['schoolName'] =
              verifiedFields['schoolName'] ?? '';
          adminNotificationData['percentage'] =
              verifiedFields['percentage'] ?? '';
          adminNotificationData['examDate'] = verifiedFields['examDate'] ?? '';
          break;
        case '12th Marksheet':
          adminNotificationData['percentage'] =
              verifiedFields['percentage'] ?? '';
          adminNotificationData['examDate'] = verifiedFields['examDate'] ?? '';
          break;
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('admin')
          .collection('adminNotifications')
          .add(adminNotificationData);

      Fluttertoast.showToast(
        msg: 'Document verification data saved successfully',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

      if (mounted) {
        setState(() {
          isLocked = isVerified;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Upload failed: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload ${widget.title}",
          style: const TextStyle(
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
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: const Color(0xFFFFFFFF),
            ),
            onPressed: widget.toggleDarkMode,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                widget.isDarkMode
                    ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Upload ${widget.title} Verification",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDarkMode
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF1B263B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isLocked
                      ? "Upload is locked. Please wait for admin review or rejection."
                      : "Please upload a clear image of your ${widget.title} for verification",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        widget.isDarkMode
                            ? const Color(0xFFB0C4DE)
                            : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? const Color(0xFF2A3A5A)
                                : const Color(0xFFFFFFFF).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              widget.isDarkMode ? 0.3 : 0.1,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildImagePickerCard(),
                          if (webImageBytes != null && kIsWeb)
                            _buildImagePreview(web: true),
                          if (selectedImage != null) _buildImagePreview(),
                          if (isProcessing) ...[
                            const SizedBox(height: 16),
                            CircularProgressIndicator(
                              color:
                                  widget.isDarkMode
                                      ? const Color(0xFFB0C4DE)
                                      : const Color(0xFF415A77),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Processing with ML Kit...',
                              style: TextStyle(
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (extractedText.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Extracted Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    widget.isDarkMode
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF1B263B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildExtractedTextCard(),
                            const SizedBox(height: 24),
                            if (comparisonResults.isNotEmpty) ...[
                              Text(
                                'Verification Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDarkMode
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF1B263B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildVerificationResultsCard(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (comparisonResults.isNotEmpty && !isLocked) ...[
                  const SizedBox(height: 16),
                  _buildUploadButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerCard() {
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? const Color(0xFF2A3A5A)
                : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 48,
                color:
                    widget.isDarkMode
                        ? const Color(0xFFB0C4DE)
                        : const Color(0xFF415A77),
              ),
              const SizedBox(height: 12),
              Text(
                selectedFileName ?? "Select Image",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      widget.isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF1B263B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Supported: JPG, PNG",
                style: TextStyle(
                  fontSize: 12,
                  color:
                      widget.isDarkMode
                          ? const Color(0xFFB0C4DE)
                          : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview({bool web = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? const Color(0xFF2A3A5A)
                : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 200,
          width: double.infinity,
          color:
              widget.isDarkMode
                  ? const Color(0xFF1B263B)
                  : const Color(0xFFF5F7FA),
          child:
              web
                  ? Image.memory(webImageBytes!, fit: BoxFit.contain)
                  : Image.file(selectedImage!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildExtractedTextCard() {
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? const Color(0xFF2A3A5A)
                : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          extractedText,
          style: TextStyle(
            fontSize: 14,
            color:
                widget.isDarkMode
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF1B263B),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationResultsCard() {
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isDarkMode
                ? const Color(0xFF2A3A5A)
                : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.warning,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isVerified
                      ? "Verification Successful"
                      : "Verification Incomplete",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode
                        ? const Color(0xFF1B263B)
                        : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Similarity: ${overallSimilarity.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getSimilarityColor(overallSimilarity),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ...comparisonResults.entries.map((entry) {
              final result = entry.value as Map;
              final bool matched = result['matched'] as bool;
              final bool exactMatch = result['exactMatch'] as bool;
              final bool partialMatch = result['partialMatch'] as bool;
              String matchedText = result['matchedText'] as String;
              final bool isEssential = result['isEssential'] as bool;

              if (entry.key == 'aadharNumber') {
                matchedText =
                    matched
                        ? '**** **** ${matchedText.substring(matchedText.length - 4)}'
                        : '';
              } else if (entry.key == 'voterId') {
                matchedText =
                    matched
                        ? '**** **** ${matchedText.substring(matchedText.length - 4)}'
                        : '';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          matched ? Icons.check : Icons.close,
                          color: matched ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${entry.key.toUpperCase()}${isEssential ? ' *' : ''}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.isDarkMode
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF1B263B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                exactMatch
                                    ? Colors.green.withOpacity(0.1)
                                    : partialMatch
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exactMatch
                                ? "Exact"
                                : partialMatch
                                ? "Partial"
                                : "Missing",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  exactMatch
                                      ? Colors.green
                                      : partialMatch
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expected: ${widget.expectedValues[entry.key] ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  widget.isDarkMode
                                      ? const Color(0xFFB0C4DE)
                                      : const Color(0xFF6B7280),
                            ),
                          ),
                          if (matched && partialMatch)
                            Text(
                              "Found: $matchedText",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isEssential)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
                        child: Text(
                          "Required field",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color:
                                widget.isDarkMode
                                    ? Colors.amber
                                    : Colors.deepOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (widget.essentialFields.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "* Required fields must match for verification",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color:
                        widget.isDarkMode
                            ? const Color(0xFFB0C4DE)
                            : const Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 80) return Colors.green;
    if (similarity >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: isUploading || isLocked ? null : _uploadDocument,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            isUploading
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFFFFF),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Uploading...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                )
                : Text(
                  isLocked ? "Upload Locked" : "Upload Document",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
      ),
    );
  }
}