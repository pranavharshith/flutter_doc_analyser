class FieldVerificationResult {
  final bool matched;
  final bool exactMatch;
  final bool partialMatch;
  final String matchedText;
  final bool isEssential;
  final String originalValue;

  FieldVerificationResult({
    required this.matched,
    required this.exactMatch,
    required this.partialMatch,
    required this.matchedText,
    required this.isEssential,
    required this.originalValue,
  });

  factory FieldVerificationResult.fromMap(Map<String, dynamic> map) {
    return FieldVerificationResult(
      matched: map['matched'] ?? false,
      exactMatch: map['exactMatch'] ?? false,
      partialMatch: map['partialMatch'] ?? false,
      matchedText: map['matchedText'] ?? '',
      isEssential: map['isEssential'] ?? false,
      originalValue: map['originalValue'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matched': matched,
      'exactMatch': exactMatch,
      'partialMatch': partialMatch,
      'matchedText': matchedText,
      'isEssential': isEssential,
      'originalValue': originalValue,
    };
  }
}

class VerificationModel {
  final String documentType;
  final Map<String, FieldVerificationResult> fieldResults;
  final double overallSimilarity;
  final bool isVerified;
  final String extractedText;

  VerificationModel({
    required this.documentType,
    required this.fieldResults,
    required this.overallSimilarity,
    required this.isVerified,
    required this.extractedText,
  });
}
