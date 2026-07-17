import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/ui/ui.dart';
import '/utils/admin_theme.dart';
import '/utils/theme.dart';
import 'admin_document_preview.dart';
import 'submission_model.dart';

typedef SubmissionStatusCallback = void Function(
  Submission submission,
  String newStatus, {
  String? rejectionReason,
});

class SubmissionPopup extends StatefulWidget {
  final Submission submission;
  final VoidCallback onClose;
  final SubmissionStatusCallback onUpdateStatus;

  const SubmissionPopup({
    super.key,
    required this.submission,
    required this.onClose,
    required this.onUpdateStatus,
  });

  @override
  State<SubmissionPopup> createState() => _SubmissionPopupState();
}

class _SubmissionPopupState extends State<SubmissionPopup>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _duplicateSummary;
  bool _dupLoading = false;

  /// Session cache: hash → warning text (or empty string = checked, no dup).
  /// Avoids re-querying collectionGroup on every reopen (ADM-05).
  static final Map<String, String> _duplicateCache = {};

  @override
  void initState() {
    super.initState();
    final hasImage =
        (widget.submission.details['fileUrl'] as String?)?.isNotEmpty == true;
    final hasHistory = widget.submission.history.isNotEmpty;
    _tabController = TabController(
      length: hasHistory ? 3 : 2,
      vsync: this,
      initialIndex: hasImage ? 0 : 1,
    );
    // Defer so first frame paints before optional network check.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDuplicates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Silent duplicate check — Aadhaar / Voter only; cached; no noise when clean.
  Future<void> _loadDuplicates() async {
    final type = widget.submission.documentType.toLowerCase();
    final isIdDoc = type.contains('aadhar') ||
        type.contains('aadhaar') ||
        type.contains('voter');
    if (!isIdDoc) return;

    final hash = (widget.submission.details['aadharHash'] as String?) ??
        (widget.submission.details['documentNumberHash'] as String?);
    if (hash == null || hash.isEmpty) return;

    final cacheKey = '$hash|${widget.submission.userId}';
    if (_duplicateCache.containsKey(cacheKey)) {
      final cached = _duplicateCache[cacheKey]!;
      setState(() {
        _duplicateSummary = cached.isEmpty ? null : cached;
        _dupLoading = false;
      });
      return;
    }

    setState(() => _dupLoading = true);
    try {
      final field = widget.submission.details['aadharHash'] != null
          ? 'aadharHash'
          : 'documentNumberHash';
      final snap = await FirebaseFirestore.instance
          .collectionGroup('uploads')
          .where(field, isEqualTo: hash)
          .limit(10)
          .get();

      final others = snap.docs.where((d) {
        final path = d.reference.path.split('/');
        final uid = path.length > 1 ? path[1] : '';
        return uid != widget.submission.userId && d.id != widget.submission.id;
      }).toList();

      final summary = others.isEmpty
          ? ''
          : 'Possible duplicate — same document number on ${others.length} other student upload(s).';
      _duplicateCache[cacheKey] = summary;

      if (!mounted) return;
      setState(() {
        _duplicateSummary = summary.isEmpty ? null : summary;
        _dupLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _duplicateSummary = null;
        _dupLoading = false;
      });
    }
  }

  Future<void> _confirmReject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject document'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: FormStyles.decoration(
            ctx,
            hintText: 'Reason (optional but recommended)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    widget.onUpdateStatus(
      widget.submission,
      'Rejected',
      rejectionReason: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AdminTheme.of(context);
    final bgColor = t.card;
    final cardBg = t.cardInset;
    final textPrimary = t.textPrimary;
    final textSecondary = t.textMuted;

    final fileUrl = (widget.submission.details['fileUrl'] as String?) ?? '';
    final hasImage = fileUrl.isNotEmpty;
    final hasHistory = widget.submission.history.isNotEmpty;

    final rawBlocks =
        widget.submission.details['ocrBlocks'] as List<dynamic>? ?? [];
    final ocrBlocks = rawBlocks
        .whereType<Map>()
        .map((b) => b.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: t.cardShadow,
              ),
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.appBarGradient,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.submission.documentType,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.bgLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submitted by ${widget.submission.name}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (widget.submission.autoVerified)
                                    _chip('OCR match', AppTheme.successGreen),
                                  if (hasHistory)
                                    _chip(
                                      '${widget.submission.history.length} prior',
                                      AppTheme.accentBlue,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Close',
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.appBarGradient,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        StatusBadge(
                          status: widget.submission.status,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        _similarityPill(widget.submission.similarity),
                      ],
                    ),
                  ),
                  Container(
                    color: t.cardInset,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: t.tabSelected,
                      indicatorWeight: 3,
                      labelColor: t.tabSelected,
                      unselectedLabelColor: t.tabUnselected,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(
                          icon: Icon(
                            hasImage
                                ? Icons.image_outlined
                                : Icons.image_not_supported_outlined,
                            size: 18,
                          ),
                          text: 'Document',
                        ),
                        const Tab(
                          icon: Icon(Icons.list_alt_outlined, size: 18),
                          text: 'Details',
                        ),
                        if (hasHistory)
                          const Tab(
                            icon: Icon(Icons.history, size: 18),
                            text: 'History',
                          ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        hasImage
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: AdminDocumentPreview(
                                  fileUrl: fileUrl,
                                  verifiedFields:
                                      widget.submission.verifiedFields,
                                  ocrBlocks: ocrBlocks,
                                  documentType:
                                      widget.submission.documentType,
                                ),
                              )
                            : _buildNoImagePlaceholder(textSecondary),
                        _buildDetailsTab(cardBg, textPrimary, textSecondary),
                        if (hasHistory)
                          _buildHistoryTab(cardBg, textPrimary, textSecondary),
                      ],
                    ),
                  ),
                  // ADM-UI-07: only offer decisions while Pending.
                  if (widget.submission.status == 'Pending')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'Verify',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.successGreen,
                              onPressed: () => widget.onUpdateStatus(
                                widget.submission,
                                'Verified',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              label: 'Reject',
                              icon: Icons.cancel_outlined,
                              color: AppTheme.errorRed,
                              onPressed: _confirmReject,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: t.cardInset,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.outline),
                        ),
                        child: Text(
                          'This submission is already ${widget.submission.status.toLowerCase()}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: t.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailsTab(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    final d = widget.submission.details;
    final rows = _reviewRows(d);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_dupLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (_duplicateSummary != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningAmber.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningAmber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _duplicateSummary!,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Review info',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              'No extra details for this submission.',
              style: TextStyle(color: textSecondary),
            )
          else
            ...rows.map((e) => _kvRow(cardBg, e.key, e.value, textPrimary)),
        ],
      ),
    );
  }

  /// Curated rows for reviewers — no hashes, UIDs, or raw dump.
  List<MapEntry<String, String>> _reviewRows(Map<String, dynamic> d) {
    final rows = <MapEntry<String, String>>[];

    void add(String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isEmpty || v == '—') return;
      rows.add(MapEntry(label, v));
    }

    add('Student', widget.submission.name);
    add(
      'Email',
      (d['studentEmail'] as String?) ?? widget.submission.email,
    );

    final quality = d['imageQuality']?.toString();
    if (quality != null && quality.isNotEmpty) {
      add('Image quality', quality);
    }

    final last4 = d['aadharLast4']?.toString();
    if (last4 != null && last4.isNotEmpty) {
      add('Aadhaar (last 4)', '**** **** $last4');
    }

    final reason = d['rejectionReason']?.toString();
    if (reason != null && reason.trim().isNotEmpty) {
      add('Rejection reason', reason.trim());
    }

    // Prefer verified/OCR-matched fields (already redacted).
    final shownKeys = <String>{};
    for (final entry in widget.submission.verifiedFields.entries) {
      final label = _humanFieldLabel(entry.key);
      var value = entry.value.trim();
      if (value.isEmpty) continue;
      if (_isSensitiveIdField(entry.key) && value.length >= 4) {
        value = '**** **** ${value.substring(value.length - 4)}';
      }
      add(label, value);
      shownKeys.add(entry.key.toLowerCase());
    }

    // A few useful form fields if not already covered by OCR matches.
    const formAllow = {
      'fullName': 'Full name',
      'name': 'Name',
      'fatherName': 'Father name',
      'motherName': 'Mother name',
      'dateOfBirth': 'Date of birth',
      'dob': 'Date of birth',
      'gender': 'Gender',
      'address': 'Address',
      'board': 'Board',
      'rollNumber': 'Roll number',
      'yearOfPassing': 'Year of passing',
      'percentage': 'Percentage',
      'schoolName': 'School',
      'voterIdLast4': 'Voter ID (last 4)',
    };

    for (final e in formAllow.entries) {
      if (shownKeys.contains(e.key.toLowerCase())) continue;
      final raw = d[e.key];
      if (raw == null) continue;
      if (raw is Map || raw is List) continue;
      final text = raw.toString().trim();
      if (text.isEmpty) continue;
      // Skip if it looks like a hash / technical id.
      if (_looksTechnical(e.key, text)) continue;
      add(e.value, text);
    }

    return rows;
  }

  bool _isSensitiveIdField(String key) {
    final k = key.toLowerCase();
    return k.contains('aadhar') ||
        k.contains('aadhaar') ||
        k.contains('voter') ||
        k.contains('documentnumber');
  }

  bool _looksTechnical(String key, String value) {
    final k = key.toLowerCase();
    if (k.contains('hash') ||
        k.contains('userid') ||
        k == 'userid' ||
        k.contains('uploadid') ||
        k.contains('fileurl') ||
        k.contains('ocr') ||
        k.contains('similarity') ||
        k.contains('sharpness') ||
        k.contains('autoverified') ||
        k.contains('status') ||
        k.contains('documenttype') ||
        k.contains('studentname') ||
        k.contains('studentemail')) {
      return true;
    }
    // Long hex-ish blobs
    if (value.length >= 32 && RegExp(r'^[a-f0-9]+$', caseSensitive: false).hasMatch(value)) {
      return true;
    }
    return false;
  }

  String _humanFieldLabel(String key) {
    const map = {
      'aadharNumber': 'Aadhaar',
      'aadhaarNumber': 'Aadhaar',
      'voterId': 'Voter ID',
      'fullName': 'Full name',
      'name': 'Name',
      'fatherName': 'Father name',
      'motherName': 'Mother name',
      'dateOfBirth': 'Date of birth',
      'dob': 'Date of birth',
      'gender': 'Gender',
      'address': 'Address',
      'board': 'Board',
      'rollNumber': 'Roll number',
      'yearOfPassing': 'Year of passing',
      'percentage': 'Percentage',
      'schoolName': 'School',
    };
    if (map.containsKey(key)) return map[key]!;
    // camelCase → words
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .replaceAll('_', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  Widget _buildHistoryTab(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    final items = widget.submission.history;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final h = items[i];
        final when = h.submittedAt.toDate().toLocal();
        final whenLabel =
            '${when.day}/${when.month}/${when.year} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              StatusBadge(status: h.status, fontSize: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whenLabel,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                    if (h.similarity > 0)
                      Text(
                        '${h.similarity.toStringAsFixed(0)}% match',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kvRow(
    Color cardBg,
    String key,
    String value,
    Color textPrimary,
  ) {
    final labelColor = AdminTheme.of(context).labelAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No document image available',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _similarityPill(double similarity) {
    final color = _similarityColor(similarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '${similarity.toStringAsFixed(1)}% match',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _similarityColor(double similarity) {
    if (similarity >= 80) return AppTheme.successGreen;
    if (similarity >= 60) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }
}
