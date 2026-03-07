import '../models/last_read_position.dart';
import '../models/mushaf_type.dart';
import '../models/reading_history.dart';
import '../models/result.dart';

/// Repository for managing reading history and progress.
/// Public API - exposed to library consumers.
abstract class ReadingHistoryRepository {
  // Last Read Position

  /// Observe the last read position for a specific mushaf type.
  Stream<LastReadPosition?> getLastReadPositionStream(MushafType mushafType);

  /// Get the last read position for a specific mushaf type.
  Future<Result<LastReadPosition?>> getLastReadPosition(MushafType mushafType);

  /// Update the last read position.
  Future<Result<void>> updateLastReadPosition({
    required MushafType mushafType,
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    double scrollPosition = 0.0,
  });

  // Reading History

  /// Record a reading session (sets current timestamp).
  Future<Result<void>> recordReadingSession({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    required int durationSeconds,
    required MushafType mushafType,
  });

  /// Insert a specific history entry (for import/sync).
  Future<Result<void>> insertReadingHistory(ReadingHistory history);

  /// Get recent reading history.
  Future<Result<List<ReadingHistory>>> getRecentHistory({int limit = 50});

  /// Get reading history for a specific date range.
  Future<Result<List<ReadingHistory>>> getHistoryForDateRange(
    int startTimestamp,
    int endTimestamp,
  );

  /// Get reading history for a specific chapter.
  Future<Result<List<ReadingHistory>>> getHistoryForChapter(int chapterNumber);

  /// Delete reading history older than a specific timestamp.
  Future<Result<void>> deleteHistoryOlderThan(int timestamp);

  /// Delete all reading history.
  Future<Result<void>> deleteAllHistory();

  // Reading Statistics

  /// Get reading statistics.
  Future<Result<ReadingStats>> getReadingStats({
    int? startTimestamp,
    int? endTimestamp,
  });

  /// Get total reading time in seconds.
  Future<Result<int>> getTotalReadingTime();

  /// Get list of read chapters.
  Future<Result<List<int>>> getReadChapters();

  /// Get reading streak (consecutive days with reading activity).
  Future<Result<int>> getCurrentStreak();
}

