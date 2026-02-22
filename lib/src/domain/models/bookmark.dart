/// User bookmark for a specific verse or page.
/// Public API - exposed to library consumers.
class Bookmark {
  final String id;
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final int createdAt;
  final String note;
  final List<String> tags;

  const Bookmark({
    required this.id,
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.createdAt,
    this.note = '',
    this.tags = const [],
  });

  /// Verse reference in format "chapter:verse".
  String get verseReference => '$chapterNumber:$verseNumber';

  /// Check if bookmark has a note.
  bool get hasNote => note.trim().isNotEmpty;

  /// Check if bookmark has tags.
  bool get hasTags => tags.isNotEmpty;
}
