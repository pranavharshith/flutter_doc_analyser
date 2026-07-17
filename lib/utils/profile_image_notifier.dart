import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/utils/app_constants.dart';

/// Global profile avatar reference for the student chrome.
///
/// Prefer **network URL** (works across devices). Local file path is only a
/// same-device cache for instant display after picking.
class ProfileImageNotifier {
  ProfileImageNotifier._();

  static final ValueNotifier<String?> _ref = ValueNotifier<String?>(null);

  /// Current image ref: `https://…` or local filesystem path.
  static ValueNotifier<String?> get imagePath => _ref;

  static bool isNetworkUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String _urlKey(String uid) =>
      '${AppConstants.prefProfileImagePath}url_$uid';

  static String _localKey(String uid) =>
      '${AppConstants.prefProfileImagePath}$uid';

  /// Load local cache, then prefer Firestore network URL when available.
  ///
  /// Requires [Firebase.initializeApp] to have completed first.
  static Future<void> init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _ref.value = null;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString(_urlKey(user.uid));
      final cachedLocal = prefs.getString(_localKey(user.uid));

      // Prefer network URL so other devices / reinstalls can show the photo.
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        _ref.value = cachedUrl;
      } else if (cachedLocal != null && cachedLocal.isNotEmpty) {
        _ref.value = cachedLocal;
      }

      try {
        // AUTH-06: students use students/{uid}; admins fall back to users/{uid}.
        String? remote;
        final studentSnap = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        remote = studentSnap.data()?['profileImageUrl'] as String?;
        if (remote == null || remote.isEmpty) {
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          remote = userSnap.data()?['profileImageUrl'] as String?;
        }
        if (remote != null && remote.isNotEmpty) {
          await prefs.setString(_urlKey(user.uid), remote);
          _ref.value = remote;
        }
      } catch (_) {
        // Offline: keep whatever cache we already have.
      }
    } catch (_) {
      // Firebase not ready / no app — leave avatar empty.
      _ref.value = null;
    }
  }

  /// After a successful Storage upload.
  static Future<void> updateFromUpload({
    required String localPath,
    required String downloadUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(user.uid), localPath);
    await prefs.setString(_urlKey(user.uid), downloadUrl);
    _ref.value = downloadUrl;
  }

  /// Legacy helper — stores a path/URL string.
  static Future<void> updateImagePath(String pathOrUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (isNetworkUrl(pathOrUrl)) {
      await prefs.setString(_urlKey(user.uid), pathOrUrl);
    } else {
      await prefs.setString(_localKey(user.uid), pathOrUrl);
    }
    // Prefer existing network URL if we only got a local path.
    final url = prefs.getString(_urlKey(user.uid));
    _ref.value = (url != null && url.isNotEmpty) ? url : pathOrUrl;
  }

  static Future<void> clearImagePath() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _ref.value = null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey(user.uid));
    await prefs.remove(_urlKey(user.uid));
    _ref.value = null;
  }

  /// Clear in-memory avatar (e.g. on sign-out). Does not wipe prefs for next login.
  static void clear() {
    _ref.value = null;
  }
}
