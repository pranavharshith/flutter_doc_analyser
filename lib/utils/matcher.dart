class Matcher {
  /// Returns the ratio of matched words between [source] and [target] (0.0 – 1.0).
  static double wordOverlapRatio(String source, String target) {
    if (source.isEmpty || target.isEmpty) return 0.0;
    final srcWords =
        source.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    final tgtLower = target.toLowerCase();
    if (srcWords.isEmpty) return 0.0;
    final matched = srcWords.where((w) => tgtLower.contains(w)).length;
    return matched / srcWords.length;
  }

  /// Returns true if [value] is found (case-insensitive) inside [text].
  static bool containsExact(String text, String value) {
    if (value.trim().isEmpty) return false;
    return text.toLowerCase().contains(value.trim().toLowerCase());
  }

  /// Normalises a date string by removing separators.
  static String normaliseDate(String date) {
    return date.replaceAll(RegExp(r'[/\-.]'), '');
  }

  /// Checks if two dates match after normalisation.
  static bool datesMatch(String a, String b) {
    return normaliseDate(a) == normaliseDate(b);
  }
}
