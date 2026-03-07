import '../../domain/error/failure.dart';
import '../../domain/models/last_read_position.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/models/result.dart';
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
  Future<Result<LastReadPosition?>> getLastReadPosition(MushafType mushafType) =>
      Result.runCatching(
        () => _dao.getLastReadPosition(mushafType),
        failureMapper: (e) => DatabaseFailure('Failed to fetch last read position', e),
      );

  @override
  Future<Result<void>> updateLastReadPosition({
    required MushafType mushafType,
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    double scrollPosition = 0.0,
  }) =>
      Result.runCatching(
        () async {
          final position = LastReadPosition(
            mushafType: mushafType,
            chapterNumber: chapterNumber,
            verseNumber: verseNumber,
            pageNumber: pageNumber,
            lastReadAt: DateTime.now().millisecondsSinceEpoch,
            scrollPosition: scrollPosition,
          );
          await _dao.saveLastReadPosition(position);
        },
        failureMapper: (e) => DatabaseFailure('Failed to update last read position', e),
      );

  @override
  Future<Result<void>> recordReadingSession({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    required int durationSeconds,
    required MushafType mushafType,
  }) =>
      Result.runCatching(
        () async {
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
        },
        failureMapper: (e) => DatabaseFailure('Failed to record reading session', e),
      );

  @override
  Future<Result<void>> insertReadingHistory(ReadingHistory history) =>
      Result.runCatching(
        () => _dao.insertHistory(history),
        failureMapper: (e) => DatabaseFailure('Failed to insert reading history', e),
      );

  @override
  Future<Result<List<ReadingHistory>>> getRecentHistory({int limit = 50}) =>
      Result.runCatching(
        () => _dao.getRecentHistory(limit),
        failureMapper: (e) => DatabaseFailure('Failed to fetch recent history', e),
      );

  @override
  Future<Result<List<ReadingHistory>>> getHistoryForDateRange(
    int startTimestamp,
    int endTimestamp,
  ) =>
      Result.runCatching(
        () => _dao.getHistoryForDateRange(startTimestamp, endTimestamp),
        failureMapper: (e) => DatabaseFailure('Failed to fetch history for date range', e),
      );

  @override
  Future<Result<List<ReadingHistory>>> getHistoryForChapter(int chapterNumber) =>
      Result.runCatching(
        () => _dao.getHistoryForChapter(chapterNumber),
        failureMapper: (e) => DatabaseFailure('Failed to fetch history for chapter $chapterNumber', e),
      );

  @override
  Future<Result<void>> deleteHistoryOlderThan(int timestamp) =>
      Result.runCatching(
        () => _dao.deleteOlderThan(timestamp),
        failureMapper: (e) => DatabaseFailure('Failed to delete old history', e),
      );

  @override
  Future<Result<void>> deleteAllHistory() => Result.runCatching(
        () => _dao.deleteAll(),
        failureMapper: (e) => DatabaseFailure('Failed to delete all history', e),
      );

  @override
  Future<Result<ReadingStats>> getReadingStats({
    int? startTimestamp,
    int? endTimestamp,
  }) =>
      Result.runCatching(
        () async {
          final history = await _dao.getRecentHistory(1000); // Get a large enough sample
          if (history.isEmpty) {
            return const ReadingStats(
              totalReadingTimeSeconds: 0,
              totalPagesRead: 0,
              totalChaptersRead: 0,
              totalVersesRead: 0,
              currentStreak: 0,
              longestStreak: 0,
              averageDailyMinutes: 0,
            );
          }

          final totalTime =
              history.fold<int>(0, (sum, h) => sum + h.durationSeconds);
          final uniqueChapters = history.map((h) => h.chapterNumber).toSet();
          final uniquePages = history.map((h) => h.pageNumber).toSet();
          final uniqueVerses =
              history.map((h) => '${h.chapterNumber}:${h.verseNumber}').toSet();

          // Streak calculation
          final dates = history.map((h) {
            final d = DateTime.fromMillisecondsSinceEpoch(h.timestamp);
            return DateTime(d.year, d.month, d.day);
          }).toSet().toList()
            ..sort((a, b) => b.compareTo(a));

          int currentStreak = 0;
          if (dates.isNotEmpty) {
            final today = DateTime.now();
            final todayMidnight = DateTime(today.year, today.month, today.day);
            final firstDate = dates.first;

            final diff = todayMidnight.difference(firstDate).inDays;
            if (diff <= 1) {
              // Current or yesterday
              currentStreak = 1;
              for (int i = 0; i < dates.length - 1; i++) {
                if (dates[i].difference(dates[i + 1]).inDays == 1) {
                  currentStreak++;
                } else {
                  break;
                }
              }
            }
          }

          int longestStreak = 0;
          if (dates.isNotEmpty) {
            int tempStreak = 1;
            for (int i = 0; i < dates.length - 1; i++) {
              if (dates[i].difference(dates[i + 1]).inDays == 1) {
                tempStreak++;
              } else {
                if (tempStreak > longestStreak) longestStreak = tempStreak;
                tempStreak = 1;
              }
            }
            if (tempStreak > longestStreak) longestStreak = tempStreak;
          }

          // Avg daily minutes
          final daysReading = dates.length;
          final avgMinutes =
              daysReading > 0 ? (totalTime ~/ 60) ~/ daysReading : 0;

          return ReadingStats(
            totalReadingTimeSeconds: totalTime,
            totalPagesRead: uniquePages.length,
            totalChaptersRead: uniqueChapters.length,
            totalVersesRead: uniqueVerses.length,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageDailyMinutes: avgMinutes,
          );
        },
        failureMapper: (e) => DatabaseFailure('Failed to calculate reading stats', e),
      );

  @override
  Future<Result<int>> getTotalReadingTime() => Result.runCatching(
        () => _dao.getTotalReadingTime(),
        failureMapper: (e) => DatabaseFailure('Failed to get total reading time', e),
      );

  @override
  Future<Result<List<int>>> getReadChapters() => Result.runCatching(
        () => _dao.getReadChapters(),
        failureMapper: (e) => DatabaseFailure('Failed to get read chapters', e),
      );

  @override
  Future<Result<int>> getCurrentStreak() => Result.runCatching(
        () async {
          final statsResult = await getReadingStats();
          return statsResult.getOrThrow().currentStreak;
        },
        failureMapper: (e) => DatabaseFailure('Failed to get current streak', e),
      );
}
