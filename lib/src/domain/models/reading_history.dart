import 'mushaf_type.dart';

/// Reading history entry for analytics.
/// Public API - exposed to library consumers.
class ReadingHistory {
  final String id;
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final int timestamp;
  final int durationSeconds;
  final MushafType mushafType;

  const ReadingHistory({
    required this.id,
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.mushafType,
  });

  /// Verse reference in format "chapter:verse".
  String get verseReference => '$chapterNumber:$verseNumber';

  /// Duration in minutes.
  int get durationMinutes => durationSeconds ~/ 60;
}

/// Reading statistics aggregated from history.
/// Public API - exposed to library consumers.
class ReadingStats {
  final int totalReadingTimeSeconds;
  final int totalPagesRead;
  final int totalChaptersRead;
  final int totalVersesRead;
  final int? mostReadChapter;
  final int currentStreak; // Days
  final int longestStreak; // Days
  final int averageDailyMinutes;

  const ReadingStats({
    required this.totalReadingTimeSeconds,
    required this.totalPagesRead,
    required this.totalChaptersRead,
    required this.totalVersesRead,
    this.mostReadChapter,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageDailyMinutes,
  });

  /// Total reading time in minutes.
  int get totalReadingTimeMinutes => totalReadingTimeSeconds ~/ 60;

  /// Total reading time in hours.
  int get totalReadingTimeHours => totalReadingTimeMinutes ~/ 60;
}
