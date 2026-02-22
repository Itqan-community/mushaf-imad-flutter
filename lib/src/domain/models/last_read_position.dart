import 'mushaf_type.dart';

/// Last read position for resuming reading.
/// Public API - exposed to library consumers.
class LastReadPosition {
  final MushafType mushafType;
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final int lastReadAt;
  final double scrollPosition;

  const LastReadPosition({
    required this.mushafType,
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.lastReadAt,
    this.scrollPosition = 0.0,
  });

  /// Verse reference in format "chapter:verse".
  String get verseReference => '$chapterNumber:$verseNumber';

  /// Check if this position is recent (within last 7 days).
  bool isRecent() {
    final sevenDaysAgo =
        DateTime.now().millisecondsSinceEpoch - (7 * 24 * 60 * 60 * 1000);
    return lastReadAt > sevenDaysAgo;
  }
}
