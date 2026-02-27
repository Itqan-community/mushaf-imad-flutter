import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/verse_data_provider.dart';
import 'verse_fasel.dart';

/// Displays a single Quran line image loaded from assets.
///
/// Images are stored in assets/quran-images/{page}/{line}.png
/// Original dimensions: 1440 x 232 pixels
/// Each page has 15 lines (1-15).
///
/// Supports verse-level highlighting and renders VerseFasel markers
/// at positions where verse separators appear.
class QuranLineImage extends StatelessWidget {
  final int page;
  final int line;
  final List<VerseHighlightData> audioHighlights;

  final Color? audioHighlightsColor;

  final List<VerseHighlightData> selectionHighlights;

  final VoidCallback? onTap;

  /// Optional highlight color — defaults to gold if not provided.
  final Color? highlightColor;

  /// Optional text color — when provided, tints the line image so text
  /// contrasts against dark backgrounds (uses BlendMode.srcIn).
  final Color? textColor;
  final void Function(double tapRatio)? onTapUpExact;

  /// Verse markers that end on this line (for rendering VerseFasel).
  final List<PageVerseData> markers;

  // Original image aspect ratio: 1440 x 232
  static const double _aspectRatio = 1440.0 / 232.0;

  const QuranLineImage({
    super.key,
    required this.page,
    required this.line,
    this.audioHighlights = const [],
    this.audioHighlightsColor,
    this.selectionHighlights = const [],
    this.onTap,
    this.onTapUpExact,
    this.markers = const [],
    this.highlightColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = QuranDataProvider.getLineImagePath(page, line);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (onTapUpExact != null) {
          final box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          // `localPosition.dx` is 0 at the physical left edge and `width` at the right edge.
          // Since we render highlights purely left-to-right based on `h.left` and `h.right`,
          // our tap ratio matches exactly.
          final tapRatio = localPosition.dx / box.size.width;
          onTapUpExact!(tapRatio);
        } else if (onTap != null) {
          onTap!();
        }
      },
      onTap: () {
        // Need to define onTap so this GestureDetector wins the gesture arena
        // against the parent MushafPageView's onTap (which toggles controls).
      },
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lineWidth = constraints.maxWidth;
            final lineHeight = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 👆 Selection Highlight background (precise bounding boxes)
                ..._buildSelectionHighlights(lineWidth),

                // 🎧 Audio Highlight (animated fill)
                ..._buildAudioHighlights(assetPath, lineWidth),

                // Verse separators (VerseFasel markers)
                if (markers.isNotEmpty) _buildMarkers(lineWidth, lineHeight),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAudioHighlights(String assetPath, double lineWidth) {
    if (audioHighlights.isEmpty) {
      return [
        Image.asset(
          assetPath,
          package: 'imad_flutter',
          fit: BoxFit.contain,
          color: textColor,
          colorBlendMode: textColor != null ? BlendMode.srcIn : null,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '⚠️ Missing quran-images/\n'
                  'Download from: github.com/Itqan-community/mushaf-imad-flutter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          },
        ),
      ];
    }

    return audioHighlights.map((h) {
      return Stack(
        children: [
          ClipRect(
            clipper: _VerseClipper(0, h.left),
            child: Image.asset(
              assetPath,
              package: 'imad_flutter',
              fit: BoxFit.contain,
              color: textColor,
              colorBlendMode: textColor != null ? BlendMode.srcIn : null,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '⚠️ Missing quran-images/\n'
                      'Download from: github.com/Itqan-community/mushaf-imad-flutter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ClipRect(
            clipper: _VerseClipper(h.left, h.right),
            child: Image.asset(
              assetPath,
              package: 'imad_flutter',
              fit: BoxFit.contain,
              color: audioHighlightsColor ?? Colors.blue,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '⚠️ Missing quran-images/\n'
                      'Download from: github.com/Itqan-community/mushaf-imad-flutter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ClipRect(
            clipper: _VerseClipper(h.right, 1),
            child: Image.asset(
              assetPath,
              package: 'imad_flutter',
              fit: BoxFit.contain,
              color: textColor,
              colorBlendMode: textColor != null ? BlendMode.srcIn : null,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '⚠️ Missing quran-images/\n'
                      'Download from: github.com/Itqan-community/mushaf-imad-flutter',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSelectionHighlights(double lineWidth) {
    if (selectionHighlights.isEmpty) return [];

    return selectionHighlights.map((h) {
      // `h.left` and `h.right` are physical coordinates (0.0 = left edge, 1.0 = right edge)
      final leftPos = lineWidth * h.left;
      final width = lineWidth * (h.right - h.left);

      return Positioned(
        left: leftPos,
        width: width,
        top: 0,
        bottom: 0,
        child: Container(
          decoration: BoxDecoration(
            color: (highlightColor ?? const Color(0xFFD4A574)).withValues(
              alpha: 0.25,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }).toList();
  }

  /// Build verse separator markers positioned on this line.
  Widget _buildMarkers(double lineWidth, double lineHeight) {
    return Stack(
      children: markers.asMap().entries.map((entry) {
        final verse = entry.value;
        final markerNode = verse.marker1441;

        if (markerNode == null) return const SizedBox.shrink();

        final markerX = lineWidth * (markerNode.centerX);
        final markerY = lineHeight * markerNode.centerY;

        // Size the marker (Android uses 3.5% of total width * 2)
        // 0.035 * 2 = 0.07 of container width. That's approx the right size.
        final markerSize = lineWidth * 0.07;

        // Center the marker at (markerX, markerY)
        final adjustedX = markerX - (markerSize / 2);
        final adjustedY = markerY - (markerSize / 2);

        return Positioned(
          left: adjustedX,
          top: adjustedY,
          child: VerseFasel(number: verse.number, size: markerSize),
        );
      }).toList(),
    );
  }
}

class _VerseClipper extends CustomClipper<Rect> {
  final double leftRatio;
  final double rightRatio;

  _VerseClipper(this.leftRatio, this.rightRatio);

  @override
  Rect getClip(Size size) {
    final left = size.width * leftRatio;
    final right = size.width * rightRatio;

    return Rect.fromLTRB(left, 0, right, size.height);
  }

  @override
  bool shouldReclip(_VerseClipper oldClipper) {
    return oldClipper.leftRatio != leftRatio ||
        oldClipper.rightRatio != rightRatio;
  }
}
