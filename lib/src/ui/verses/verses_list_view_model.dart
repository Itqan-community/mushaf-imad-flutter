import 'package:flutter/material.dart';

import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/preferences_repository.dart';
import 'dart:async';

/// Display mode for verse text rendering.
enum VerseTextDisplayMode {
  /// Uthmanic Hafs text (e.g. "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ").
  uthmanic,

  /// Plain Arabic text with diacritics / tashkil.
  plainWithTashkil,

  /// Plain Arabic text without diacritics / tashkil.
  plainWithoutTashkil,
}

/// A lightweight holder that pairs a [Verse] with its [Chapter] metadata
/// so the UI can display chapter names without extra lookups.
class VerseWithChapter {
  final Verse verse;
  final Chapter chapter;

  const VerseWithChapter({required this.verse, required this.chapter});
}

/// ViewModel for the VersesListPage.
///
/// Fetches all 6,236 Quran verses grouped by chapter and exposes them
/// through a reactive [ChangeNotifier] interface.  Supports toggling
/// between three text-display modes (Uthmanic / Plain+Tashkil / Plain).
class VersesListViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  final ChapterRepository _chapterRepository;
  final PreferencesRepository _preferencesRepository;
  StreamSubscription? _fontSubscription;

  VersesListViewModel({
    required VerseRepository verseRepository,
    required ChapterRepository chapterRepository,
    required PreferencesRepository preferencesRepository,
  })  : _verseRepository = verseRepository,
        _chapterRepository = chapterRepository,
        _preferencesRepository = preferencesRepository {
    _initPreferences();
  }

  void _initPreferences() {
    _fontSubscription = _preferencesRepository.getFontSizeMultiplierStream().listen((multiplier) {
      _fontSizeMultiplier = multiplier;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _fontSubscription?.cancel();
    super.dispose();
  }

  // ── State ────────────────────────────────────────────────────────────────

  List<VerseWithChapter> _verses = [];
  List<Chapter> _chapters = [];
  bool _isLoading = false;
  String? _error;
  VerseTextDisplayMode _displayMode = VerseTextDisplayMode.uthmanic;
  double _loadProgress = 0.0;
  double _fontSizeMultiplier = 1.0;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<VerseWithChapter> get verses => _verses;
  List<Chapter> get chapters => _chapters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VerseTextDisplayMode get displayMode => _displayMode;
  double get loadProgress => _loadProgress;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  int get totalVerses => _verses.length;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Load all verses for all 114 chapters.
  ///
  /// Fetches chapter-by-chapter to keep memory pressure manageable and
  /// reports progress so the UI can show a determinate progress indicator.
  Future<void> loadAllVerses() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _loadProgress = 0.0;
    notifyListeners();

    try {
      // 1. Fetch all chapters first.
      _chapters = await _chapterRepository.getAllChapters();

      // 2. Fetch verses chapter-by-chapter.
      final allVerses = <VerseWithChapter>[];
      for (int i = 0; i < _chapters.length; i++) {
        final chapter = _chapters[i];
        final chapterVerses = await _verseRepository.getVersesForChapter(
          chapter.number,
        );
        for (final verse in chapterVerses) {
          allVerses.add(VerseWithChapter(verse: verse, chapter: chapter));
        }

        _loadProgress = (i + 1) / _chapters.length;
        notifyListeners();
      }

      _verses = allVerses;
    } catch (e) {
      _error = 'Failed to load verses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch the text display mode.
  void setDisplayMode(VerseTextDisplayMode mode) {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();
  }

  /// Get the display text for a verse based on the current mode.
  String getDisplayText(Verse verse) {
    switch (_displayMode) {
      case VerseTextDisplayMode.uthmanic:
        return verse.uthmanicHafsText.isNotEmpty
            ? verse.uthmanicHafsText
            : verse.text;
      case VerseTextDisplayMode.plainWithTashkil:
        return verse.text;
      case VerseTextDisplayMode.plainWithoutTashkil:
        return verse.textWithoutTashkil.isNotEmpty
            ? verse.textWithoutTashkil
            : verse.text;
    }
  }

  /// Clear the error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
