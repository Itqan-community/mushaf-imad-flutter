import '../models/bookmark.dart';
import '../models/result.dart';

/// Repository for managing user bookmarks.
/// Public API - exposed to library consumers.
abstract class BookmarkRepository {
  /// Observe all bookmarks.
  Stream<List<Bookmark>> getAllBookmarksStream();

  /// Get all bookmarks.
  Future<Result<List<Bookmark>>> getAllBookmarks();

  /// Get bookmark by ID.
  Future<Result<Bookmark?>> getBookmarkById(String id);

  /// Get bookmarks for a specific chapter.
  Future<Result<List<Bookmark>>> getBookmarksForChapter(int chapterNumber);

  /// Get bookmark for a specific verse.
  Future<Result<Bookmark?>> getBookmarkForVerse(int chapterNumber, int verseNumber);

  /// Add or update a bookmark.
  Future<Result<Bookmark>> addBookmark({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    String note = '',
    List<String> tags = const [],
  });

  /// Update bookmark note.
  Future<Result<void>> updateBookmarkNote(String id, String note);

  /// Update bookmark tags.
  Future<Result<void>> updateBookmarkTags(String id, List<String> tags);

  /// Delete a bookmark.
  Future<Result<void>> deleteBookmark(String id);

  /// Delete bookmark for a specific verse.
  Future<Result<void>> deleteBookmarkForVerse(int chapterNumber, int verseNumber);

  /// Delete all bookmarks.
  Future<Result<void>> deleteAllBookmarks();

  /// Check if a verse is bookmarked.
  Future<Result<bool>> isVerseBookmarked(int chapterNumber, int verseNumber);

  /// Search bookmarks by note content or tags.
  Future<Result<List<Bookmark>>> searchBookmarks(String query);
}
