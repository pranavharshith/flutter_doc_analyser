import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/screens/admin/admin_dashboard_screen.dart';
import '/screens/auth/auth_page.dart';
import '/screens/student/dashboard/dashboard_screen.dart';
import '/screens/student/student_details_page.dart';
import '/ui/ui.dart';
import '/utils/app_constants.dart';

/// Where a signed-in (or signed-out) user should land.
enum AppHomeDestination {
  auth,
  adminDashboard,
  studentDashboard,
  studentDetails,
  error,
}

/// Single source of truth for post-auth routing (main, sign-in, sign-up).
///
/// Also repairs incomplete `users/{uid}` docs for admin-domain emails (AUTH-02).
class AuthRouting {
  AuthRouting._();

  static bool isAdminEmail(String? email) => AppConstants.isAdminEmail(email);

  /// Resolve home for [user] (defaults to [FirebaseAuth.instance.currentUser]).
  static Future<AppHomeDestination> resolveHomeDestination({User? user}) async {
    try {
      final current = user ?? FirebaseAuth.instance.currentUser;
      if (current == null) return AppHomeDestination.auth;

      final email = (current.email ?? '').trim();
      final usersRef =
          FirebaseFirestore.instance.collection('users').doc(current.uid);
      var userSnap = await usersRef.get();
      var role = userSnap.exists
          ? (userSnap.data()?['role'] as String?)?.trim()
          : null;

      // AUTH-02: admin domain must never silently default to student.
      if (isAdminEmail(email)) {
        if (!userSnap.exists || role != AppConstants.roleAdmin) {
          await usersRef.set({
            'email': email,
            'role': AppConstants.roleAdmin,
            'updatedAt': FieldValue.serverTimestamp(),
            if (!userSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return AppHomeDestination.adminDashboard;
      }

      // Ensure a users doc exists for students (missing doc used to default
      // role to student without repair).
      if (!userSnap.exists) {
        await usersRef.set({
          'email': email,
          'role': AppConstants.roleStudent,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        role = AppConstants.roleStudent;
      } else if (role == AppConstants.roleAdmin && !isAdminEmail(email)) {
        // Non-admin email must not keep admin role from a bad doc.
        role = AppConstants.roleStudent;
      }

      if (role == AppConstants.roleAdmin) {
        return AppHomeDestination.adminDashboard;
      }

      final studentSnap = await FirebaseFirestore.instance
          .collection('students')
          .doc(current.uid)
          .get();

      final firstName = studentSnap.exists
          ? (studentSnap.data()?['firstName'] as String?)?.trim()
          : null;
      if (firstName != null && firstName.isNotEmpty) {
        return AppHomeDestination.studentDashboard;
      }
      return AppHomeDestination.studentDetails;
    } catch (e, st) {
      debugPrint('AuthRouting.resolveHomeDestination failed: $e\n$st');
      return AppHomeDestination.error;
    }
  }

  /// Widget for [dest] (including a recoverable error screen).
  static Widget buildHome(
    AppHomeDestination dest, {
    VoidCallback? onRetry,
  }) {
    switch (dest) {
      case AppHomeDestination.adminDashboard:
        return const AdminDashboardScreen();
      case AppHomeDestination.studentDashboard:
        return const StudentDashboard();
      case AppHomeDestination.studentDetails:
        return const StudentDetailsPage();
      case AppHomeDestination.auth:
        return const AuthPage();
      case AppHomeDestination.error:
        return Scaffold(
          body: AppEmptyState.error(
            title: 'Error loading app',
            message:
                'We could not determine where to send you. Retry or return to login.',
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppSecondaryButton(
                label: 'Return to Login',
                icon: Icons.logout,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  onRetry?.call();
                },
              ),
            ),
          ),
        );
    }
  }

  /// Replace the navigation stack with the correct home for the current user.
  static Future<void> navigateToResolvedHome(BuildContext context) async {
    final dest = await resolveHomeDestination();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => buildHome(
          dest,
          onRetry: () {
            // Caller screens that still need retry can re-invoke navigate.
          },
        ),
      ),
      (_) => false,
    );
  }
}
