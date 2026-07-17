class AppConstants {
  // App info
  static const String appName = 'Vortex Dashboard';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String notificationsCollection = 'notifications';
  static const String documentsSubCollection = 'documents';
  static const String uploadsSubCollection = 'uploads';
  static const String userNotificationsSubCollection = 'userNotifications';
  static const String adminNotificationsSubCollection = 'adminNotifications';
  static const String trashSubCollection = 'trash';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';

  // Admin email domain (JWT email must match for admin routes + rules).
  static const String adminEmailDomain = '@admin.vortexapp.com';

  /// Optional extra allow-list of full admin emails (lowercase). Empty = any
  /// address on [adminEmailDomain]. Use to lock down production sign-ups.
  static const List<String> adminEmailAllowlist = <String>[
    // e.g. 'ops@admin.vortexapp.com',
  ];

  // Notification type strings (UX-03)
  static const String notifTypeUser = 'user';
  static const String notifTypeAdmin = 'admin';
  static const String notifTypeReupload = 'reupload';
  static const String notifTypeCompletion = 'completion';

  // Document types
  static const String docAadhar = 'Aadhar Card';
  static const String docVoterId = 'Voter ID';
  static const String docTenth = '10th Marksheet';
  static const String docTwelfth = '12th Marksheet';

  static const List<String> documentTypes = [
    docAadhar,
    docVoterId,
    docTenth,
    docTwelfth,
  ];

  /// Firestore document keys (snake_case) aligned with [documentTypes].
  static const List<String> documentTypeKeys = [
    'aadhar_card',
    'voter_id',
    '10th_marksheet',
    '12th_marksheet',
  ];

  static const Map<String, String> documentTypeLabels = {
    'aadhar_card': docAadhar,
    'voter_id': docVoterId,
    '10th_marksheet': docTenth,
    '12th_marksheet': docTwelfth,
  };

  /// Canonical display title for a document type (title, key, or messy string).
  static String normalizeDocumentType(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    final lower = t.toLowerCase().replaceAll(' ', '_');
    if (documentTypeLabels.containsKey(lower)) {
      return documentTypeLabels[lower]!;
    }
    for (final title in documentTypes) {
      if (title.toLowerCase() == t.toLowerCase()) return title;
    }
    // Common aliases
    if (lower.contains('aadhar') || lower.contains('aadhaar')) return docAadhar;
    if (lower.contains('voter')) return docVoterId;
    if (lower.contains('10') || lower.contains('tenth')) return docTenth;
    if (lower.contains('12') || lower.contains('twelfth')) return docTwelfth;
    return t;
  }

  static String documentTypeKey(String titleOrKey) {
    final title = normalizeDocumentType(titleOrKey);
    for (final e in documentTypeLabels.entries) {
      if (e.value == title) return e.key;
    }
    return title.toLowerCase().replaceAll(' ', '_');
  }

  static bool isAdminEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final e = email.trim().toLowerCase();
    if (!e.endsWith(adminEmailDomain.toLowerCase())) return false;
    if (adminEmailAllowlist.isEmpty) return true;
    return adminEmailAllowlist.map((x) => x.toLowerCase()).contains(e);
  }

  /// All Indian states and union territories (alphabetical).
  static const List<String> indianStatesAndUTs = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  // Support contacts (Help screen)
  static const String supportEmail = 'support@vortexapp.com';
  static const String supportPhone = '+91 1800 123 4567';
  static const String supportPhoneTel = '+9118001234567';

  // SharedPreferences keys
  /// Legacy bool key — still written for migration; prefer [prefThemeMode].
  static const String prefDarkMode = 'isDarkMode';
  /// Stores `light` | `dark` | `system`.
  static const String prefThemeMode = 'theme_mode';
  static const String prefProfileImagePath = 'profile_image_path_';

  // Trash auto-delete duration (days)
  static const int trashRetentionDays = 15;
}
