import 'dart:async';

import '../../domain/models/chapter.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/page.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/part.dart';
import '../../domain/models/quarter.dart';
import '../../domain/models/verse.dart';
import '../quran/quran_data_provider.dart';
import '../quran/quran_metadata.dart';
import '../quran/verse_data_provider.dart';
import '../repository/database_service.dart';

/// Hive/in-memory implementation of [DatabaseService] using static Quran metadata.
///
/// Chapters, pages, parts, and quarters are derived from the bundled
/// [quran_metadata.dart] data. Verse operations will return empty results
/// until verse data is loaded from a JSON asset (Phase 8: Realm export).
class HiveDatabaseService implements DatabaseService {
  bool _initialized = false;

  // Pre-computed lookup tables
  late final List<Chapter> _chapters;
  late final List<Page> _pages;
  late final List<Part> _parts;
  late final List<Quarter> _quarters;
  final QuranDataProvider _dataProvider = QuranDataProvider.instance;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Build chapters from static metadata
    _chapters = allChapters
        .map(
          (c) => Chapter(
            identifier: c.number,
            number: c.number,
            isMeccan: c.isMeccan,
            title: c.arabicTitle,
            arabicTitle: c.arabicTitle,
            englishTitle: c.englishTitle,
            titleCodePoint: '',
            searchableText: '${c.arabicTitle} ${c.englishTitle}'.toLowerCase(),
            searchableKeywords: c.englishTitle.toLowerCase(),
            versesCount: c.versesCount,
          ),
        )
        .toList();

    // Build pages
    _pages = List.generate(QuranDataProvider.totalPages, (i) {
      final pageNum = i + 1;
      return Page(
        identifier: pageNum,
        number: pageNum,
        isRight: pageNum.isOdd, // Odd pages are on the right
      );
    });

    // Build parts (juz)
    _parts = List.generate(30, (i) {
      final partNum = i + 1;
      return Part(
        identifier: partNum,
        number: partNum,
        arabicTitle: 'الجزء $partNum',
        englishTitle: 'Juz $partNum',
      );
    });

    // Build quarters (hizb fourths) — 240 in total (60 hizbs × 4 quarters)
    _quarters = [];
    for (int hizb = 1; hizb <= 60; hizb++) {
      for (int fraction = 0; fraction < 4; fraction++) {
        final partNum = ((hizb - 1) ~/ 2) + 1;
        _quarters.add(
          Quarter(
            identifier: (hizb - 1) * 4 + fraction + 1,
            hizbNumber: hizb,
            hizbFraction: fraction,
            arabicTitle: _quarterArabicTitle(hizb, fraction),
            englishTitle: _quarterEnglishTitle(hizb, fraction),
            partNumber: partNum,
          ),
        );
      }
    }

    _initialized = true;
  }

  String _quarterArabicTitle(int hizb, int fraction) {
    return switch (fraction) {
      0 => 'الحزب $hizb',
      1 => '¼ الحزب $hizb',
      2 => '½ الحزب $hizb',
      3 => '¾ الحزب $hizb',
      _ => 'الحزب $hizb',
    };
  }

  String _quarterEnglishTitle(int hizb, int fraction) {
    return switch (fraction) {
      0 => 'Hizb $hizb',
      1 => '¼ Hizb $hizb',
      2 => '½ Hizb $hizb',
      3 => '¾ Hizb $hizb',
      _ => 'Hizb $hizb',
    };
  }

  @override
  bool get isInitialized => _initialized;

  // MARK: - Chapter Operations

  @override
  Future<List<Chapter>> fetchAllChapters() async => _chapters;

  @override
  Future<Chapter?> getChapter(int number) async {
    if (number < 1 || number > _chapters.length) return null;
    return _chapters[number - 1];
  }

  @override
  Future<Chapter?> getChapterForPage(int pageNumber) async {
    final chapters = _dataProvider.getChaptersForPage(pageNumber);
    if (chapters.isEmpty) return null;
    return _chapters[chapters.first.number - 1];
  }

  @override
  Future<List<Chapter>> getChaptersOnPage(int pageNumber) async {
    return _dataProvider
        .getChaptersForPage(pageNumber)
        .map((c) => _chapters[c.number - 1])
        .toList();
  }

  // MARK: - Page Operations

  @override
  Future<Page?> getPage(int number) async {
    if (number < 1 || number > _pages.length) return null;
    return _pages[number - 1];
  }

  @override
  Future<int> getTotalPages() async => QuranDataProvider.totalPages;

  // MARK: - Page Header

  @override
  Future<PageHeaderInfo?> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs_1441,
  }) async {
    final juz = _dataProvider.getJuzForPage(pageNumber);
    final chaptersOnPage = _dataProvider.getChaptersForPage(pageNumber);
    final hizb = ((juz - 1) * 2) + (pageNumber.isOdd ? 1 : 2);
    final hizbClamped = hizb.clamp(1, 60);

    return PageHeaderInfo(
      partNumber: juz,
      partArabicTitle: 'الجزء $juz',
      partEnglishTitle: 'Juz $juz',
      hizbNumber: hizbClamped,
      hizbFraction: 0,
      quarterArabicTitle: 'الحزب $hizbClamped',
      quarterEnglishTitle: 'Hizb $hizbClamped',
      chapters: chaptersOnPage
          .map(
            (c) => ChapterInfo(
              number: c.number,
              arabicTitle: c.arabicTitle,
              englishTitle: c.englishTitle,
            ),
          )
          .toList(),
    );
  }

  // MARK: - Verse Operations (stub — needs Realm data)

  @override
  Future<List<Verse>> getVersesForPage(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs_1441,
  }) async => []; // TODO: Load from quran_data.json when available

  @override
  Future<List<Verse>> getVersesForChapter(int chapterNumber) async => [];

  @override
  Future<Verse?> getVerse(int chapterNumber, int verseNumber) async => null;

  @override
  Future<List<Verse>> getSajdaVerses() async => [];

  // MARK: - Part Operations

  @override
  Future<Part?> getPart(int number) async {
    if (number < 1 || number > _parts.length) return null;
    return _parts[number - 1];
  }

  @override
  Future<Part?> getPartForPage(int pageNumber) async {
    final juz = _dataProvider.getJuzForPage(pageNumber);
    return _parts[juz - 1];
  }

  @override
  Future<Part?> getPartForVerse(int chapterNumber, int verseNumber) async {
    // Simplified: get chapter's start page, find juz for that page
    final chapter = _dataProvider.getChapter(chapterNumber);
    final juz = _dataProvider.getJuzForPage(chapter.startPage);
    return _parts[juz - 1];
  }

  @override
  Future<List<Part>> fetchAllParts() async => _parts;

  // MARK: - Quarter Operations

  @override
  Future<Quarter?> getQuarter(int hizbNumber, int fraction) async {
    final index = (hizbNumber - 1) * 4 + fraction;
    if (index < 0 || index >= _quarters.length) return null;
    return _quarters[index];
  }

  @override
  Future<Quarter?> getQuarterForPage(int pageNumber) async {
    // Simplified: map page to approximate hizb
    final juz = _dataProvider.getJuzForPage(pageNumber);
    final hizb = ((juz - 1) * 2) + 1;
    final index = (hizb - 1) * 4;
    if (index >= 0 && index < _quarters.length) {
      return _quarters[index];
    }
    return null;
  }

  @override
  Future<Quarter?> getQuarterForVerse(
    int chapterNumber,
    int verseNumber,
  ) async {
    final chapter = _dataProvider.getChapter(chapterNumber);
    return getQuarterForPage(chapter.startPage);
  }

  @override
  Future<List<Quarter>> fetchAllQuarters() async => _quarters;

  // MARK: - Search

  @override
  Future<List<Verse>> searchVerses(String query) async {
    if (query.trim().isEmpty) return [];

    final verseProvider = VerseDataProvider.instance;
    if (!verseProvider.isLoaded) await verseProvider.initialize();

    final results = <Verse>[];
    final queryLower = query.toLowerCase();

    // Search across all pages
    for (int page = 1; page <= QuranDataProvider.totalPages; page++) {
      final verses = verseProvider.getVersesForPage(page);
      for (final v in verses) {
        if (v.searchableText.contains(queryLower) ||
            v.text.contains(query) ||
            v.textWithoutTashkil.contains(query)) {
          results.add(
            Verse(
              verseID: v.verseID,
              humanReadableID: '${v.chapter}_${v.number}',
              number: v.number,
              text: v.text,
              textWithoutTashkil: v.textWithoutTashkil,
              uthmanicHafsText: '',
              hafsSmartText: '',
              searchableText: v.searchableText,
              chapterNumber: v.chapter,
              pageNumber: page,
            ),
          );
        }
      }
    }

    return results;
  }

  @override
  Future<List<Chapter>> searchChapters(String query) async {
    final lower = query.toLowerCase();
    return _chapters
        .where(
          (c) =>
              c.searchableText.contains(lower) ||
              c.searchableKeywords.contains(lower) ||
              c.arabicTitle.contains(query),
        )
        .toList();
  }

  @override
  Future<void> dispose() async {
    // Nothing to dispose — data is static
  }
}
