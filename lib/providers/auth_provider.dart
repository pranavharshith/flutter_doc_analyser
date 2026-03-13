import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userDataMap;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Map<String, dynamic>? get userDataMap => _userDataMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    AuthService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userDataMap = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    _userDataMap = await AuthService.getUser(uid);
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final cred = await AuthService.signIn(email: email, password: password);
      _user = cred.user;
      await _loadUserData(_user!.uid);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// FIX: signUp now writes the user record to Firestore so the role and email
  /// are persisted regardless of which code path calls signUp.
  Future<bool> signUp(String email, String password, String role) async {
    _setLoading(true);
    try {
      final cred = await AuthService.signUp(email: email, password: password);
      _user = cred.user;
      if (_user != null) {
        // Write to 'users' collection with role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
          'email': email.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // If student, also create an entry in 'students' so lookups work
        if (role == 'student') {
          await FirebaseFirestore.instance
              .collection('students')
              .doc(_user!.uid)
              .set({
            'email': email.trim(),
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await _loadUserData(_user!.uid);
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSubmittedDetails');
    await AuthService.signOut();
    _user = null;
    _userDataMap = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
