import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/ui/ui.dart';
import '/utils/theme.dart';
import '/utils/app_constants.dart';
import '/utils/name_utils.dart';

class DashboardContent extends StatefulWidget {
  final VoidCallback onNavigateToUploads;
  final VoidCallback? onNavigateToNotifications;

  /// Increment when the Home tab is re-selected to reload stats after uploads.
  final int refreshToken;

  const DashboardContent({
    super.key,
    required this.onNavigateToUploads,
    this.onNavigateToNotifications,
    this.refreshToken = 0,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _uploadedCount = 0;
  int _verifiedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _userName = '';
  Map<String, String> _docStatuses = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      final displayName = NameUtils.displayNameFromMap(userDoc.data());

      int uploaded = 0;
      int verified = 0;
      int pending = 0;
      int rejected = 0;
      final statuses = <String, String>{};

      for (final docType in AppConstants.documentTypeKeys) {
        final uploads = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .collection('documents')
            .doc(docType)
            .collection('uploads')
            .orderBy('submittedAt', descending: true)
            .limit(1)
            .get();

        String status = 'Not Submitted';
        if (uploads.docs.isNotEmpty) {
          uploaded++;
          status = uploads.docs.first.data()['status'] as String? ?? 'Pending';
          switch (status) {
            case 'Verified':
              verified++;
              break;
            case 'Rejected':
              rejected++;
              break;
            case 'Pending':
              pending++;
              break;
          }
        }
        statuses[docType] = status;
      }

      if (mounted) {
        setState(() {
          _userName = displayName;
          _uploadedCount = uploaded;
          _verifiedCount = verified;
          _pendingCount = pending;
          _rejectedCount = rejected;
          _docStatuses = statuses;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final muted = isDarkMode ? AppTheme.accentBlue : AppTheme.textMuted;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final allDone = _uploadedCount >= AppConstants.documentTypeKeys.length;

    return AppGradientBody(
      child: _isLoading
          ? _DashboardSkeleton(muted: muted)
          : _hasError
              ? AppEmptyState.error(
                  title: 'Could not load dashboard',
                  message: 'Check your connection and try again.',
                  onAction: _fetchDashboardData,
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  color: AppTheme.primaryMid,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 16, color: muted),
                      ),
                      Text(
                        _userName.isNotEmpty ? _userName : 'Student',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.appBarGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryMid.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Progress',
                              style: TextStyle(
                                color: AppTheme.bgLight.withValues(alpha: 0.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _uploadedCount /
                                            AppConstants
                                                .documentTypeKeys.length,
                                        strokeWidth: 8,
                                        backgroundColor: AppTheme.bgLight
                                            .withValues(alpha: 0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<
                                                Color>(AppTheme.bgLight),
                                      ),
                                      Center(
                                        child: Text(
                                          '$_uploadedCount/${AppConstants.documentTypeKeys.length}',
                                          style: const TextStyle(
                                            color: AppTheme.bgLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        allDone
                                            ? 'All documents uploaded!'
                                            : '${AppConstants.documentTypeKeys.length - _uploadedCount} documents remaining.',
                                        style: const TextStyle(
                                          color: AppTheme.bgLight,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$_verifiedCount verified · $_pendingCount pending · $_rejectedCount rejected',
                                        style: TextStyle(
                                          color: AppTheme.bgLight
                                              .withValues(alpha: 0.75),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Document status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...AppConstants.documentTypeKeys.map((key) {
                        final label =
                            AppConstants.documentTypeLabels[key] ?? key;
                        final status = _docStatuses[key] ?? 'Not Submitted';
                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          onTap: widget.onNavigateToUploads,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                              StatusBadge(status: status),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      if (!allDone)
                        AppPrimaryButton(
                          label: 'Go to Upload Documents',
                          icon: Icons.upload_file,
                          onPressed: widget.onNavigateToUploads,
                        )
                      else ...[
                        AppPrimaryButton(
                          label: 'Review documents',
                          icon: Icons.folder_open,
                          onPressed: widget.onNavigateToUploads,
                        ),
                        const SizedBox(height: 12),
                        if (widget.onNavigateToNotifications != null)
                          AppSecondaryButton(
                            label: 'View notifications',
                            icon: Icons.notifications_outlined,
                            onPressed: widget.onNavigateToNotifications,
                          ),
                        if (_verifiedCount ==
                            AppConstants.documentTypeKeys.length) ...[
                          const SizedBox(height: 16),
                          AppCard(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.celebration,
                                  color: AppTheme.successGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'All documents verified. You’re all set!',
                                    style: TextStyle(color: onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

/// Placeholder that mirrors the real home layout (welcome → progress → status rows).
class _DashboardSkeleton extends StatelessWidget {
  final Color muted;

  const _DashboardSkeleton({required this.muted});

  Widget _shimmerBar({double height = 14, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Matches "Welcome back," + name
        Text(
          'Welcome back,',
          style: TextStyle(fontSize: 16, color: muted.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        _shimmerBar(height: 28, width: 180),
        const SizedBox(height: 24),

        // Progress card shell (same gradient + inner layout as loaded state)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.appBarGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryMid.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.bgLight.withValues(alpha: 0.2),
                  color: AppTheme.bgLight.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 13,
                      width: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Document status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface.withValues(alpha: 0.35),
              ),
        ),
        const SizedBox(height: 12),

        // Four status rows — same shape as real document cards
        ...List.generate(AppConstants.documentTypeKeys.length, (_) {
          return AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _shimmerBar(height: 16)),
                const SizedBox(width: 16),
                Container(
                  width: 88,
                  height: 28,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        // CTA button placeholder
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: muted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
