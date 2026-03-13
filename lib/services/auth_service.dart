import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Determines the role of the user from Firestore.
  static Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return 'student';
    return doc.data()!['role'] ?? 'student';
  }

  /// Returns true if the student has filled in their details.
  static Future<bool> hasStudentDetails(String uid) async {
    final doc = await _firestore.collection('students').doc(uid).get();
    return doc.exists && doc.data()!.containsKey('firstName');
  }

  /// FIX: Returns user data map from Firestore for AuthProvider._loadUserModel.
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': uid, ...doc.data()!};
  }
}
