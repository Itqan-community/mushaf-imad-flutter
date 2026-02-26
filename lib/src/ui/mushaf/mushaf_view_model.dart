import 'package:flutter/material.dart';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/last_read_position.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for the main Mushaf reading view.
class MushafViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  // ignore: unused_field
  final ChapterRepository _chapterRepository;
  final ReadingHistoryRepository _readingHistoryRepository;
  final PreferencesRepository _preferencesRepository;

  MushafViewModel({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required ReadingHistoryRepository readingHistoryRepository,
    required PreferencesRepository preferencesRepository,
  }) : _verseRepository = verseRepository,
       _chapterRepository = chapterRepository,
       _readingHistoryRepository = readingHistoryRepository,
       _preferencesRepository = preferencesRepository;

  // State
  int _currentPage = 1;
  final int _totalPages = 604;
  List<Verse> _versesForPage = [];
  PageHeaderInfo? _pageHeaderInfo;
  MushafType _mushafType = MushafType.hafs1441;
  LastReadPosition? _lastReadPosition;
  bool _isLoading = false;

  // Getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  List<Verse> get versesForPage => _versesForPage;
  PageHeaderInfo? get pageHeaderInfo => _pageHeaderInfo;
  MushafType get mushafType => _mushafType;
  LastReadPosition? get lastReadPosition => _lastReadPosition;
  bool get isLoading => _isLoading;

  /// Initialize the ViewModel.
  /// Loads the last read page from SharedPreferences.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load last read page from SharedPreferences
      _currentPage = await _preferencesRepository.getCurrentPage();
      
      // Also load last read position for additional context
      _lastReadPosition = await _readingHistoryRepository.getLastReadPosition(
        _mushafType,
      );

      await loadPage(_currentPage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to a specific page.
  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) return;
    _currentPage = pageNumber;
    await loadPage(pageNumber);
    await _preferencesRepository.setCurrentPage(pageNumber);
  }

  /// Load data for a specific page.
  Future<void> loadPage(int pageNumber) async {
    _versesForPage = await _verseRepository.getVersesForPage(
      pageNumber,
      mushafType: _mushafType,
    );
    notifyListeners();
  }

  /// Navigate to the next page.
  Future<void> nextPage() async {
    if (_currentPage < _totalPages) {
      await goToPage(_currentPage + 1);
    }
  }

  /// Navigate to the previous page.
  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }

  /// Set the Mushaf type (layout).
  Future<void> setMushafType(MushafType type) async {
    _mushafType = type;
    await _preferencesRepository.setMushafType(type);
    await loadPage(_currentPage);
  }

  /// Record reading progress.
  Future<void> recordReading(int durationSeconds) async {
    final verses = _versesForPage;
    if (verses.isEmpty) return;

    await _readingHistoryRepository.updateLastReadPosition(
      mushafType: _mushafType,
      chapterNumber: verses.first.chapterNumber,
      verseNumber: verses.first.number,
      pageNumber: _currentPage,
    );

    await _readingHistoryRepository.recordReadingSession(
      chapterNumber: verses.first.chapterNumber,
      verseNumber: verses.first.number,
      pageNumber: _currentPage,
      durationSeconds: durationSeconds,
      mushafType: _mushafType,
    );
  }
}
