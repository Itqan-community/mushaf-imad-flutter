import '../models/bookmark.dart';

/// Repository for managing user bookmarks.
/// Public API - exposed to library consumers.
abstract class BookmarkRepository {
  /// Observe all bookmarks.
  Stream<List<Bookmark>> getAllBookmarksStream();

  /// Get all bookmarks.
  Future<List<Bookmark>> getAllBookmarks();

  /// Get bookmark by ID.
  Future<Bookmark?> getBookmarkById(String id);

  /// Get bookmarks for a specific chapter.
  Future<List<Bookmark>> getBookmarksForChapter(int chapterNumber);

  /// Get bookmark for a specific verse.
  Future<Bookmark?> getBookmarkForVerse(int chapterNumber, int verseNumber);

  /// Add or update a bookmark.
  Future<Bookmark> addBookmark({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    String note = '',
    List<String> tags = const [],
  });

  /// Update bookmark note.
  Future<void> updateBookmarkNote(String id, String note);

  /// Update bookmark tags.
  Future<void> updateBookmarkTags(String id, List<String> tags);

  /// Delete a bookmark.
  Future<void> deleteBookmark(String id);

  /// Delete bookmark for a specific verse.
  Future<void> deleteBookmarkForVerse(int chapterNumber, int verseNumber);

  /// Delete all bookmarks.
  Future<void> deleteAllBookmarks();

  /// Check if a verse is bookmarked.
  Future<bool> isVerseBookmarked(int chapterNumber, int verseNumber);

  /// Search bookmarks by note content or tags.
  Future<List<Bookmark>> searchBookmarks(String query);
}
