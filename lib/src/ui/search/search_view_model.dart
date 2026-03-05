import 'package:flutter/material.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/search_history.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import 'models/search_params.dart';
import 'search_engine.dart';

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
  List<Bookmark> _bookmarkResults = [];
  List<SearchHistoryEntry> _recentSearches = [];
  List<SearchSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  SearchType _searchType = SearchType.general;
  SearchParams _searchParams = const SearchParams();

  // Getters
  String get query => _query;
  List<Verse> get verseResults => _verseResults;
  List<Chapter> get chapterResults => _chapterResults;
  List<Bookmark> get bookmarkResults => _bookmarkResults;
  List<SearchHistoryEntry> get recentSearches => _recentSearches;
  List<SearchSuggestion> get suggestions => _suggestions;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get error => _error;
  SearchType get searchType => _searchType;
  SearchParams get searchParams => _searchParams;
  int get totalResults =>
      _verseResults.length + _chapterResults.length + _bookmarkResults.length;

  /// Initialize search ViewModel.
  Future<void> initialize() async {
    _recentSearches = await _searchHistoryRepository.getRecentSearches();
    _suggestions = await _searchHistoryRepository.getPopularSearches();
    notifyListeners();
  }

  /// Update scope filter and re-run search if query exists.
  void updateScope(SearchScope scope, {int? scopeValue}) {
    _searchParams = _searchParams.copyWith(
      scope: scope,
      scopeValue: scopeValue,
      clearScopeValue: scopeValue == null,
    );
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  /// Toggle negation exclusion and re-run search if query exists.
  void toggleExcludeNegated(bool value) {
    _searchParams = _searchParams.copyWith(excludeNegated: value);
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  /// Perform unified search.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _query = query;
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      switch (_searchType) {
        case SearchType.verse:
          _verseResults = await _verseRepository.searchVerses(query);
          _chapterResults = [];
          _bookmarkResults = [];
          break;
        case SearchType.chapter:
          _chapterResults = await _chapterRepository.searchChapters(query);
          _verseResults = [];
          _bookmarkResults = [];
          break;
        case SearchType.general:
          _verseResults = await _verseRepository.searchVerses(query);
          _chapterResults = await _chapterRepository.searchChapters(query);
          _bookmarkResults = await _bookmarkRepository.searchBookmarks(query);
          break;
        case SearchType.exact:
        case SearchType.root:
        case SearchType.prefix:
          final allVerses = await _verseRepository.getAllVerses();
          _verseResults = SearchEngine.search(
            allVerses: allVerses,
            query: query,
            searchType: _searchType,
            params: _searchParams,
          );
          _chapterResults = [];
          _bookmarkResults = [];
          break;
      }

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

  /// Set search type and re-run if active query exists.
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
    _bookmarkResults = [];
    _hasSearched = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear search history.
  Future<void> clearHistory() async {
    await _searchHistoryRepository.clearSearchHistory();
    _recentSearches = [];
    _suggestions = [];
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
