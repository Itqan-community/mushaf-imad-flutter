import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/search_history.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../services/advanced_search_service.dart';
import '../../utils/arabic_normalizer.dart';

/// ViewModel for unified Quran search functionality with autocomplete and debouncing.
///
/// Features:
/// - Debounced search (300ms default)
/// - Autocomplete suggestions
/// - Arabic text normalization
/// - Support for surah:ayah syntax (e.g., "2:255")
/// - Search by surah number, page number, or text
class SearchViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  final ChapterRepository _chapterRepository;
  final BookmarkRepository _bookmarkRepository;
  final SearchHistoryRepository _searchHistoryRepository;
  late final AdvancedSearchService _advancedSearchService;

  // State
  String _query = '';
  List<Verse> _verseResults = [];
  List<Chapter> _chapterResults = [];
  List<Bookmark> _bookmarkResults = [];
  List<SearchHistoryEntry> _recentSearches = [];
  List<SearchSuggestion> _suggestions = [];
  List<AutocompleteSuggestion> _autocompleteSuggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  SearchType _searchType = SearchType.general;
  
  // Debounce timer
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 300);

  // Getters
  String get query => _query;
  List<Verse> get verseResults => _verseResults;
  List<Chapter> get chapterResults => _chapterResults;
  List<Bookmark> get bookmarkResults => _bookmarkResults;
  List<SearchHistoryEntry> get recentSearches => _recentSearches;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<AutocompleteSuggestion> get autocompleteSuggestions => _autocompleteSuggestions;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get error => _error;
  SearchType get searchType => _searchType;
  int get totalResults =>
      _verseResults.length + _chapterResults.length + _bookmarkResults.length;

  /// Initialize search ViewModel
  SearchViewModel({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required BookmarkRepository bookmarkRepository,
    required SearchHistoryRepository searchHistoryRepository,
  }) : _verseRepository = verseRepository,
       _chapterRepository = chapterRepository,
       _bookmarkRepository = bookmarkRepository,
       _searchHistoryRepository = searchHistoryRepository {
    _advancedSearchService = AdvancedSearchService(
      verseRepository: verseRepository,
      chapterRepository: chapterRepository,
      bookmarkRepository: bookmarkRepository,
    );
  }

  /// Initialize and load data
  Future<void> initialize() async {
    _recentSearches = await _searchHistoryRepository.getRecentSearches();
    _suggestions = await _searchHistoryRepository.getPopularSearches();
    await _advancedSearchService.initialize();
    
    // Listen to autocomplete stream
    _advancedSearchService.autocompleteStream.listen((suggestions) {
      _autocompleteSuggestions = suggestions;
      notifyListeners();
    });
    
    notifyListeners();
  }

  /// Perform unified search (with optional debouncing)
  Future<void> search(String query, {bool debounce = false}) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _query = query;
    
    if (debounce) {
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      // Show searching state immediately for better UX
      _isSearching = true;
      notifyListeners();
      
      // Debounce the actual search
      _debounceTimer = Timer(_debounceDelay, () => _performSearch(query));
    } else {
      await _performSearch(query);
    }
  }

  /// Internal search implementation
  Future<void> _performSearch(String query) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final parsedQuery = _advancedSearchService.parseQuery(query);

      switch (_searchType) {
        case SearchType.verse:
          _verseResults = await _advancedSearchService.searchVerses(query);
          _chapterResults = [];
          _bookmarkResults = [];
          break;
        case SearchType.chapter:
          _chapterResults = await _advancedSearchService.searchChapters(query);
          _verseResults = [];
          _bookmarkResults = [];
          break;
        case SearchType.general:
          final results = await _advancedSearchService.unifiedSearch(query);
          _verseResults = results.verses;
          _chapterResults = results.chapters;
          _bookmarkResults = results.bookmarks;
          break;
      }

      // Record search in history
      await _searchHistoryRepository.recordSearch(
        query: query,
        resultCount: totalResults,
        searchType: _searchType,
      );

      _recentSearches = await _searchHistoryRepository.getRecentSearches();
      _hasSearched = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Get autocomplete suggestions for a partial query
  Future<void> updateAutocomplete(String partialQuery) async {
    if (partialQuery.trim().length < 2) {
      _autocompleteSuggestions = [];
      notifyListeners();
      return;
    }

    // Debounce autocomplete
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () async {
      _autocompleteSuggestions = await _advancedSearchService.getAutocompleteSuggestions(
        partialQuery,
        limit: 8,
      );
      notifyListeners();
    });
  }

  /// Set search type and re-run if active query exists
  void setSearchType(SearchType type) {
    _searchType = type;
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  /// Clear search results
  void clearResults() {
    _query = '';
    _verseResults = [];
    _chapterResults = [];
    _bookmarkResults = [];
    _autocompleteSuggestions = [];
    _hasSearched = false;
    _error = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear autocomplete suggestions
  void clearAutocomplete() {
    _autocompleteSuggestions = [];
    notifyListeners();
  }

  /// Clear search history
  Future<void> clearHistory() async {
    await _searchHistoryRepository.clearSearchHistory();
    _recentSearches = [];
    _suggestions = [];
    notifyListeners();
  }

  /// Toggle bookmark for a verse
  Future<void> toggleBookmark(Verse verse) async {
    final isBookmarked = await _bookmarkRepository.isVerseBookmarked(
      verse.chapterNumber,
      verse.number,
    );
    if (isBookmarked) {
      await _bookmarkRepository.deleteBookmarkForVerse(
        verse.chapterNumber,
        verse.number,
      );
    } else {
      await _bookmarkRepository.addBookmark(
        chapterNumber: verse.chapterNumber,
        verseNumber: verse.number,
        pageNumber: verse.pageNumber,
      );
    }
    notifyListeners();
  }

  /// Check if a query looks like a surah:ayah reference
  bool isSurahAyahQuery(String query) {
    return _advancedSearchService.parseQuery(query).type == SearchQueryType.surahAyah;
  }

  /// Get normalized version of query (for debugging/display)
  String getNormalizedQuery(String query) {
    return query.normalized;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _advancedSearchService.dispose();
    super.dispose();
  }
}

/// Extension for SearchType conversion
extension SearchTypeExtension on SearchType {
  String get displayName {
    switch (this) {
      case SearchType.general:
        return 'All';
      case SearchType.verse:
        return 'Verses';
      case SearchType.chapter:
        return 'Chapters';
    }
  }
}
