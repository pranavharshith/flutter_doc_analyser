import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document_model.dart';

class DocumentProvider extends ChangeNotifier {
  final List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<DocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments(String uid, String docTypeKey) async {
    _setLoading(true);
    _error = null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('documents')
          .doc(docTypeKey)
          .collection('uploads')
          .orderBy('submittedAt', descending: true)
          .get();
      _documents
        ..clear()
        ..addAll(
            snap.docs.map((d) => DocumentModel.fromMap(d.data(), d.id)));
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
