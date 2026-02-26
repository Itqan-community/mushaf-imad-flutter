import 'dart:async';

import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../arabic_normalizer.dart';

/// Represents different types of search queries
enum SearchQueryType {
  /// General text search
  text,
  /// Search by surah:ayah format (e.g., "2:255" for Ayat Al-Kursi)
  surahAyah,
  /// Search by surah number only
  surahNumber,
  /// Search by page number
  pageNumber,
  /// Search by juz number
  juzNumber,
}

/// Parsed search query with type information
class ParsedSearchQuery {
  final String rawQuery;
  final SearchQueryType type;
  final int? surahNumber;
  final int? ayahNumber;
  final int? pageNumber;
  final int? juzNumber;
  final String searchText;

  ParsedSearchQuery({
    required this.rawQuery,
    required this.type,
    this.surahNumber,
    this.ayahNumber,
    this.pageNumber,
    this.juzNumber,
    this.searchText = '',
  });

  bool get isSpecificQuery => surahNumber != null || ayahNumber != null || pageNumber != null || juzNumber != null;
}

/// Autocomplete suggestion item
class AutocompleteSuggestion {
  final String text;
  final String? secondaryText;
  final AutocompleteSuggestionType type;
  final dynamic data;

  AutocompleteSuggestion({
    required this.text,
    this.secondaryText,
    required this.type,
    this.data,
  });
}

enum AutocompleteSuggestionType {
  chapter,
  verse,
  bookmark,
  recentSearch,
  suggestion,
}

/// Advanced search service with autocomplete and Arabic normalization support
class AdvancedSearchService {
  final VerseRepository _verseRepository;
  final ChapterRepository _chapterRepository;
  final BookmarkRepository _bookmarkRepository;

  // Cache for chapters and popular verses
  List<Chapter>? _cachedChapters;
  final _autocompleteController = StreamController<List<AutocompleteSuggestion>>.broadcast();
  Timer? _debounceTimer;

  AdvancedSearchService({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required BookmarkRepository bookmarkRepository,
  }) : _verseRepository = verseRepository,
       _chapterRepository = chapterRepository,
       _bookmarkRepository = bookmarkRepository;

  /// Stream of autocomplete suggestions
  Stream<List<AutocompleteSuggestion>> get autocompleteStream => _autocompleteController.stream;

  /// Initialize the service and preload data
  Future<void> initialize() async {
    _cachedChapters = await _chapterRepository.getAllChapters();
  }

  /// Parse a search query to determine its type and extract structured data
  ParsedSearchQuery parseQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return ParsedSearchQuery(rawQuery: query, type: SearchQueryType.text);
    }

    // Check for surah:ayah format (e.g., "2:255", "2:255-260", "Al-Baqarah:255")
    final surahAyahPattern = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$');
    final surahAyahMatch = surahAyahPattern.firstMatch(trimmed);

    if (surahAyahMatch != null) {
      return ParsedSearchQuery(
        rawQuery: query,
        type: SearchQueryType.surahAyah,
        surahNumber: int.tryParse(surahAyahMatch.group(1)!),
        ayahNumber: int.tryParse(surahAyahMatch.group(2)!),
        searchText: trimmed,
      );
    }

    // Check for standalone number (could be surah, page, or juz)
    final numberPattern = RegExp(r'^(\d+)$');
    final numberMatch = numberPattern.firstMatch(trimmed);

    if (numberMatch != null) {
      final number = int.tryParse(numberMatch.group(1)!);
      if (number != null) {
        // Determine if it's likely a surah (1-114), page (1-604), or juz (1-30)
        if (number <= 30) {
          // Could be surah, page, or juz - default to surah for small numbers
          return ParsedSearchQuery(
            rawQuery: query,
            type: SearchQueryType.surahNumber,
            surahNumber: number,
            searchText: trimmed,
          );
        } else if (number <= 114) {
          return ParsedSearchQuery(
            rawQuery: query,
            type: SearchQueryType.surahNumber,
            surahNumber: number,
            searchText: trimmed,
          );
        } else if (number <= 604) {
          return ParsedSearchQuery(
            rawQuery: query,
            type: SearchQueryType.pageNumber,
            pageNumber: number,
            searchText: trimmed,
          );
        }
      }
    }

    // Default to text search
    return ParsedSearchQuery(
      rawQuery: query,
      type: SearchQueryType.text,
      searchText: trimmed,
    );
  }

  /// Get autocomplete suggestions based on partial query
  Future<List<AutocompleteSuggestion>> getAutocompleteSuggestions(
    String partialQuery, {
    int limit = 10,
  }) async {
    if (partialQuery.trim().length < 2) {
      return [];
    }

    final suggestions = <AutocompleteSuggestion>[];
    final normalizedQuery = partialQuery.normalized;

    // Ensure chapters are loaded
    _cachedChapters ??= await _chapterRepository.getAllChapters();

    // 1. Match chapters by Arabic or English name
    for (final chapter in _cachedChapters!) {
      if (suggestions.length >= limit) break;

      final normalizedArabic = chapter.arabicTitle.normalized;
      final normalizedEnglish = chapter.englishTitle.toLowerCase();

      if (normalizedArabic.contains(normalizedQuery) ||
          normalizedEnglish.contains(normalizedQuery.toLowerCase())) {
        suggestions.add(AutocompleteSuggestion(
          text: chapter.arabicTitle,
          secondaryText: '${chapter.englishTitle} · ${chapter.versesCount} verses',
          type: AutocompleteSuggestionType.chapter,
          data: chapter,
        ));
      }
    }

    // 2. If query starts with a number, suggest surah:ayah format
    final numberPrefix = RegExp(r'^(\d+):?$').firstMatch(partialQuery.trim());
    if (numberPrefix != null) {
      final surahNum = int.tryParse(numberPrefix.group(1)!);
      if (surahNum != null && surahNum >= 1 && surahNum <= 114) {
        final chapter = _cachedChapters!.firstWhere(
          (c) => c.number == surahNum,
          orElse: () => _cachedChapters!.first,
        );
        suggestions.add(AutocompleteSuggestion(
          text: '$surahNum:1',
          secondaryText: '${chapter.arabicTitle} - Verse 1',
          type: AutocompleteSuggestionType.verse,
          data: {'chapter': surahNum, 'verse': 1},
        ));
      }
    }

    // 3. Add generic text search suggestion
    if (suggestions.length < limit) {
      suggestions.add(AutocompleteSuggestion(
        text: partialQuery,
        secondaryText: 'Search for "$partialQuery"',
        type: AutocompleteSuggestionType.suggestion,
      ));
    }

    return suggestions;
  }

  /// Debounced autocomplete - useful for text fields
  void debouncedAutocomplete(
    String query, {
    Duration delay = const Duration(milliseconds: 300),
    int limit = 10,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      final suggestions = await getAutocompleteSuggestions(query, limit: limit);
      _autocompleteController.add(suggestions);
    });
  }

  /// Search verses with Arabic normalization support
  Future<List<Verse>> searchVerses(
    String query, {
    bool useNormalization = true,
    int? chapterFilter,
  }) async {
    final parsed = parseQuery(query);

    // Handle specific query types
    if (parsed.type == SearchQueryType.surahAyah && parsed.surahNumber != null) {
      // Get specific verse
      final verse = await _verseRepository.getVerse(
        parsed.surahNumber!,
        parsed.ayahNumber ?? 1,
      );
      return verse != null ? [verse] : [];
    }

    if (parsed.type == SearchQueryType.surahNumber && parsed.surahNumber != null) {
      // Return verses from that chapter
      return _verseRepository.getVersesForChapter(parsed.surahNumber!);
    }

    // General text search
    var results = await _verseRepository.searchVerses(query);

    if (useNormalization && results.isEmpty) {
      // If no results, try searching with normalized text
      // This is handled at the database level, but we can add additional filtering
      results = await _verseRepository.searchVerses(query.normalized);
    }

    return results;
  }

  /// Search chapters with Arabic normalization
  Future<List<Chapter>> searchChapters(String query) async {
    final normalizedQuery = query.normalized;

    _cachedChapters ??= await _chapterRepository.getAllChapters();

    return _cachedChapters!.where((chapter) {
      return chapter.arabicTitle.containsArabic(query) ||
          chapter.englishTitle.toLowerCase().contains(normalizedQuery.toLowerCase());
    }).toList();
  }

  /// Search bookmarks with Arabic normalization
  Future<List<Bookmark>> searchBookmarks(String query) async {
    final bookmarks = await _bookmarkRepository.getAllBookmarks();
    final normalizedQuery = query.normalized;

    return bookmarks.where((bookmark) {
      return bookmark.note.normalized.contains(normalizedQuery) ||
          bookmark.tags.any((tag) => tag.normalized.contains(normalizedQuery));
    }).toList();
  }

  /// Unified search across all content types
  Future<UnifiedSearchResults> unifiedSearch(
    String query, {
    bool useNormalization = true,
  }) async {
    final parsed = parseQuery(query);

    return UnifiedSearchResults(
      verses: await searchVerses(query, useNormalization: useNormalization),
      chapters: await searchChapters(query),
      bookmarks: await searchBookmarks(query),
      parsedQuery: parsed,
    );
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _autocompleteController.close();
  }
}

/// Container for unified search results
class UnifiedSearchResults {
  final List<Verse> verses;
  final List<Chapter> chapters;
  final List<Bookmark> bookmarks;
  final ParsedSearchQuery parsedQuery;

  UnifiedSearchResults({
    required this.verses,
    required this.chapters,
    required this.bookmarks,
    required this.parsedQuery,
  });

  int get totalCount => verses.length + chapters.length + bookmarks.length;
  bool get isEmpty => totalCount == 0;
}
