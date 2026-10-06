import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../../data/quran/verse_data_provider.dart';
import '../../domain/models/line_compactness.dart';
import '../../domain/models/mushaf_config.dart';
import '../../domain/models/mushaf_type.dart';
import '../theme/reading_theme.dart';
import 'quran_line_image.dart';

/// Renders a single Quran page — 15 line images with a page header.
class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final int? selectedVerseKey;
  final int? audioVerseKey;
  final Color? audioHighlightsColor;
  final void Function(PageVerseData verse)? onVerseTap;
  final ReadingThemeData? themeData;

  /// The active Mushaf type — determines marker/highlight field selection
  /// and image provider resolution. Defaults to hafs1441.
  final MushafType mushafType;

  /// Defines line spacing and compactness across the page.
  /// Defaults to [LineCompactness.normal].
  final LineCompactness lineCompactness;

  /// Custom padding around the page lines.
  /// If null, defaults to `EdgeInsets.symmetric(horizontal: 8, vertical: 4)`.
  final EdgeInsetsGeometry? pagePadding;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    this.selectedVerseKey,
    this.audioVerseKey,
    this.audioHighlightsColor,
    this.onVerseTap,
    this.themeData,
    this.mushafType = MushafType.hafs1441,
    this.lineCompactness = LineCompactness.normal,
    this.pagePadding,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  late final QuranDataProvider _dataProvider;
  late List<ChapterData> _chapters;
  late int _juz;
  late MushafConfig _mushafConfig;

  @override
  void initState() {
    super.initState();
    _dataProvider = QuranDataProvider.instance;
    _refreshConfig();
    _updatePageData();
  }

  @override
  void didUpdateWidget(covariant QuranPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _updatePageData();
    }
    if (oldWidget.mushafType != widget.mushafType) {
      _refreshConfig();
    }
  }

  void _refreshConfig() {
    _mushafConfig = MushafConfigRegistry.configFor(widget.mushafType);
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
    final mushafType = widget.mushafType;

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
            color: theme.secondaryTextColor.withValues(alpha: 0.3),
          ),

          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: widget.pagePadding ??
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: widget.lineCompactness.isExpanded
                    ? _buildExpandedLines(
                        pageVerses: pageVerses,
                        mushafType: mushafType,
                        theme: theme,
                      )
                    : _buildCompactLines(
                        pageVerses: pageVerses,
                        mushafType: mushafType,
                        theme: theme,
                        compactness: widget.lineCompactness,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLines({
    required List<PageVerseData> pageVerses,
    required MushafType mushafType,
    required ReadingThemeData theme,
  }) {
    return Column(
      children: List.generate(15, (index) {
        final line = index + 1;
        return Expanded(
          child: _buildLineWidget(
            line: line,
            pageVerses: pageVerses,
            mushafType: mushafType,
            theme: theme,
          ),
        );
      }),
    );
  }

  Widget _buildCompactLines({
    required List<PageVerseData> pageVerses,
    required MushafType mushafType,
    required ReadingThemeData theme,
    required LineCompactness compactness,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const lineCount = 15;
        const lineAspectRatio = 1440.0 / 232.0;
        final factor = (compactness.spacingFactor ?? 0.85).clamp(
          0.20,
          2.0,
        );
        final effectiveLineCount = (lineCount - 1) * factor + 1.0;

        final availWidth = constraints.maxWidth;
        final availHeight = constraints.maxHeight;

        if (availWidth <= 0 || availHeight <= 0) {
          return const SizedBox.shrink();
        }

        final maxLineWidthFromHeight =
            availHeight * lineAspectRatio / effectiveLineCount;
        final lineWidth = availWidth < maxLineWidthFromHeight
            ? availWidth
            : maxLineWidthFromHeight;
        final lineHeight = lineWidth / lineAspectRatio;
        final step = lineHeight * factor;
        final totalContentHeight = (lineCount - 1) * step + lineHeight;

        return Center(
          child: SizedBox(
            width: lineWidth,
            height: totalContentHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(lineCount, (index) {
                final line = index + 1;
                // When line images overlap (factor < 1.0), transparent borders of later lines
                // would intercept taps intended for earlier lines in the Z-order.
                // _LineHitTestScope ignores hits on the upper overlapping half of later lines,
                // allowing taps to cleanly fall through to the preceding line.
                final topCutoff = index == 0
                    ? 0.0
                    : ((lineHeight - step) / 2).clamp(0.0, lineHeight);

                return Positioned(
                  top: index * step,
                  left: 0,
                  width: lineWidth,
                  height: lineHeight,
                  child: _LineHitTestScope(
                    topCutoff: topCutoff,
                    child: _buildLineWidget(
                      line: line,
                      pageVerses: pageVerses,
                      mushafType: mushafType,
                      theme: theme,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLineWidget({
    required int line,
    required List<PageVerseData> pageVerses,
    required MushafType mushafType,
    required ReadingThemeData theme,
  }) {
    final markers = pageVerses.where((v) {
      final m = v.getMarker(mushafType);
      return m != null && m.line == line;
    }).toList();

    final versesOnLine = pageVerses
        .where((v) => v.occupiesLine(line, mushafType: mushafType))
        .toList();

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
          selectedVerse
              .getHighlights(mushafType)
              .where((h) => h.line == line),
        );
      }
    }

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
          audioVerse
              .getHighlights(mushafType)
              .where((h) => h.line == line),
        );
      }
    }

    return QuranLineImage(
      page: widget.pageNumber,
      line: line,
      mushafType: mushafType,
      imageProvider: _mushafConfig.lineImageProvider(
        widget.pageNumber,
        line,
      ),
      audioHighlights: audioHighlights,
      audioHighlightsColor: widget.audioHighlightsColor,
      selectionHighlights: selectionHighlights,
      markers: markers,
      highlightColor: theme.highlightColor,
      textColor: theme.textColor,
      onTapUpExact: (tapRatio) {
        _handleVerseTapAt(
          line: line,
          tapRatio: tapRatio,
          pageVerses: pageVerses,
          mushafType: mushafType,
        );
      },
    );
  }

  void _handleVerseTapAt({
    required int line,
    required double tapRatio,
    required List<PageVerseData> pageVerses,
    required MushafType mushafType,
  }) {
    if (widget.onVerseTap == null) return;

    final versesOnLine = pageVerses
        .where((v) => v.occupiesLine(line, mushafType: mushafType))
        .toList();

    if (versesOnLine.isEmpty) return;

    final markers = pageVerses.where((v) {
      final m = v.getMarker(mushafType);
      return m != null && m.line == line;
    }).toList();

    PageVerseData? target;

    for (final verse in versesOnLine) {
      final hList = verse
          .getHighlights(mushafType)
          .where((h) => h.line == line);
      for (final h in hList) {
        if (tapRatio >= h.left && tapRatio <= h.right) {
          target = verse;
          break;
        }
      }
      if (target != null) break;
    }

    target ??= markers.isNotEmpty
        ? markers.last
        : versesOnLine.last;

    if (kDebugMode) {
      print(
        "Calling onVerseTap with chapter: ${target.chapter}, verse: ${target.number}",
      );
    }
    widget.onVerseTap!(target);
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

/// Hit-test boundary scope for overlapping lines in a Stack.
///
/// When lines overlap (compactness factor < 1.0), later children in the Stack
/// would otherwise intercept hit tests across their full height including the
/// transparent top margin that visually belongs to the preceding line.
///
/// By ignoring pointer events above [topCutoff], the upper half of the overlapping
/// region falls through to the preceding line in the Stack, ensuring exact
/// geometric touch dispatch without requiring a separate touch overlay.
class _LineHitTestScope extends SingleChildRenderObjectWidget {
  final double topCutoff;

  const _LineHitTestScope({
    required this.topCutoff,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLineHitTestScope(topCutoff: topCutoff);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLineHitTestScope renderObject,
  ) {
    renderObject.topCutoff = topCutoff;
  }
}

class _RenderLineHitTestScope extends RenderProxyBox {
  double topCutoff;

  _RenderLineHitTestScope({required this.topCutoff});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (position.dy < topCutoff) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
