import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../../data/quran/verse_data_provider.dart';
import '../theme/reading_theme.dart';
import 'quran_line_image.dart';

/// Renders a single Quran page — 15 line images with a page header.
///
/// Port of the Android QuranPageView composable.
/// Supports verse-level selection and highlighting.
class QuranPageWidget extends StatefulWidget {
  final int pageNumber;

  /// Currently selected verse (chapterNumber * 1000 + verseNumber).
  /// null means no selection.
  final int? selectedVerseKey;
  final int? audioVerseKey;
  final Color? audioHighlightsColor;

  /// Called when a verse is tapped. Provides (chapterNumber, verseNumber).
  final void Function(int chapterNumber, int verseNumber)? onVerseTap;

  /// Reading theme data for colors. Defaults to light theme.
  final ReadingThemeData? themeData;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    this.selectedVerseKey,
    this.audioVerseKey,
    this.audioHighlightsColor,
    this.onVerseTap,
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

                    // Find markers ending on this line
                    final markers = pageVerses
                        .where(
                          (v) =>
                              v.marker1441 != null &&
                              v.marker1441!.line == line,
                        )
                        .toList();

                    // Find verses that occupy this line
                    final versesOnLine = pageVerses
                        .where((v) => v.occupiesLine(line))
                        .toList();

                    // Selection highlights
                    final selectionHighlights = <VerseHighlightData>[];

                    if (widget.selectedVerseKey != null) {
                      final selectedVerse = versesOnLine
                          .where(
                            (v) =>
                                v.chapter * 1000 + v.number ==
                                widget.selectedVerseKey,
                          )
                          .firstOrNull;

                      if (selectedVerse != null) {
                        selectionHighlights.addAll(
                          selectedVerse.highlights1441.where(
                            (h) => h.line == line,
                          ),
                        );
                      }
                    }

                    // Audio highlights
                    final audioHighlights = <VerseHighlightData>[];

                    if (widget.audioVerseKey != null) {
                      final audioVerse = versesOnLine
                          .where(
                            (v) =>
                                v.chapter * 1000 + v.number ==
                                widget.audioVerseKey,
                          )
                          .firstOrNull;

                      if (audioVerse != null) {
                        audioHighlights.addAll(
                          audioVerse.highlights1441.where(
                            (h) => h.line == line,
                          ),
                        );
                      }
                    }

                    return Expanded(
                      child: QuranLineImage(
                        page: widget.pageNumber,
                        line: line,
                        audioHighlights: audioHighlights
                            .where((h) => h.line == line)
                            .toList(),
                        audioHighlightsColor: widget.audioHighlightsColor,
                        selectionHighlights: selectionHighlights,
                        markers: markers,
                        highlightColor: theme.highlightColor,

                        textColor: theme.textColor,
                        onTapUpExact: (tapRatio) {
                          if (widget.onVerseTap == null || versesOnLine.isEmpty)
                            return;

                          PageVerseData? target;

                          // 1. Precise hit test against exact verse bounds
                          for (final verse in versesOnLine) {
                            final hList = verse.highlights1441.where(
                              (h) => h.line == line,
                            );
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
                            target = markers.isNotEmpty
                                ? markers.last
                                : versesOnLine.last;
                          }

                          print(
                            "Calling onVerseTap with chapter: ${target?.chapter}, verse: ${target?.number}",
                          );
                          widget.onVerseTap!(target!.chapter, target.number);
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
