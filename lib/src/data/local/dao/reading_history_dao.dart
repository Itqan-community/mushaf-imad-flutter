import '../../../domain/models/last_read_position.dart';
import '../../../domain/models/mushaf_type.dart';
import '../../../domain/models/reading_history.dart';

/// Data Access Object interface for reading history.
/// Abstraction layer to keep DB implementation swappable.
abstract class ReadingHistoryDao {
  Future<LastReadPosition?> getLastReadPosition(MushafType mushafType);
  Stream<LastReadPosition?> watchLastReadPosition(MushafType mushafType);
  Future<void> saveLastReadPosition(LastReadPosition position);
  Future<void> insertHistory(ReadingHistory history);
  Future<List<ReadingHistory>> getRecentHistory(int limit);
  Future<List<ReadingHistory>> getHistoryForDateRange(
    int startTimestamp,
    int endTimestamp,
  );
  Future<List<ReadingHistory>> getHistoryForChapter(int chapterNumber);
  Future<void> deleteOlderThan(int timestamp);
  Future<void> deleteAll();
  Future<int> getTotalReadingTime();
  Future<List<int>> getReadChapters();
}
