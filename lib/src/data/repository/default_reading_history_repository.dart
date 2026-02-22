import '../../domain/models/last_read_position.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../local/dao/reading_history_dao.dart';

/// Default implementation of ReadingHistoryRepository.
class DefaultReadingHistoryRepository implements ReadingHistoryRepository {
  final ReadingHistoryDao _dao;

  DefaultReadingHistoryRepository(this._dao);

  @override
  Stream<LastReadPosition?> getLastReadPositionStream(MushafType mushafType) =>
      _dao.watchLastReadPosition(mushafType);

  @override
  Future<LastReadPosition?> getLastReadPosition(MushafType mushafType) =>
      _dao.getLastReadPosition(mushafType);

  @override
  Future<void> updateLastReadPosition({
    required MushafType mushafType,
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    double scrollPosition = 0.0,
  }) async {
    final position = LastReadPosition(
      mushafType: mushafType,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      lastReadAt: DateTime.now().millisecondsSinceEpoch,
      scrollPosition: scrollPosition,
    );
    await _dao.saveLastReadPosition(position);
  }

  @override
  Future<void> recordReadingSession({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    required int durationSeconds,
    required MushafType mushafType,
  }) async {
    final history = ReadingHistory(
      id: '${chapterNumber}_${verseNumber}_${DateTime.now().millisecondsSinceEpoch}',
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: durationSeconds,
      mushafType: mushafType,
    );
    await _dao.insertHistory(history);
  }

  @override
  Future<List<ReadingHistory>> getRecentHistory({int limit = 50}) =>
      _dao.getRecentHistory(limit);

  @override
  Future<List<ReadingHistory>> getHistoryForDateRange(
    int startTimestamp,
    int endTimestamp,
  ) => _dao.getHistoryForDateRange(startTimestamp, endTimestamp);

  @override
  Future<List<ReadingHistory>> getHistoryForChapter(int chapterNumber) =>
      _dao.getHistoryForChapter(chapterNumber);

  @override
  Future<void> deleteHistoryOlderThan(int timestamp) =>
      _dao.deleteOlderThan(timestamp);

  @override
  Future<void> deleteAllHistory() => _dao.deleteAll();

  @override
  Future<ReadingStats> getReadingStats({
    int? startTimestamp,
    int? endTimestamp,
  }) async {
    // Basic implementation - can be enhanced
    final totalTime = await _dao.getTotalReadingTime();
    final readChapters = await _dao.getReadChapters();
    return ReadingStats(
      totalReadingTimeSeconds: totalTime,
      totalPagesRead: 0,
      totalChaptersRead: readChapters.length,
      totalVersesRead: 0,
      currentStreak: 0,
      longestStreak: 0,
      averageDailyMinutes: 0,
    );
  }

  @override
  Future<int> getTotalReadingTime() => _dao.getTotalReadingTime();

  @override
  Future<List<int>> getReadChapters() => _dao.getReadChapters();

  @override
  Future<int> getCurrentStreak() async => 0; // TODO: Implement streak logic
}
