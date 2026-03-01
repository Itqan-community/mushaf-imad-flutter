import 'package:flutter/material.dart';
import 'quran_line_image.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final List<dynamic> verses;
  final List<dynamic> markers;
  final int? highlightedVerseKey;
  final ThemeData themeData;
  final Function(int chapter, int verse)? onVerseTap;
  final Function(int chapter, int verse)? onVerseLongPress;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    required this.verses,
    required this.markers,
    required this.themeData,
    this.highlightedVerseKey,
    this.onVerseTap,
    this.onVerseLongPress,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.themeData;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: 15,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final line = index + 1;

          final versesOnLine =
              widget.verses.where((v) => (v as dynamic).line == line).toList();
          final markersOnLine =
              widget.markers.where((m) => (m as dynamic).line == line).toList();

          final highlights = versesOnLine.where((v) {
            final d = v as dynamic;
            return ((d.chapter * 1000) + d.number) == widget.highlightedVerseKey;
          }).toList();

          return Builder(
            builder: (lineContext) => GestureDetector(
              onLongPressStart: (details) {
                if (widget.onVerseLongPress == null ||
                    versesOnLine.isEmpty) {
                  return;
                }

                final RenderBox box =
                    lineContext.findRenderObject() as RenderBox;
                final localOffset =
                    box.globalToLocal(details.globalPosition);
                final tapRatio =
                    1.0 - (localOffset.dx / box.size.width);

                final target =
                    _resolveVerse(tapRatio, versesOnLine, markersOnLine, line);
                if (target != null) {
                  widget.onVerseLongPress!(
                      target.chapter, target.number);
                }
              },
              child: QuranLineImage(
                page: widget.pageNumber,
                line: line,
                highlights: highlights,
                markers: markersOnLine,
                highlightColor: theme.highlightColor,
                textColor:
                    theme.textTheme.bodyLarge?.color ?? Colors.black,
                onTapUpExact: (tapRatio) {
                  if (widget.onVerseTap == null ||
                      versesOnLine.isEmpty) {
                    return;
                  }
                  final target = _resolveVerse(
                      tapRatio, versesOnLine, markersOnLine, line);
                  if (target != null) {
                    widget.onVerseTap!(
                        target.chapter, target.number);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  dynamic _resolveVerse(double tapRatio, List<dynamic> verses,
      List<dynamic> markers, int line) {
    for (final verse in verses) {
      final d = verse as dynamic;
      final hList =
          d.highlights1441.where((h) => h.line == line);
      for (final h in hList) {
        if (tapRatio >= h.left && tapRatio <= h.right) {
          return d;
        }
      }
    }
    if (markers.isNotEmpty) return markers.last;
    if (verses.isNotEmpty) return verses.last;
    return null;
  }
}
