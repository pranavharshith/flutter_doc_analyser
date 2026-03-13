import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a document file (image or PDF bytes) to Firebase Storage.
  /// Returns the public download URL.
  static Future<String> uploadDocument({
    required String uid,
    required String documentType,
    required String fileName,
    File? file,
    Uint8List? bytes,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final storagePath =
        'documents/$uid/${documentType.toLowerCase().replaceAll(' ', '_')}/$fileName';
    final ref = _storage.ref().child(storagePath);

    UploadTask task;
    if (bytes != null) {
      final metadata = SettableMetadata(
        contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext',
      );
      task = ref.putData(bytes, metadata);
    } else if (file != null) {
      task = ref.putFile(file);
    } else {
      throw ArgumentError('Either file or bytes must be provided');
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Uploads a profile image to Firebase Storage and returns the download URL.
  static Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    final task = ref.putFile(file);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
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
