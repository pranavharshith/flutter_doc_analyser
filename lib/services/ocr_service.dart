import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class OcrService {
  // Field extraction utilities reused across document forms

  /// Checks if a given text contains any of the keyword variations for a field.
  static bool containsField(String ocrText, List<String> keywords) {
    final lower = ocrText.toLowerCase();
    return keywords.any((kw) => lower.contains(kw.toLowerCase()));
  }

  /// Extracts Aadhar number (12 digits, optionally spaced in groups of 4) from OCR text.
  static String? extractAadharNumber(String ocrText) {
    // Relaxed pattern to allow common OCR misreads (O, o, l, I)
    final pattern = RegExp(r'\b[0-9OoIil]{4}[\s-]?[0-9OoIil]{4}[\s-]?[0-9OoIil]{4}\b');
    final match = pattern.firstMatch(ocrText);
    if (match != null) {
      return match.group(0)?.replaceAll(RegExp(r'[\s-]'), '').replaceAll(RegExp(r'[Oo]'), '0').replaceAll(RegExp(r'[Iil]'), '1');
    }
    return null;
  }

  /// Extracts a Voter ID number from OCR text matching 3 letters + 7 numbers, with some leeway.
  static String? extractVoterId(String ocrText) {
    // Allow O/0, I/1, S/5, Z/2 misreads
    final pattern = RegExp(r'\b[A-Z0-9]{3}[0-9A-Z]{7}\b', caseSensitive: false);
    final match = pattern.firstMatch(ocrText);
    return match?.group(0)?.toUpperCase();
  }

  /// Extracts a date in common formats from OCR text.
  static String? extractDate(String ocrText) {
    final patterns = [
      RegExp(r'\d{2}[/\-.]\d{2}[/\-.]\d{4}'),
      RegExp(r'\d{2}[/\-.]\d{2}[/\-.]\d{2}'),
      RegExp(
        r'\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(ocrText);
      if (m != null) return m.group(0);
    }
    return null;
  }

  /// Computes string similarity using Levenshtein distance to handle OCR misreads.
  static double wordSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    // Convert to uppercase and strip non-alphanumeric for comparison
    a = a.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    b = b.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    if (a.isEmpty || b.isEmpty) return 0.0;

    List<int> costs = List<int>.filled(b.length + 1, 0);
    for (int j = 0; j < costs.length; j++) {
      costs[j] = j;
    }
    for (int i = 1; i <= a.length; i++) {
      costs[0] = i;
      int nw = i - 1;
      for (int j = 1; j <= b.length; j++) {
        int cj = math.min(
          1 + math.min(costs[j], costs[j - 1]),
          a[i - 1] == b[j - 1] ? nw : nw + 1,
        );
        nw = costs[j];
        costs[j] = cj;
      }
    }
    int maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return (maxLen - costs[b.length]) / maxLen.toDouble();
  }
}
