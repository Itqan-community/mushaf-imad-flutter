import '../../../domain/models/bookmark.dart';

/// Data Access Object interface for bookmarks.
/// Abstraction layer to keep DB implementation swappable.
abstract class BookmarkDao {
  Future<List<Bookmark>> getAll();
  Stream<List<Bookmark>> watchAll();
  Future<Bookmark?> getById(String id);
  Future<List<Bookmark>> getByChapter(int chapterNumber);
  Future<Bookmark?> getByVerse(int chapterNumber, int verseNumber);
  Future<Bookmark> insert(Bookmark bookmark);
  Future<void> updateNote(String id, String note);
  Future<void> updateTags(String id, List<String> tags);
  Future<void> delete(String id);
  Future<void> deleteByVerse(int chapterNumber, int verseNumber);
  Future<void> deleteAll();
  Future<bool> existsByVerse(int chapterNumber, int verseNumber);
  Future<List<Bookmark>> search(String query);
}
