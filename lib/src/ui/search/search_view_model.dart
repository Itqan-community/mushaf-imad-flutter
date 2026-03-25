import 'package:flutter/material.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/search_history.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../data/remote/alketab_api_service.dart';

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

  // AlKetab pagination state
  String? _alketabGeneratedQuery;
  int _alketabCurrentPage = 1;
  int _alketabTotalPages = 1;
  bool _isLoadingMore = false;

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
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages => _alketabCurrentPage < _alketabTotalPages;
  int get totalResults =>
      _verseResults.length + _chapterResults.length + _bookmarkResults.length;

  bool get _isAlKetabType =>
      _searchType == SearchType.exact ||
      _searchType == SearchType.root ||
      _searchType == SearchType.prefix;

  Future<void> initialize() async {
    _recentSearches = await _searchHistoryRepository.getRecentSearches();
    _suggestions = await _searchHistoryRepository.getPopularSearches();
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _query = query;
    _isSearching = true;
    _error = null;
    _alketabGeneratedQuery = null;
    _alketabCurrentPage = 1;
    _alketabTotalPages = 1;
    notifyListeners();

    try {
      if (_isAlKetabType) {
        await _searchWithAlKetab(query);
      } else {
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
          default:
            _verseResults = await _verseRepository.searchVerses(query);
            _chapterResults = await _chapterRepository.searchChapters(query);
            _bookmarkResults = await _bookmarkRepository.searchBookmarks(query);
            break;
        }
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

  Future<void> _searchWithAlKetab(String query) async {
    final response = await AlKetabApiService.search(query);
    _alketabGeneratedQuery = response.generatedQuery;
    _alketabTotalPages = response.totalPages;
    _alketabCurrentPage = 1;
    _verseResults = _mapAlKetabResults(response.results);
    _chapterResults = [];
    _bookmarkResults = [];
  }

  /// Load next page of AlKetab results and append to existing results
  Future<void> loadMoreResults() async {
    if (!hasMorePages || _isLoadingMore || _alketabGeneratedQuery == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _alketabCurrentPage + 1;
      final response = await AlKetabApiService.fetchPage(
        _alketabGeneratedQuery!,
        nextPage,
      );
      _alketabCurrentPage = nextPage;
      _verseResults = [
        ..._verseResults,
        ..._mapAlKetabResults(response.results),
      ];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  List<Verse> _mapAlKetabResults(List<AlKetabResult> results) {
    return results
        .map(
          (r) => Verse(
            verseID: r.verseID,
            humanReadableID: '${r.chapterNumber}_${r.verseNumber}',
            number: r.verseNumber,
            text: r.text,
            textWithoutTashkil: r.text,
            uthmanicHafsText: r.text,
            hafsSmartText: r.text,
            searchableText: r.text,
            chapterNumber: r.chapterNumber,
            pageNumber: r.pageNumber,
            partNumber: 0,
            hizbNumber: 0,
          ),
        )
        .toList();
  }

  void setSearchType(SearchType type) {
    _searchType = type;
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  void clearResults() {
    _query = '';
    _verseResults = [];
    _chapterResults = [];
    _bookmarkResults = [];
    _hasSearched = false;
    _error = null;
    _alketabGeneratedQuery = null;
    _alketabCurrentPage = 1;
    _alketabTotalPages = 1;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _searchHistoryRepository.clearSearchHistory();
    _recentSearches = [];
    _suggestions = [];
    notifyListeners();
  }

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
