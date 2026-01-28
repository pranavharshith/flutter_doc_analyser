import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageNotifier {
  static final ValueNotifier<String?> _imagePathNotifier =
      ValueNotifier<String?>(null);
  static ValueNotifier<String?> get imagePath => _imagePathNotifier;

  static Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      _imagePathNotifier.value =
          prefs.getString('profile_image_path_${user.uid}');
    }
  }

  static Future<void> updateImagePath(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path_${user.uid}', path);
      _imagePathNotifier.value = path;
    }
  }

  static Future<void> clearImagePath() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path_${user.uid}');
      _imagePathNotifier.value = null;
    }
  }
}
