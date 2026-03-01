import 'package:flutter/material.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/verse.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/last_read_position.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../../domain/repository/preferences_repository.dart';
// إضافة الاستيراد للمشغل والقارئ
import '../../data/audio/flutter_audio_player.dart'; 
import '../../domain/models/reciter_info.dart';

class MushafViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  final ChapterRepository _chapterRepository;
  final ReadingHistoryRepository _readingHistoryRepository;
  final PreferencesRepository _preferencesRepository;
  // إضافة مرجع للمشغل
  final FlutterAudioPlayer? _audioPlayer;

  MushafViewModel({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required ReadingHistoryRepository readingHistoryRepository,
    required PreferencesRepository preferencesRepository,
    FlutterAudioPlayer? audioPlayer, // تمرير المشغل هنا
  }) : _verseRepository = verseRepository,
       _chapterRepository = chapterRepository,
       _readingHistoryRepository = readingHistoryRepository,
       _preferencesRepository = preferencesRepository,
       _audioPlayer = audioPlayer;

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

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lastReadPosition = await _readingHistoryRepository.getLastReadPosition(_mushafType);
      if (_lastReadPosition != null) {
        _currentPage = _lastReadPosition!.pageNumber;
      }
      await loadPage(_currentPage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// دالة جديدة لتشغيل الصوت من بداية الصفحة الحالية
  Future<void> playCurrentPageAudio(ReciterInfo reciter) async {
    if (_versesForPage.isEmpty || _audioPlayer == null) return;

    // الحصول على أول آية في الصفحة الحالية
    final firstVerse = _versesForPage.first;

    // أمر المشغل بالبدء من هذه السورة وهذه الآية تحديداً
    await _audioPlayer!.loadChapter(
      firstVerse.chapterNumber,
      reciter,
      autoPlay: true,
      startAyahNumber: firstVerse.number, // تمرير رقم الآية
    );
  }

  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > _totalPages) return;
    _currentPage = pageNumber;
    await loadPage(pageNumber);
    await _preferencesRepository.setCurrentPage(pageNumber);
  }

  Future<void> loadPage(int pageNumber) async {
    _versesForPage = await _verseRepository.getVersesForPage(
      pageNumber,
      mushafType: _mushafType,
    );
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (_currentPage < _totalPages) await goToPage(_currentPage + 1);
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) await goToPage(_currentPage - 1);
  }

  Future<void> setMushafType(MushafType type) async {
    _mushafType = type;
    await _preferencesRepository.setMushafType(type);
    await loadPage(_currentPage);
  }

  Future<void> recordReading(int durationSeconds) async {
    final verses = _versesForPage;
    if (verses.isEmpty) return;
    await _readingHistoryRepository.updateLastReadPosition(
      mushafType: _mushafType,
      chapterNumber: verses.first.chapterNumber,
      verseNumber: verses.first.number,
      pageNumber: _currentPage,
    );
  }
}
