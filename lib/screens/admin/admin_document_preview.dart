import 'package:flutter/material.dart';

/// Colour-coded OCR bounding-box overlay for an admin document image.
///
/// • Green  → text block matched a verified field
/// • Amber  → block partially matches (text contains a field value keyword)
/// • Grey   → extracted but not matched to any verified field
///
/// Admins can toggle highlights on/off and pinch-to-zoom the image.
class AdminDocumentPreview extends StatefulWidget {
  final String fileUrl;
  final Map<String, String> verifiedFields;
  final List<Map<String, dynamic>> ocrBlocks;
  final String documentType;

  const AdminDocumentPreview({
    super.key,
    required this.fileUrl,
    required this.verifiedFields,
    required this.ocrBlocks,
    required this.documentType,
  });

  @override
  State<AdminDocumentPreview> createState() => _AdminDocumentPreviewState();
}

class _AdminDocumentPreviewState extends State<AdminDocumentPreview>
    with SingleTickerProviderStateMixin {
  bool _showHighlights = true;
  bool _showHint = true;
  late final AnimationController _hintController;
  late final Animation<double> _hintFade;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintFade = CurvedAnimation(parent: _hintController, curve: Curves.easeOut);

    // Fade out the "Pinch to zoom" hint after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _hintController.forward().then((_) {
          if (mounted) setState(() => _showHint = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background ──────────────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF0A111F) : const Color(0xFFF5F7FA),
        ),

        // ── Image + Overlay ─────────────────────────────────────────────
        InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Document image
                    Image.network(
                      widget.fileUrl,
                      fit: BoxFit.contain,
                      width: constraints.maxWidth,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFF415A77),
                              ),
                              const SizedBox(height: 12),
                              const Text('Loading document…'),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 64,
                                color: isDark
                                    ? const Color(0xFFB0C4DE)
                                    : const Color(0xFF6B7280)),
                            const SizedBox(height: 12),
                            Text('Could not load image',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),

                    // OCR highlight overlay
                    if (_showHighlights && widget.ocrBlocks.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OcrHighlightPainter(
                            ocrBlocks: widget.ocrBlocks,
                            verifiedFields: widget.verifiedFields,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        // ── Pinch hint ──────────────────────────────────────────────────
        if (_showHint)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(_hintFade),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Pinch to zoom',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Legend + Toggle ─────────────────────────────────────────────
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: const [
                    _LegendChip(color: Color(0xFF10B981), label: 'Verified'),
                    _LegendChip(color: Color(0xFFF59E0B), label: 'Partial'),
                    _LegendChip(color: Color(0xFF94A3B8), label: 'Extracted'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Highlight toggle
              GestureDetector(
                onTap: () => setState(() => _showHighlights = !_showHighlights),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showHighlights
                        ? const Color(0xFF415A77)
                        : Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showHighlights
                          ? const Color(0xFF415A77)
                          : Colors.white38,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showHighlights
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showHighlights ? 'Hide' : 'Show',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// OCR Highlight Painter
// ────────────────────────────────────────────────────────────────────────────

enum _MatchType { verified, partial, extracted }

class _OcrHighlightPainter extends CustomPainter {
  final List<Map<String, dynamic>> ocrBlocks;
  final Map<String, String> verifiedFields;

  _OcrHighlightPainter({
    required this.ocrBlocks,
    required this.verifiedFields,
  });

  static const _verifiedColor = Color(0xFF10B981);
  static const _partialColor = Color(0xFFF59E0B);
  static const _extractedColor = Color(0xFF94A3B8);

  /// Returns the field key name that matches the block text, or null.
  _MatchType _classifyBlock(String blockText) {
    final lowerBlock = blockText.toLowerCase();

    // Check for exact / strong match against any verified field value
    for (final entry in verifiedFields.entries) {
      final val = entry.value.toLowerCase().trim();
      if (val.isEmpty) continue;

      if (lowerBlock.contains(val) || val.contains(lowerBlock.trim())) {
        return _MatchType.verified;
      }
      // Partial: at least one significant word matches
      final words = val.split(RegExp(r'\s+')).where((w) => w.length > 2);
      if (words.any((word) => lowerBlock.contains(word))) {
        return _MatchType.partial;
      }
    }
    return _MatchType.extracted;
  }

  Color _colorFor(_MatchType type) {
    switch (type) {
      case _MatchType.verified:
        return _verifiedColor;
      case _MatchType.partial:
        return _partialColor;
      case _MatchType.extracted:
        return _extractedColor;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final block in ocrBlocks) {
      final left = (block['left'] as num?)?.toDouble() ?? 0;
      final top = (block['top'] as num?)?.toDouble() ?? 0;
      final width = (block['width'] as num?)?.toDouble() ?? 0;
      final height = (block['height'] as num?)?.toDouble() ?? 0;
      final text = (block['text'] as String?) ?? '';

      if (width <= 0 || height <= 0) continue;

      final rect = Rect.fromLTWH(
        left * size.width,
        top * size.height,
        width * size.width,
        height * size.height,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      final matchType = _classifyBlock(text);

      // Skip purely "extracted" blocks to reduce noise — only show verified/partial
      if (matchType == _MatchType.extracted) continue;

      final color = _colorFor(matchType);

      // Fill
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      // Border
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // Label chip above the box
      _drawLabel(canvas, rect, color, _labelFor(matchType));
    }
  }

  String _labelFor(_MatchType type) {
    switch (type) {
      case _MatchType.verified:
        return '✓ VERIFIED';
      case _MatchType.partial:
        return '~ PARTIAL';
      case _MatchType.extracted:
        return 'EXTRACTED';
    }
  }

  void _drawLabel(Canvas canvas, Rect blockRect, Color color, String label) {
    const fontSize = 9.0;
    const paddingH = 5.0;
    const paddingV = 2.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final chipW = textPainter.width + paddingH * 2;
    final chipH = textPainter.height + paddingV * 2;

    // Position chip just above the block, clamped into canvas bounds
    double chipLeft = blockRect.left;
    double chipTop = blockRect.top - chipH - 2;
    if (chipTop < 0) chipTop = blockRect.top + 2;
    if (chipLeft + chipW > blockRect.right) {
      chipLeft = blockRect.right - chipW;
    }
    if (chipLeft < 0) chipLeft = 0;

    final chipRect = Rect.fromLTWH(chipLeft, chipTop, chipW, chipH);
    final chipRRect =
        RRect.fromRectAndRadius(chipRect, const Radius.circular(3));

    canvas.drawRRect(chipRRect, Paint()..color = color);
    textPainter.paint(
        canvas, Offset(chipLeft + paddingH, chipTop + paddingV));
  }

  @override
  bool shouldRepaint(_OcrHighlightPainter old) =>
      old.ocrBlocks != ocrBlocks ||
      old.verifiedFields != verifiedFields;
}

// ────────────────────────────────────────────────────────────────────────────
// Legend chip
// ────────────────────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
