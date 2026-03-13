import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_document_preview.dart';

class SubmissionPopup extends StatefulWidget {
  final Submission submission;
  final VoidCallback onClose;
  final Function(Submission, String) onUpdateStatus;

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

  @override
  void initState() {
    super.initState();
    final hasImage =
        (widget.submission.details['fileUrl'] as String?)?.isNotEmpty == true;
    _tabController = TabController(
      length: 2,
      vsync: this,
      // Land on Document tab if image exists, Details otherwise
      initialIndex: hasImage ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B263B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF2A3A5A) : const Color(0xFFF5F7FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1B263B);
    final textSecondary =
        isDark ? const Color(0xFFB0C4DE) : const Color(0xFF6B7280);

    final fileUrl =
        (widget.submission.details['fileUrl'] as String?) ?? '';
    final hasImage = fileUrl.isNotEmpty;

    final rawBlocks =
        widget.submission.details['ocrBlocks'] as List<dynamic>? ?? [];
    final ocrBlocks = rawBlocks
        .where((b) => b is Map)
        .map((b) => (b as Map).map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    return Stack(
      children: [
        // ── Scrim ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black54),
        ),

        // ── Popup card ───────────────────────────────────────────────────
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF415A77), Color(0xFF1B263B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submitted by ${widget.submission.name}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),

                  // ── Status + Similarity strip ──────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF415A77), Color(0xFF1B263B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        _statusPill(
                            widget.submission.status,
                            _getStatusColor(widget.submission.status)),
                        const SizedBox(width: 12),
                        _similarityPill(widget.submission.similarity),
                      ],
                    ),
                  ),

                  // ── TabBar ─────────────────────────────────────────────
                  Container(
                    color: isDark
                        ? const Color(0xFF1B263B)
                        : const Color(0xFFF5F7FA),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF415A77),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF415A77),
                      unselectedLabelColor: textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
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
                      ],
                    ),
                  ),

                  // ── Tab content ────────────────────────────────────────
                  Flexible(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ─── Document tab ───────────────────────────────
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
                            : _buildNoImagePlaceholder(
                                isDark, textSecondary),

                        // ─── Details tab ────────────────────────────────
                        _buildDetailsTab(cardBg, textPrimary, textSecondary),
                      ],
                    ),
                  ),

                  // ── Action buttons ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: 'Verify',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF10B981),
                            onPressed: () =>
                                widget.onUpdateStatus(
                                    widget.submission, 'Verified'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            label: 'Reject',
                            icon: Icons.cancel_outlined,
                            color: const Color(0xFFEF4444),
                            onPressed: () =>
                                widget.onUpdateStatus(
                                    widget.submission, 'Rejected'),
                          ),
                        ),
                      ],
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

  // ── Details tab ────────────────────────────────────────────────────────────
  Widget _buildDetailsTab(Color cardBg, Color textPrimary, Color textSecondary) {
    if (widget.submission.verifiedFields.isEmpty) {
      return Center(
        child: Text(
          'No verified field data available.',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified Fields',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.submission.verifiedFields.entries.map((entry) {
            final displayKey = entry.key
                .replaceAll(RegExp(r'([A-Z])'), ' \$1')
                .trim()
                .toUpperCase();

            String displayValue = entry.value;
            if (entry.key == 'aadharNumber' || entry.key == 'voterId') {
              displayValue =
                  '**** **** ${entry.value.substring(entry.value.length - 4)}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      displayKey,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF415A77),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      displayValue,
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── No-image placeholder ───────────────────────────────────────────────────
  Widget _buildNoImagePlaceholder(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 64,
              color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No document image available',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Image will appear for new uploads.',
            style: TextStyle(
                color: textSecondary.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _statusPill(String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _similarityPill(double similarity) {
    final color = _getSimilarityColor(similarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${similarity.toStringAsFixed(1)}% match',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        textStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity >= 80) return const Color(0xFF10B981);
    if (similarity >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}