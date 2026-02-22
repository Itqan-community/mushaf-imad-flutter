import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/last_read_position.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/repository/reading_history_repository.dart';

/// ViewModel for reading history.
class ReadingHistoryViewModel extends ChangeNotifier {
  final ReadingHistoryRepository _readingHistoryRepository;

  ReadingHistoryViewModel({
    required ReadingHistoryRepository readingHistoryRepository,
  }) : _readingHistoryRepository = readingHistoryRepository;

  // State
  List<ReadingHistory> _recentHistory = [];
  ReadingStats? _stats;
  LastReadPosition? _lastReadPosition;
  bool _isLoading = false;

  // Getters
  List<ReadingHistory> get recentHistory => _recentHistory;
  ReadingStats? get stats => _stats;
  LastReadPosition? get lastReadPosition => _lastReadPosition;
  bool get isLoading => _isLoading;

  /// Initialize the ViewModel.
  Future<void> initialize({MushafType mushafType = MushafType.hafs1441}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentHistory = await _readingHistoryRepository.getRecentHistory();
      _stats = await _readingHistoryRepository.getReadingStats();
      _lastReadPosition = await _readingHistoryRepository.getLastReadPosition(
        mushafType,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    await _readingHistoryRepository.deleteAllHistory();
    _recentHistory = [];
    _stats = null;
    notifyListeners();
  }
}
