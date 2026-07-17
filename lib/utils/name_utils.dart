/// Shared helpers for the student name field contract.
///
/// Always prefer storing:
/// - `firstName`, `lastName`
/// - computed `name` = `"$firstName $lastName".trim()`
class NameUtils {
  NameUtils._();

  /// Display name from a student/users map.
  static String displayNameFromMap(Map<String, dynamic>? data, {String fallback = 'Student'}) {
    if (data == null) return fallback;
    final name = (data['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    final first = (data['firstName'] as String?)?.trim() ?? '';
    final last = (data['lastName'] as String?)?.trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;

    return fallback;
  }

  /// Split a full name into (first, last). Last word → lastName when multi-word.
  static ({String firstName, String lastName}) splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (firstName: '', lastName: '');
    if (parts.length == 1) return (firstName: parts.first, lastName: '');
    return (
      firstName: parts.sublist(0, parts.length - 1).join(' '),
      lastName: parts.last,
    );
  }

  static String composeName(String firstName, String lastName) {
    return '${firstName.trim()} ${lastName.trim()}'.trim();
  }

  /// Payload fragment to merge into Firestore student/user docs.
  static Map<String, String> firestoreNameFields({
    required String firstName,
    required String lastName,
  }) {
    final first = firstName.trim();
    final last = lastName.trim();
    return {
      'firstName': first,
      'lastName': last,
      'name': composeName(first, last),
    };
  }
}
