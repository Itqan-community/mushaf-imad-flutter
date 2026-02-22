import 'package:flutter/material.dart';

import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/search_history.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/search_history_repository.dart';

/// ViewModel for Quran search functionality.
class SearchViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  final ChapterRepository _chapterRepository;
  final BookmarkRepository _bookmarkRepository;
  final SearchHistoryRepository _searchHistoryRepository;

  SearchViewModel({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required BookmarkRepository bookmarkRepository,
    required SearchHistoryRepository searchHistoryRepository,
  }) : _verseRepository = verseRepository,
       _chapterRepository = chapterRepository,
       _bookmarkRepository = bookmarkRepository,
       _searchHistoryRepository = searchHistoryRepository;

  // State
  String _query = '';
  List<Verse> _verseResults = [];
  List<Chapter> _chapterResults = [];
  List<SearchHistoryEntry> _recentSearches = [];
  List<SearchSuggestion> _suggestions = [];
  bool _isSearching = false;
  SearchType _searchType = SearchType.verse;

  // Getters
  String get query => _query;
  List<Verse> get verseResults => _verseResults;
  List<Chapter> get chapterResults => _chapterResults;
  List<SearchHistoryEntry> get recentSearches => _recentSearches;
  List<SearchSuggestion> get suggestions => _suggestions;
  bool get isSearching => _isSearching;
  SearchType get searchType => _searchType;
  int get totalResults => _verseResults.length + _chapterResults.length;

  /// Initialize search ViewModel.
  Future<void> initialize() async {
    _recentSearches = await _searchHistoryRepository.getRecentSearches();
    _suggestions = await _searchHistoryRepository.getPopularSearches();
    notifyListeners();
  }

  /// Perform search.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _query = query;
    _isSearching = true;
    notifyListeners();

    try {
      switch (_searchType) {
        case SearchType.verse:
          _verseResults = await _verseRepository.searchVerses(query);
          _chapterResults = [];
          break;
        case SearchType.chapter:
          _chapterResults = await _chapterRepository.searchChapters(query);
          _verseResults = [];
          break;
        case SearchType.general:
          _verseResults = await _verseRepository.searchVerses(query);
          _chapterResults = await _chapterRepository.searchChapters(query);
          break;
      }

      // Record search
      await _searchHistoryRepository.recordSearch(
        query: query,
        resultCount: totalResults,
        searchType: _searchType,
      );

      _recentSearches = await _searchHistoryRepository.getRecentSearches();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Set search type.
  void setSearchType(SearchType type) {
    _searchType = type;
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  /// Clear search results.
  void clearResults() {
    _query = '';
    _verseResults = [];
    _chapterResults = [];
    notifyListeners();
  }

  /// Clear search history.
  Future<void> clearHistory() async {
    await _searchHistoryRepository.clearSearchHistory();
    _recentSearches = [];
    notifyListeners();
  }

  /// Toggle bookmark for a verse.
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
}
