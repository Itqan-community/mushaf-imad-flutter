import 'package:flutter/material.dart';
import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../../data/quran/verse_data_provider.dart';
import '../theme/reading_theme.dart';
import 'quran_line_image.dart';

/// Renders a single Quran page — 15 line images with a page header.
/// Supports verse-level selection, highlighting, and long-press actions.
class QuranPageWidget extends StatefulWidget {
  final int pageNumber;

  /// Currently selected verse (chapterNumber * 1000 + verseNumber).
  final int? selectedVerseKey;

  /// Called when a verse is tapped (selection).
  final void Function(int chapterNumber, int verseNumber)? onVerseTap;

  /// 🔥 NEW: Called when a verse is long-pressed (e.g. play from verse)
  final void Function(int chapterNumber, int verseNumber)? onVerseLongPress;

  /// Reading theme data for colors.
  final ReadingThemeData? themeData;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    this.selectedVerseKey,
    this.onVerseTap,
    this.onVerseLongPress,
    this.themeData,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  late final QuranDataProvider _dataProvider;
  late List<ChapterData> _chapters;
  late int _juz;

  @override
  void initState() {
    super.initState();
    _dataProvider = QuranDataProvider.instance;
    _updatePageData();
  }

  @override
  void didUpdateWidget(covariant QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _updatePageData();
    }
  }

  void _updatePageData() {
    _chapters = _dataProvider.getChaptersForPage(widget.pageNumber);
    _juz = _dataProvider.getJuzForPage(widget.pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    final verseProvider = VerseDataProvider.instance;
    final pageVerses = verseProvider.getVersesForPage(widget.pageNumber);
    final theme =
        widget.themeData ?? ReadingThemeData.fromTheme(ReadingTheme.light);

    return Container(
      color: theme.backgroundColor,
      child: Column(
        children: [
          _PageHeader(
            chapters: _chapters,
            pageNumber: widget.pageNumber,
            juzNumber: _juz,
            themeData: theme,
          ),

          Container(
            height: 1,
            color: theme.secondaryTextColor.withOpacity(0.3),
          ),

          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: List.generate(15, (index) {
                    final line = index + 1;

                    final markers = pageVerses
                        .where(
                          (v) =>
                              v.marker1441 != null &&
                              v.marker1441!.line == line,
                        )
                        .toList();

                    final versesOnLine = pageVerses
                        .where((v) => v.occupiesLine(line))
                        .toList();

                    final highlights = <VerseHighlightData>[];
                    if (widget.selectedVerseKey != null) {
                      final selectedVerse = versesOnLine
                          .where(
                            (v) =>
                                v.chapter * 1000 + v.number ==
                                widget.selectedVerseKey,
                          )
                          .firstOrNull;

                      if (selectedVerse != null) {
                        highlights.addAll(
                          selectedVerse.highlights1441.where(
                            (h) => h.line == line,
                          ),
                        );
                      }
                    }

                    // ✅ Wrap with GestureDetector to handle Long Press since QuranLineImage doesn't support it natively
                    return Expanded(
                      child: GestureDetector(
                        onLongPressStart: (details) {
                          if (widget.onVerseLongPress == null || versesOnLine.isEmpty) return;
                          
                          // Calculate tap ratio manually for long press
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localOffset = box.globalToLocal(details.globalPosition);
                          final tapRatio = 1.0 - (localOffset.dx / box.size.width);

                          final target = _resolveVerse(tapRatio, versesOnLine, markers, line);
                          widget.onVerseLongPress!(target.chapter, target.number);
                        },
                        child: QuranLineImage(
                          page: widget.pageNumber,
                          line: line,
                          highlights: highlights,
                          markers: markers,
                          highlightColor: theme.highlightColor,
                          textColor: theme.textColor,

                          /// TAP = select verse
                          onTapUpExact: (tapRatio) {
                            if (widget.onVerseTap == null ||
                                versesOnLine.isEmpty) return;

                            final target =
                                _resolveVerse(tapRatio, versesOnLine, markers, line);

                            widget.onVerseTap!(
                                target.chapter, target.number);
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Logic to find which verse was touched based on horizontal position (ratio)
  PageVerseData _resolveVerse(
    double tapRatio,
    List<PageVerseData> versesOnLine,
    List<PageVerseData> markers,
    int line,
  ) {
    for (final verse in versesOnLine) {
      final hList = verse.highlights1441.where((h) => h.line == line);
      for (final h in hList) {
        if (tapRatio >= h.left && tapRatio <= h.right) {
          return verse;
        }
      }
    }
    return markers.isNotEmpty ? markers.last : versesOnLine.last;
  }
}

class _PageHeader extends StatelessWidget {
  final List<ChapterData> chapters;
  final int pageNumber;
  final int juzNumber;
  final ReadingThemeData themeData;

  const _PageHeader({
    required this.chapters,
    required this.pageNumber,
    required this.juzNumber,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final chapterName = chapters.isNotEmpty
        ? chapters.map((c) => c.arabicTitle).join(' - ')
        : '';

    return Container(
      color: themeData.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Text(
              'جزء ${QuranDataProvider.toArabicNumerals(juzNumber)}',
              style: TextStyle(
                fontSize: 13,
                color: themeData.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                chapterName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: themeData.textColor,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeData.secondaryTextColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${QuranDataProvider.toArabicNumerals(pageNumber)} / ٦٠٤',
                style: TextStyle(
                  fontSize: 12,
                  color: themeData.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
