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
  final List<VerseHighlightData> highlights;
  final VoidCallback? onTap;
  final void Function(double tapRatio)? onTapUpExact;

  /// Verse markers that end on this line (for rendering VerseFasel).
  final List<PageVerseData> markers;

  // Original image aspect ratio: 1440 x 232
  static const double _aspectRatio = 1440.0 / 232.0;

  const QuranLineImage({
    super.key,
    required this.page,
    required this.line,
    this.highlights = const [],
    this.onTap,
    this.onTapUpExact,
    this.markers = const [],
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
                // Highlight background (precise bounding boxes)
                if (highlights.isNotEmpty)
                  ...highlights.map((h) {
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
                          color: const Color(
                            0xFFD4A574,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),

                // Line image — loaded from package assets
                Image.asset(
                  assetPath,
                  package: 'imad_flutter',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),

                // Verse separators (VerseFasel markers)
                if (markers.isNotEmpty) _buildMarkers(lineWidth, lineHeight),
              ],
            );
          },
        ),
      ),
    );
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
