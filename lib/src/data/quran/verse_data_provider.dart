import 'dart:convert';
import 'package:flutter/services.dart';

/// Lightweight model for verse marker position on a page line.
class VerseMarkerData {
  final int line;
  final double centerX;
  final double centerY;
  final String numberCodePoint;

  const VerseMarkerData({
    required this.line,
    required this.centerX,
    required this.centerY,
    required this.numberCodePoint,
  });

  factory VerseMarkerData.fromJson(Map<String, dynamic> json) {
    return VerseMarkerData(
      line: (json['line'] as int) + 1, // DB uses 0-indexed lines
      centerX: (json['centerX'] as num).toDouble(),
      centerY: (json['centerY'] as num).toDouble(),
      numberCodePoint: json['numberCodePoint'] as String,
    );
  }
}

/// Lightweight model for verse highlight region (single line).
class VerseHighlightData {
  final int line;
  final double left;
  final double right;

  const VerseHighlightData({
    required this.line,
    required this.left,
    required this.right,
  });

  factory VerseHighlightData.fromJson(Map<String, dynamic> json) {
    return VerseHighlightData(
      line: (json['line'] as int) + 1, // DB uses 0-indexed lines
      left: (json['left'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
    );
  }
}

/// Per-verse data for rendering on a Mushaf page.
class PageVerseData {
  final int verseID;
  final int number;
  final int chapter;
  final String text;
  final String textWithoutTashkil;
  final String searchableText;
  final VerseMarkerData? marker1441;
  final VerseMarkerData? marker1421;
  final List<VerseHighlightData> highlights1441;
  final List<VerseHighlightData> highlights1421;

  const PageVerseData({
    required this.verseID,
    required this.number,
    required this.chapter,
    this.text = '',
    this.textWithoutTashkil = '',
    this.searchableText = '',
    this.marker1441,
    this.marker1421,
    this.highlights1441 = const [],
    this.highlights1421 = const [],
  });

  factory PageVerseData.fromJson(Map<String, dynamic> json) {
    return PageVerseData(
      verseID: json['id'] as int,
      number: json['number'] as int,
      chapter: json['chapter'] as int,
      text: (json['text'] as String?) ?? '',
      textWithoutTashkil: (json['textWithoutTashkil'] as String?) ?? '',
      searchableText: (json['searchableText'] as String?) ?? '',
      marker1441: json['marker1441'] != null
          ? VerseMarkerData.fromJson(json['marker1441'] as Map<String, dynamic>)
          : null,
      marker1421: json['marker1421'] != null
          ? VerseMarkerData.fromJson(json['marker1421'] as Map<String, dynamic>)
          : null,
      highlights1441:
          (json['highlights1441'] as List?)
              ?.map(
                (h) => VerseHighlightData.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
      highlights1421:
          (json['highlights1421'] as List?)
              ?.map(
                (h) => VerseHighlightData.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Check if this verse occupies the given line (1441 layout).
  bool occupiesLine(int lineNumber) {
    return highlights1441.any((h) => h.line == lineNumber);
  }

  /// Check if this verse occupies the given line (1421 layout).
  bool occupiesLine1421(int lineNumber) {
    return highlights1421.any((h) => h.line == lineNumber);
  }

  /// Get marker for specific mushaf type.
  VerseMarkerData? getMarkerForMushafType(String mushafType) {
    return switch (mushafType) {
      'hafs1421' => marker1421,
      'hafs1441' => marker1441,
      _ => marker1441,
    };
  }

  /// Get highlights for specific mushaf type.
  List<VerseHighlightData> getHighlightsForMushafType(String mushafType) {
    return switch (mushafType) {
      'hafs1421' => highlights1421,
      'hafs1441' => highlights1441,
      _ => highlights1441,
    };
  }
}

/// Loads and caches verse data from the bundled JSON asset.
///
/// Provides per-page verse data including markers and highlight regions.
class VerseDataProvider {
  VerseDataProvider._();
  static final VerseDataProvider instance = VerseDataProvider._();

  Map<int, List<PageVerseData>>? _pageData;
  bool _loading = false;

  /// Whether verse data has been loaded.
  bool get isLoaded => _pageData != null;

  /// Initialize by loading the JSON asset. Safe to call multiple times.
  Future<void> initialize() async {
    if (_pageData != null || _loading) return;
    _loading = true;

    try {
      final jsonStr = await rootBundle.loadString(
        'packages/imad_flutter/assets/quran_verse_data.json',
      );
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final pages = json['pages'] as Map<String, dynamic>;

      _pageData = {};
      for (final entry in pages.entries) {
        final pageNum = int.parse(entry.key);
        final verses = (entry.value as List)
            .map((v) => PageVerseData.fromJson(v as Map<String, dynamic>))
            .toList();
        _pageData![pageNum] = verses;
      }
    } catch (e) {
      // If loading fails, use empty data
      _pageData = {};
    } finally {
      _loading = false;
    }
  }

  /// Get all verse data for a specific page.
  List<PageVerseData> getVersesForPage(int pageNumber) {
    return _pageData?[pageNumber] ?? [];
  }

  /// Get verses whose marker appears on the given line of a page.
  List<PageVerseData> getMarkersForLine(int pageNumber, int lineNumber) {
    return getVersesForPage(pageNumber)
        .where((v) => v.marker1441 != null && v.marker1441!.line == lineNumber)
        .toList();
  }

  /// Get verses that occupy the given line (for highlighting).
  List<PageVerseData> getVersesOnLine(int pageNumber, int lineNumber) {
    return getVersesForPage(
      pageNumber,
    ).where((v) => v.occupiesLine(lineNumber)).toList();
  }
}
