import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/ui/search/search_engine.dart';
import 'package:imad_flutter/src/ui/search/models/search_params.dart';
import 'package:imad_flutter/src/domain/models/search_history.dart';
import 'package:imad_flutter/src/domain/models/verse.dart';

void main() {
  // ── normalizeQuery ────────────────────────────────────────────────────────

  group('normalizeQuery', () {
    test('strips tashkil', () {
      expect(SearchEngine.normalizeQuery('رَحِيمٌ'), 'رحيم');
    });

    test('unifies hamza forms', () {
      expect(SearchEngine.normalizeQuery('أنزل'), 'انزل');
      expect(SearchEngine.normalizeQuery('إياك'), 'اياك');
    });

    test('normalizes ta marbuta', () {
      expect(SearchEngine.normalizeQuery('الصلاة'), 'الصلاه');
    });

    test('normalizes alef maqsura', () {
      expect(SearchEngine.normalizeQuery('هدى'), 'هدي');
    });
  });

  // ── exact search ──────────────────────────────────────────────────────────

  group('exact search', () {
    final verses = [
      _v(' الرحمن الرحيم ', chapter: 1),
      _v(' رحيم الله ', chapter: 1),
      _v(' الرحمن رب العالمين ', chapter: 1),
    ];

    test('finds verse with exact word', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'الرحيم',
        searchType: SearchType.exact,
        params: const SearchParams(),
      );
      expect(results.length, 1);
    });

    test('does not match partial word', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'رحم',
        searchType: SearchType.exact,
        params: const SearchParams(),
      );
      expect(results.isEmpty, true);
    });
  });

  // ── prefix search ─────────────────────────────────────────────────────────

  group('prefix search', () {
    final verses = [
      _v(' يومنون بالله ', chapter: 1),
      _v(' امنوا بالغيب ', chapter: 1),
      _v(' الله رب العالمين ', chapter: 1),
    ];

    test('finds words starting with query', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'يوم',
        searchType: SearchType.prefix,
        params: const SearchParams(),
      );
      expect(results.length, 1);
    });

    test('does not find word where query is in the middle', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'لله',
        searchType: SearchType.prefix,
        params: const SearchParams(),
      );
      expect(results.isEmpty, true);
    });
  });

  // ── exclude negated ───────────────────────────────────────────────────────

  group('excludeNegated', () {
    final verses = [
      _v(' لا يومنون بالله ', chapter: 1),
      _v(' الذين يومنون بالغيب ', chapter: 2),
    ];

    test('removes negated verses when toggle is on', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'يومنون',
        searchType: SearchType.general,
        params: const SearchParams(excludeNegated: true),
      );
      expect(results.length, 1);
      expect(results.first.chapterNumber, 2);
    });

    test('keeps all verses when toggle is off', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'يومنون',
        searchType: SearchType.general,
        params: const SearchParams(excludeNegated: false),
      );
      expect(results.length, 2);
    });
  });

  // ── scope filter ──────────────────────────────────────────────────────────

  group('scope filter', () {
    final verses = [
      _v(' بسم الله ', chapter: 1, page: 1, part: 1),
      _v(' الحمد لله ', chapter: 1, page: 1, part: 1),
      _v(' الله رب العالمين ', chapter: 2, page: 2, part: 1),
      _v(' الله نور السماوات ', chapter: 24, page: 350, part: 18),
    ];

    test('surah scope limits to correct chapter', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'الله',
        searchType: SearchType.general,
        params: const SearchParams(scope: SearchScope.surah, scopeValue: 1),
      );
      expect(results.length, 1);
    });

    test('page scope limits to correct page', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'الله',
        searchType: SearchType.general,
        params: const SearchParams(scope: SearchScope.page, scopeValue: 350),
      );
      expect(results.length, 1);
    });

    test('juz scope limits to correct part', () {
      final results = SearchEngine.search(
        allVerses: verses,
        query: 'الله',
        searchType: SearchType.general,
        params: const SearchParams(scope: SearchScope.juz, scopeValue: 18),
      );
      expect(results.length, 1);
    });
  });

  // ── empty query ───────────────────────────────────────────────────────────

  test('empty query returns empty list', () {
    final verses = [_v(' الله ', chapter: 1)];
    final results = SearchEngine.search(
      allVerses: verses,
      query: '',
      searchType: SearchType.general,
      params: const SearchParams(),
    );
    expect(results.isEmpty, true);
  });
}

// ── helper ────────────────────────────────────────────────────────────────────

Verse _v(String text, {required int chapter, int page = 1, int part = 1}) {
  return Verse(
    verseID: 0,
    humanReadableID: '${chapter}_1',
    number: 1,
    text: text,
    textWithoutTashkil: text,
    uthmanicHafsText: text,
    hafsSmartText: text,
    searchableText: text,
    chapterNumber: chapter,
    pageNumber: page,
    partNumber: part,
    hizbNumber: 1,
  );
}
