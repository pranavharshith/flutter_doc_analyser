import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DocumentValidators
//
// Tier-1 verification improvements — all run 100 % on-device, no API keys,
// no internet required, completely free forever.
//
//   • validateAadhaar   – Verhoeff check-digit algorithm (structurally validates
//                         any 12-digit Aadhaar number without contacting UIDAI).
//   • hashDocumentNumber – SHA-256 hex string used for privacy-preserving
//                         cross-student duplicate detection in Firestore.
//   • extractVoterId    – Multi-pattern regex covering 6 known Indian state
//                         EPIC formats instead of just the old 3-letter+7-digit.
//   • calculateSharpness – Laplacian-variance image-quality score computed
//                         entirely from the already-decoded pixel bytes; no
//                         extra package required.
// ─────────────────────────────────────────────────────────────────────────────

enum ImageQuality { sharp, fair, blurry }

class DocumentValidators {
  DocumentValidators._();

  // ── Verhoeff tables ────────────────────────────────────────────────────────
  // Multiplication table d
  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  // Permutation table p
  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  // ── Aadhaar validation ─────────────────────────────────────────────────────

  /// Validates a 12-digit Aadhaar number using the Verhoeff check-digit
  /// algorithm.  Strips all non-digit characters first so the caller can pass
  /// "1234 5678 9012" or "123456789012" — both are handled.
  ///
  /// Returns true  → number is structurally valid (check digit is correct).
  /// Returns false → obviously wrong / tampered number.
  ///
  /// NOTE: This does NOT verify the number against UIDAI — it only confirms
  /// the check digit, ruling out most typos and fake numbers.
  static bool validateAadhaar(String rawNumber) {
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) return false;
    // First digit of a valid Aadhaar must be 2–9
    final first = int.tryParse(digits[0]);
    if (first == null || first < 2) return false;

    int c = 0;
    for (int i = 0; i < digits.length; i++) {
      final n = int.parse(digits[i]);
      c = _d[c][_p[(digits.length - 1 - i) % 8][n]];
    }
    return c == 0;
  }

  // ── Document-number hashing ────────────────────────────────────────────────

  /// Returns a lowercase hex SHA-256 digest of [rawNumber].
  ///
  /// Normalises by keeping only letters/digits and lowercasing so that
  /// Aadhaar (`1234 5678 9012`), EPIC IDs (`ABC1234567`), and hall tickets
  /// all hash consistently without storing plaintext identifiers.
  ///
  /// The crypto package used here is:
  ///   • Free forever — MIT-licensed, maintained by Google Dart team
  ///   • Runs 100 % on-device — no network call, no API key
  static String hashDocumentNumber(String rawNumber) {
    final normalised =
        rawNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final bytes = utf8.encode(normalised);
    return sha256.convert(bytes).toString();
  }

  // ── Voter ID extraction ────────────────────────────────────────────────────

  /// Attempts to extract a valid Indian EPIC (Voter ID) number from raw OCR
  /// text using six regional format patterns.
  ///
  /// Known formats:
  ///   ABC1234567   — 3 uppercase + 7 digits (most states, most common)
  ///   AB1234567    — 2 uppercase + 7 digits (some states)
  ///   ABC123456    — 3 uppercase + 6 digits (Tamil Nadu older cards)
  ///   ABC12345678  — 3 uppercase + 8 digits (some Eastern states)
  ///   A123456789   — 1 uppercase + 9 digits (older format)
  ///   ABС0123456789 — 3 uppercase + 10 digits (Bihar, UP newer cards)
  ///
  /// Returns the first matching string, or null if none found.
  static String? extractVoterId(String ocrText) {
    final patterns = [
      RegExp(r'\b[A-Z]{3}\d{10}\b'), // 3+10 (newest)
      RegExp(r'\b[A-Z]{3}\d{8}\b'), // 3+8
      RegExp(r'\b[A-Z]{3}\d{7}\b'), // 3+7 (most common)
      RegExp(r'\b[A-Z]{3}\d{6}\b'), // 3+6 (Tamil Nadu)
      RegExp(r'\b[A-Z]{2}\d{7}\b'), // 2+7
      RegExp(r'\b[A-Z]{1}\d{9}\b'), // 1+9 (old)
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(ocrText);
      if (match != null) return match.group(0);
    }
    return null;
  }

  /// Returns true if [candidate] matches any known EPIC format pattern.
  static bool isValidVoterIdFormat(String candidate) {
    final trimmed = candidate.trim().toUpperCase();
    final patterns = [
      RegExp(r'^[A-Z]{3}\d{10}$'),
      RegExp(r'^[A-Z]{3}\d{8}$'),
      RegExp(r'^[A-Z]{3}\d{7}$'),
      RegExp(r'^[A-Z]{3}\d{6}$'),
      RegExp(r'^[A-Z]{2}\d{7}$'),
      RegExp(r'^[A-Z]{1}\d{9}$'),
    ];
    return patterns.any((p) => p.hasMatch(trimmed));
  }

  // ── Image sharpness ────────────────────────────────────────────────────────

  /// Computes a Laplacian-variance sharpness score for [image].
  ///
  /// Algorithm:
  ///   1. Read raw RGBA pixel bytes from the already-decoded ui.Image.
  ///   2. Convert a sampled grid of pixels to luminance (Y = 0.299R + 0.587G
  ///      + 0.114B).
  ///   3. Apply the discrete Laplacian kernel (centre×4 − four neighbours).
  ///   4. Return the variance of the Laplacian response.
  ///
  /// Interpretation:
  ///   > 150  → ImageQuality.sharp  — suitable for OCR
  ///   50–150 → ImageQuality.fair   — OCR may miss some fields; warn user
  ///   < 50   → ImageQuality.blurry — likely to produce bad OCR; warn strongly
  ///
  /// Pure Dart + dart:ui — no extra package, no internet, free forever.
  static Future<double> calculateSharpness(ui.Image image) async {
    ByteData? byteData;
    try {
      byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } catch (_) {
      return 100.0; // fallback: assume passable quality
    }
    if (byteData == null) return 100.0;

    final bytes = byteData.buffer.asUint8List();
    final w = image.width;
    final h = image.height;

    // Adaptive step: aim for ~8 000–12 000 sample points regardless of
    // image resolution to keep computation under ~50 ms on a mid-range phone.
    final step = ((w * h) / 10000).ceil().clamp(1, 16);

    double sumLap = 0.0;
    double sumLapSq = 0.0;
    int count = 0;

    // Inline luminance helper: given pixel at (px,py) return Y in [0,255].
    double lum(int px, int py) {
      final idx = (py * w + px) * 4;
      return 0.299 * bytes[idx] +
          0.587 * bytes[idx + 1] +
          0.114 * bytes[idx + 2];
    }

    for (int y = 1; y < h - 1; y += step) {
      for (int x = 1; x < w - 1; x += step) {
        // Laplacian: ∇²f ≈ 4·f(x,y) − f(x−1,y) − f(x+1,y) − f(x,y−1) − f(x,y+1)
        final lap = 4.0 * lum(x, y) -
            lum(x - 1, y) -
            lum(x + 1, y) -
            lum(x, y - 1) -
            lum(x, y + 1);
        sumLap += lap;
        sumLapSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 100.0;

    final mean = sumLap / count;
    final variance = (sumLapSq / count) - (mean * mean);
    return variance.clamp(0.0, double.infinity);
  }

  /// Converts a raw sharpness variance score to a human-readable quality level.
  static ImageQuality qualityFromScore(double score) {
    if (score >= 150) return ImageQuality.sharp;
    if (score >= 50) return ImageQuality.fair;
    return ImageQuality.blurry;
  }

  /// Short label for display in the UI.
  static String qualityLabel(double score) {
    switch (qualityFromScore(score)) {
      case ImageQuality.sharp:
        return 'Good quality';
      case ImageQuality.fair:
        return 'Acceptable quality';
      case ImageQuality.blurry:
        return 'Image may be blurry';
    }
  }

  /// Colour corresponding to the quality level.
  static int qualityColorValue(double score) {
    switch (qualityFromScore(score)) {
      case ImageQuality.sharp:
        return 0xFF10B981; // green
      case ImageQuality.fair:
        return 0xFFF59E0B; // amber
      case ImageQuality.blurry:
        return 0xFFEF4444; // red
    }
  }
}
