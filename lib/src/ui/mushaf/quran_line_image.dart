import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/verse_data_provider.dart';
import '../../domain/models/mushaf_type.dart';
import 'verse_fasel.dart';

/// Displays a single Quran line image loaded from the active Mushaf's
/// configured [ImageProvider].
///
/// Supports verse-level highlighting and renders [VerseFasel] markers
/// at positions where verse separators appear.
class QuranLineImage extends StatelessWidget {
  final int page;
  final int line;
  final List<VerseHighlightData> audioHighlights;
  final Color? audioHighlightsColor;
  final List<VerseHighlightData> selectionHighlights;
  final VoidCallback? onTap;
  final Color? highlightColor;
  final Color? textColor;
  final void Function(double tapRatio)? onTapUpExact;
  final List<PageVerseData> markers;

  /// The image provider that supplies this line. Defaults to the built-in
  /// Hafs 1441 bundled asset provider.
  final ImageProvider? imageProvider;

  /// The active Mushaf type — used to resolve which marker field to read
  /// from [PageVerseData] when rendering verse separators.
  final MushafType mushafType;

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
    this.imageProvider,
    this.mushafType = MushafType.hafs1441,
  });

  @override
  Widget build(BuildContext context) {
    final provider =
        imageProvider ?? QuranDataProvider.getLineImageProvider(page, line);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        if (onTapUpExact != null) {
          final box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final tapRatio = localPosition.dx / box.size.width;
          onTapUpExact!(tapRatio);
        } else if (onTap != null) {
          onTap!();
        }
      },
      onTap: () {
        // Need to define onTap so this GestureDetector wins the gesture arena
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
                ..._buildSelectionHighlights(lineWidth),
                ..._buildAudioHighlights(provider),
                if (markers.isNotEmpty) _buildMarkers(lineWidth, lineHeight),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _image({
    required ImageProvider provider,
    Color? color,
    BlendMode? colorBlendMode,
  }) => Image(
    image: provider,
    fit: BoxFit.contain,
    color: color ?? textColor,
    colorBlendMode:
        colorBlendMode ?? (textColor != null ? BlendMode.srcIn : null),
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
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _buildAudioHighlights(ImageProvider provider) {
    if (audioHighlights.isEmpty) {
      return [_image(provider: provider)];
    }

    return audioHighlights.map((h) {
      return Stack(
        children: [
          ClipRect(
            clipper: _VerseClipper(0, h.left),
            child: _image(provider: provider),
          ),
          ClipRect(
            clipper: _VerseClipper(h.left, h.right),
            child: _image(
              provider: provider,
              color: audioHighlightsColor ?? Colors.blue,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          ClipRect(
            clipper: _VerseClipper(h.right, 1),
            child: _image(provider: provider),
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSelectionHighlights(double lineWidth) {
    if (selectionHighlights.isEmpty) return [];

    return selectionHighlights.map((h) {
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

  Widget _buildMarkers(double lineWidth, double lineHeight) {
    return Stack(
      children: markers.asMap().entries.map((entry) {
        final verse = entry.value;
        final markerNode = verse.getMarker(mushafType);

        if (markerNode == null) return const SizedBox.shrink();

        final markerX = lineWidth * (markerNode.centerX);
        final markerY = lineHeight * markerNode.centerY;
        final markerSize = lineWidth * 0.07;
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
  bool shouldReclip(_VerseClipper oldClipper) =>
      oldClipper.leftRatio != leftRatio || oldClipper.rightRatio != rightRatio;
}
