import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a document image from a local [file] (mobile).
  /// Returns the public download URL.
  static Future<String> uploadDocument({
    required String uid,
    required String documentType,
    required String fileName,
    required File file,
  }) async {
    final storagePath =
        'documents/$uid/${documentType.toLowerCase().replaceAll(' ', '_')}/$fileName';
    final ref = _storage.ref().child(storagePath);
    final snapshot = await ref.putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  /// Uploads a profile image to Firebase Storage and returns the download URL.
  static Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=3600',
    );
    // Unique query-busting path segment is unnecessary; overwrite same object.
    final task = ref.putFile(file, metadata);
    final snapshot = await task;
    return snapshot.ref.getDownloadURL();
  }

  /// Deletes a file at the given storage path.
  static Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (_) {
      // Ignore if file does not exist
    }
  }
}
