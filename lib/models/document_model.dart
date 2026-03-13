import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String fileName;
  final String documentType;
  final String status; // 'Pending', 'Verified', 'Rejected'
  final bool verified;
  final double overallSimilarity;
  final String extractedText;
  final Map<String, String> verifiedFields;
  final String userId;
  final String name;
  final Timestamp uploadDate;
  final String? fileUrl; // Firebase Storage URL

  DocumentModel({
    required this.id,
    required this.fileName,
    required this.documentType,
    required this.status,
    required this.verified,
    required this.overallSimilarity,
    required this.extractedText,
    required this.verifiedFields,
    required this.userId,
    required this.name,
    required this.uploadDate,
    this.fileUrl,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      fileName: map['fileName'] ?? '',
      documentType: map['documentType'] ?? '',
      status: map['status'] ?? 'Pending',
      verified: map['verified'] ?? false,
      overallSimilarity: (map['overallSimilarity'] ?? 0.0).toDouble(),
      extractedText: map['extractedText'] ?? '',
      verifiedFields: Map<String, String>.from(map['verifiedFields'] ?? {}),
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Unknown',
      uploadDate: map['submittedAt'] ?? Timestamp.now(),
      fileUrl: map['fileUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'documentType': documentType,
      'status': status,
      'verified': verified,
      'overallSimilarity': overallSimilarity,
      'extractedText': extractedText,
      'verifiedFields': verifiedFields,
      'userId': userId,
      'name': name,
      'submittedAt': uploadDate,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };
  }
}
