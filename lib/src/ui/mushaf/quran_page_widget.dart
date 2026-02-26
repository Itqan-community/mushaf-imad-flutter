import 'package:flutter/material.dart';
// ⚠️ السطر ده هو مفتاح الحل، تأكد من مسار الملف الصحيح في مشروعك
import '../../domain/models/page_verse_data.dart'; 
import 'quran_line_image.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final List<PageVerseData> verses; // الآن سيعرف أن لها line و chapter
  final List<PageVerseData> markers;
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
          
          // هنا Dart سيفهم الـ v والـ m لأننا حددنا النوع في الـ List فوق
          final versesOnLine = widget.verses.where((v) => v.line == line).toList();
          final markersOnLine = widget.markers.where((m) => m.line == line).toList();
          
          final highlights = versesOnLine
              .where((v) => (v.chapter * 1000 + v.number) == widget.highlightedVerseKey)
              .toList();

          return Builder(
            builder: (lineContext) => GestureDetector(
              onLongPressStart: (details) {
                if (widget.onVerseLongPress == null || versesOnLine.isEmpty) return;

                final RenderBox box = lineContext.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.globalPosition);
                final tapRatio = 1.0 - (localOffset.dx / box.size.width);

                final target = _resolveVerse(tapRatio, versesOnLine, markersOnLine, line);
                if (target != null) {
                  widget.onVerseLongPress!(target.chapter, target.number);
                }
              },
              child: QuranLineImage(
                page: widget.pageNumber,
                line: line,
                highlights: highlights,
                markers: markersOnLine,
                highlightColor: theme.highlightColor,
                textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
                onTapUpExact: (tapRatio) {
                  if (widget.onVerseTap == null || versesOnLine.isEmpty) return;
                  final target = _resolveVerse(tapRatio, versesOnLine, markersOnLine, line);
                  if (target != null) {
                    widget.onVerseTap!(target.chapter, target.number);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // تحديد النوع هنا يمنع خطأ "PageVerseData isn't a type"
  PageVerseData? _resolveVerse(double tapRatio, List<PageVerseData> verses, List<PageVerseData> markers, int line) {
    for (final verse in verses) {
      final hList = verse.highlights1441.where((h) => h.line == line);
      for (final h in hList) {
        if (tapRatio >= h.left && tapRatio <= h.right) return verse;
      }
    }
    return markers.isNotEmpty ? markers.last : (verses.isNotEmpty ? verses.last : null);
  }
}
