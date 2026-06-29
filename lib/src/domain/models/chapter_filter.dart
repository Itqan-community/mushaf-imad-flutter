/// Enum representing the revelation type of a Quran chapter.
enum RevelationType {
  /// Show all chapters (no filter).
  all,

  /// Chapters revealed in Makkah.
  meccan,

  /// Chapters revealed in Madinah.
  medinan,
}

/// Filter object for querying chapters.
///
/// Designed to be extensible — future contributors can add
/// more filter criteria (e.g., verses count range, juz number)
/// without breaking the existing API.
class ChapterFilter {
  /// Filter by revelation type (Meccan, Medinan, or all).
  final RevelationType revelationType;
  const ChapterFilter({this.revelationType = RevelationType.all});
}
