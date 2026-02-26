import 'package:flutter/material.dart';
import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../../data/quran/verse_data_provider.dart';
import '../../domain/models/mushaf_type.dart';
import '../theme/reading_theme.dart';
import 'quran_line_image.dart';

/// Renders a single Quran page with support for multiple Mushaf layouts.
///
/// Supports 1441, 1421, and 1405 Mushaf layouts based on the [mushafType] parameter.
/// Port of the Android QuranPageView composable with verse-level selection.
class MushafPageWidget extends StatefulWidget {
  final int pageNumber;
  final MushafType mushafType;

  /// Currently selected verse (chapterNumber * 1000 + verseNumber).
  /// null means no selection.
  final int? selectedVerseKey;

  /// Called when a verse is tapped. Provides (chapterNumber, verseNumber).
  final void Function(int chapterNumber, int verseNumber)? onVerseTap;

  /// Reading theme data for colors. Defaults to light theme.
  final ReadingThemeData? themeData;

  const MushafPageWidget({
    super.key,
    required this.pageNumber,
    this.mushafType = MushafType.hafs1441,
    this.selectedVerseKey,
    this.onVerseTap,
    this.themeData,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
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
  void didUpdateWidget(covariant MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.mushafType != widget.mushafType) {
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
          // Page header
          _PageHeader(
            chapters: _chapters,
            pageNumber: widget.pageNumber,
            juzNumber: _juz,
            themeData: theme,
          ),

          // Divider
          Container(
            height: 1,
            color: theme.secondaryTextColor.withValues(alpha: 0.3),
          ),

          // 15 line images
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: List.generate(15, (index) {
                    final line = index + 1;

                    // Get markers and verses based on Mushaf type
                    final markers = _getMarkersForLine(pageVerses, line);
                    final versesOnLine = _getVersesOnLine(pageVerses, line);

                    // Calculate highlights based on Mushaf type
                    final highlights = _calculateHighlights(versesOnLine, line);

                    return Expanded(
                      child: QuranLineImage(
                        page: widget.pageNumber,
                        line: line,
                        highlights: highlights,
                        markers: markers,
                        highlightColor: theme.highlightColor,
                        textColor: theme.textColor,
                        onTapUpExact: (tapRatio) {
                          if (widget.onVerseTap == null || versesOnLine.isEmpty)
                            return;

                          _handleVerseTap(versesOnLine, line, tapRatio);
                        },
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

  /// Get markers for a specific line based on Mushaf type.
  List<PageVerseData> _getMarkersForLine(
    List<PageVerseData> pageVerses,
    int line,
  ) {
    final mushafTypeStr = widget.mushafType.name;
    return pageVerses
        .where(
          (v) {
            final marker = v.getMarkerForMushafType(mushafTypeStr);
            return marker != null && marker.line == line;
          },
        )
        .toList();
  }

  /// Get verses on a specific line based on Mushaf type.
  List<PageVerseData> _getVersesOnLine(
    List<PageVerseData> pageVerses,
    int line,
  ) {
    final mushafTypeStr = widget.mushafType.name;
    return pageVerses
        .where((v) {
          final highlights = v.getHighlightsForMushafType(mushafTypeStr);
          return highlights.any((h) => h.line == line);
        })
        .toList();
  }

  /// Calculate highlight regions for the selected verse.
  List<VerseHighlightData> _calculateHighlights(
    List<PageVerseData> versesOnLine,
    int line,
  ) {
    final highlights = <VerseHighlightData>[];
    if (widget.selectedVerseKey != null) {
      final selectedVerse = versesOnLine
          .where(
            (v) => v.chapter * 1000 + v.number == widget.selectedVerseKey,
          )
          .firstOrNull;

      if (selectedVerse != null) {
        final mushafTypeStr = widget.mushafType.name;
        final verseHighlights = selectedVerse.getHighlightsForMushafType(mushafTypeStr);
        highlights.addAll(
          verseHighlights.where((h) => h.line == line),
        );
      }
    }
    return highlights;
  }

  /// Handle verse tap gesture.
  void _handleVerseTap(
    List<PageVerseData> versesOnLine,
    int line,
    double tapRatio,
  ) {
    final mushafTypeStr = widget.mushafType.name;
    PageVerseData? target;

    // 1. Precise hit test against exact verse bounds
    for (final verse in versesOnLine) {
      final hList = verse
          .getHighlightsForMushafType(mushafTypeStr)
          .where((h) => h.line == line);
      for (final h in hList) {
        if (tapRatio >= h.left && tapRatio <= h.right) {
          target = verse;
          break;
        }
      }
      if (target != null) break;
    }

    // 2. Fallback if tapped on empty space or gap between verses
    if (target == null) {
      final markers = _getMarkersForLine(versesOnLine, line);
      target = markers.isNotEmpty ? markers.last : versesOnLine.last;
    }

    if (target != null && widget.onVerseTap != null) {
      widget.onVerseTap!(target.chapter, target.number);
    }
  }
}

/// Page header showing surah name, page number, and juz.
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
            // Juz (right side in RTL)
            Text(
              'جزء ${QuranDataProvider.toArabicNumerals(juzNumber)}',
              style: TextStyle(
                fontSize: 13,
                color: themeData.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Chapter name (center)
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

            // Page number (left side in RTL)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeData.secondaryTextColor.withValues(alpha: 0.15),
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