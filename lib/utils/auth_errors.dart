import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth exceptions to short, user-facing messages.
class AuthErrors {
  AuthErrors._();

  static String message(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'requires-recent-login':
          return 'Please sign in again to complete this action.';
        default:
          return error.message?.isNotEmpty == true
              ? error.message!
              : 'Authentication failed. Please try again.';
      }
    }
    final s = error.toString();
    if (s.contains('network') || s.contains('SocketException')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
