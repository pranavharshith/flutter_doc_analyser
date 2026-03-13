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

  // Admin email domain
  static const String adminEmailDomain = '@admin.vortexapp.com';

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

  // SharedPreferences keys
  static const String prefDarkMode = 'isDarkMode';
  static const String prefProfileImagePath = 'profile_image_path_';

  // Trash auto-delete duration (days)
  static const int trashRetentionDays = 15;
}
