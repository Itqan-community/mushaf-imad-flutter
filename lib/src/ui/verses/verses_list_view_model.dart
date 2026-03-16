import 'package:flutter/foundation.dart';

import '../../domain/models/verse.dart';
import '../../domain/repository/verse_repository.dart';

/// Display mode for verse text rendering.
enum DisplayMode { plain, tajweed, translation, both }

/// ViewModel for the verses list page.
///
/// Manages fetching and state for a chapter's verses via [VerseRepository].
/// Validates [chapterNumber] immediately on construction — sets [errorMessage]
/// without calling the repository if the value is outside [1, 114].
class VersesListViewModel extends ChangeNotifier {
  final VerseRepository _verseRepository;
  final int chapterNumber;

  List<Verse> _verses = [];
  bool _isLoading = false;
  String? _errorMessage;
  DisplayMode _displayMode = DisplayMode.plain;

  VersesListViewModel({
    required VerseRepository verseRepository,
    required this.chapterNumber,
  }) : _verseRepository = verseRepository {
    // Requirement 1.5, 1.6: validate chapterNumber immediately
    if (chapterNumber < 1 || chapterNumber > 114) {
      _errorMessage = 'رقم السورة يجب أن يكون بين 1 و 114';
    }
  }

  // Getters

  List<Verse> get verses => _verses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DisplayMode get displayMode => _displayMode;

  /// Fetch verses for [chapterNumber] from the repository.
  ///
  /// No-op if [chapterNumber] is invalid (error already set in constructor).
  /// Requirement 1.1, 1.2, 1.3, 1.4
  Future<void> loadVerses() async {
    if (chapterNumber < 1 || chapterNumber > 114) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _verses = await _verseRepository.getVersesForChapter(chapterNumber);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the display mode without re-fetching verses.
  ///
  /// Requirement 3.7: only updates local state and notifies listeners.
  void setDisplayMode(DisplayMode mode) {
    _displayMode = mode;
    notifyListeners();
  }
}
