import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/verse_data_provider.dart';

enum TextDisplayMode { uthmanic, plainWithTashkil, plainWithoutTashkil }

class VersesListViewModel extends ChangeNotifier {
  TextDisplayMode _displayMode = TextDisplayMode.uthmanic;
  List<PageVerseData> _allVerses = [];
  bool _isLoading = true;

  TextDisplayMode get displayMode => _displayMode;
  List<PageVerseData> get allVerses => _allVerses;
  bool get isLoading => _isLoading;

  VersesListViewModel() {
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    final provider = VerseDataProvider.instance;
    if (!provider.isLoaded) {
      await provider.initialize();
    }

    final verses = <PageVerseData>[];
    for (int page = 1; page <= QuranDataProvider.totalPages; page++) {
      final pageVerses = provider.getVersesForPage(page);
      for (final v in pageVerses) {
        if (!verses.any((existing) => existing.verseID == v.verseID)) {
          verses.add(v);
        }
      }
    }

    _allVerses = verses;
    _isLoading = false;
    notifyListeners();
  }

  void setDisplayMode(TextDisplayMode mode) {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();
  }

  String getVerseText(PageVerseData verse) {
    switch (_displayMode) {
      case TextDisplayMode.uthmanic:
        return verse.text;
      case TextDisplayMode.plainWithTashkil:
        return verse.searchableText;
      case TextDisplayMode.plainWithoutTashkil:
        return verse.textWithoutTashkil;
    }
  }
}
