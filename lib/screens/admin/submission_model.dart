import 'package:cloud_firestore/cloud_firestore.dart';

import '/utils/app_constants.dart';

/// One document upload shown on the admin dashboard / popup.
class Submission {
  final String id;
  final String name;
  final String userId;
  final String documentType;
  String status;
  final Timestamp submittedAt;
  final Map<String, dynamic> details;
  final double similarity;
  final Map<String, String> verifiedFields;
  final List<Submission> history;

  Submission({
    required this.id,
    required this.name,
    required this.userId,
    required this.documentType,
    required this.status,
    required this.submittedAt,
    required this.details,
    required this.similarity,
    required this.verifiedFields,
    this.history = const [],
  });

  factory Submission.fromMap(Map<String, dynamic> map, String id) {
    final uid = (map['userId'] as String?)?.trim() ?? '';
    final display = (map['studentName'] as String?)?.trim().isNotEmpty == true
        ? map['studentName'] as String
        : (map['name'] as String?) ?? 'Unknown';
    return Submission(
      id: id,
      name: display,
      userId: uid,
      documentType: AppConstants.normalizeDocumentType(
        (map['documentType'] as String?) ?? '',
      ),
      status: map['status'] ?? 'Not Submitted',
      submittedAt: map['submittedAt'] is Timestamp
          ? map['submittedAt'] as Timestamp
          : Timestamp.now(),
      details: map,
      similarity: (map['overallSimilarity'] ?? 0.0).toDouble(),
      verifiedFields: Map<String, String>.from(
        (map['verifiedFields'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            {},
      ),
    );
  }

  Submission copyWith({
    String? status,
    List<Submission>? history,
    Map<String, dynamic>? details,
  }) {
    return Submission(
      id: id,
      name: name,
      userId: userId,
      documentType: documentType,
      status: status ?? this.status,
      submittedAt: submittedAt,
      details: details ?? this.details,
      similarity: similarity,
      verifiedFields: verifiedFields,
      history: history ?? this.history,
    );
  }

  bool get autoVerified => details['autoVerified'] == true;

  String get email =>
      (details['studentEmail'] as String?)?.trim() ?? '';

  String? get fileUrl {
    final u = details['fileUrl'] as String?;
    if (u == null || u.isEmpty) return null;
    return u;
  }

  bool isValid() {
    return name.isNotEmpty &&
        documentType.isNotEmpty &&
        status.isNotEmpty &&
        userId.isNotEmpty;
  }
}
