import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/models/mushaf_config.dart';
import '../../domain/models/mushaf_type.dart';

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
  final List<VerseHighlightData> highlights1441;
  final VerseMarkerData? marker1405;
  final List<VerseHighlightData> highlights1405;

  const PageVerseData({
    required this.verseID,
    required this.number,
    required this.chapter,
    this.text = '',
    this.textWithoutTashkil = '',
    this.searchableText = '',
    this.marker1441,
    this.highlights1441 = const [],
    this.marker1405,
    this.highlights1405 = const [],
  });

  factory PageVerseData.fromJson(Map<String, dynamic> json) {
    List<VerseHighlightData> parseHighlights(String key) =>
        (json[key] as List?)
            ?.map((h) => VerseHighlightData.fromJson(h as Map<String, dynamic>))
            .toList() ??
        [];

    VerseMarkerData? parseMarker(String key) {
      final raw = json[key];
      if (raw == null) return null;
      return VerseMarkerData.fromJson(raw as Map<String, dynamic>);
    }

    return PageVerseData(
      verseID: json['id'] as int,
      number: json['number'] as int,
      chapter: json['chapter'] as int,
      text: (json['text'] as String?) ?? '',
      textWithoutTashkil: (json['textWithoutTashkil'] as String?) ?? '',
      searchableText: (json['searchableText'] as String?) ?? '',
      marker1441: parseMarker('marker1441'),
      highlights1441: parseHighlights('highlights1441'),
      marker1405: parseMarker('marker1405'),
      highlights1405: parseHighlights('highlights1405'),
    );
  }

  // ---------------------------------------------------------------------------
  // Mushaf-aware accessors
  // ---------------------------------------------------------------------------

  /// Get the verse marker for the given [MushafType].
  /// Returns null if the verse has no marker for that Mushaf.
  VerseMarkerData? getMarker(MushafType mushafType) {
    final config = MushafConfigRegistry.configFor(mushafType);
    return switch (config.markerField) {
      'marker1441' => marker1441,
      'marker1405' => marker1405,
      _ => null,
    };
  }

  /// Get the highlight regions for the given [MushafType].
  List<VerseHighlightData> getHighlights(MushafType mushafType) {
    final config = MushafConfigRegistry.configFor(mushafType);
    return switch (config.highlightsField) {
      'highlights1441' => highlights1441,
      'highlights1405' => highlights1405,
      _ => const [],
    };
  }

  /// Check if this verse occupies the given line for the active Mushaf.
  ///
  /// Defaults to [MushafType.hafs1441] for backward compatibility.
  bool occupiesLine(
    int lineNumber, {
    MushafType mushafType = MushafType.hafs1441,
  }) {
    return getHighlights(mushafType).any((h) => h.line == lineNumber);
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
  ///
  /// Defaults to [MushafType.hafs1441] for backward compatibility.
  List<PageVerseData> getMarkersForLine(
    int pageNumber,
    int lineNumber, {
    MushafType mushafType = MushafType.hafs1441,
  }) {
    return getVersesForPage(pageNumber).where((v) {
      final marker = v.getMarker(mushafType);
      return marker != null && marker.line == lineNumber;
    }).toList();
  }

  /// Get verses that occupy the given line (for highlighting).
  ///
  /// Defaults to [MushafType.hafs1441] for backward compatibility.
  List<PageVerseData> getVersesOnLine(
    int pageNumber,
    int lineNumber, {
    MushafType mushafType = MushafType.hafs1441,
  }) {
    return getVersesForPage(
      pageNumber,
    ).where((v) => v.occupiesLine(lineNumber, mushafType: mushafType)).toList();
  }
}
