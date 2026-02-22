import '../../domain/models/bookmark.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../local/dao/bookmark_dao.dart';

/// Default implementation of BookmarkRepository.
class DefaultBookmarkRepository implements BookmarkRepository {
  final BookmarkDao _bookmarkDao;

  DefaultBookmarkRepository(this._bookmarkDao);

  @override
  Stream<List<Bookmark>> getAllBookmarksStream() => _bookmarkDao.watchAll();

  @override
  Future<List<Bookmark>> getAllBookmarks() => _bookmarkDao.getAll();

  @override
  Future<Bookmark?> getBookmarkById(String id) => _bookmarkDao.getById(id);

  @override
  Future<List<Bookmark>> getBookmarksForChapter(int chapterNumber) =>
      _bookmarkDao.getByChapter(chapterNumber);

  @override
  Future<Bookmark?> getBookmarkForVerse(int chapterNumber, int verseNumber) =>
      _bookmarkDao.getByVerse(chapterNumber, verseNumber);

  @override
  Future<Bookmark> addBookmark({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    String note = '',
    List<String> tags = const [],
  }) async {
    final bookmark = Bookmark(
      id: '${chapterNumber}_${verseNumber}_${DateTime.now().millisecondsSinceEpoch}',
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      note: note,
      tags: tags,
    );
    return _bookmarkDao.insert(bookmark);
  }

  @override
  Future<void> updateBookmarkNote(String id, String note) =>
      _bookmarkDao.updateNote(id, note);

  @override
  Future<void> updateBookmarkTags(String id, List<String> tags) =>
      _bookmarkDao.updateTags(id, tags);

  @override
  Future<void> deleteBookmark(String id) => _bookmarkDao.delete(id);

  @override
  Future<void> deleteBookmarkForVerse(int chapterNumber, int verseNumber) =>
      _bookmarkDao.deleteByVerse(chapterNumber, verseNumber);

  @override
  Future<void> deleteAllBookmarks() => _bookmarkDao.deleteAll();

  @override
  Future<bool> isVerseBookmarked(int chapterNumber, int verseNumber) =>
      _bookmarkDao.existsByVerse(chapterNumber, verseNumber);

  @override
  Future<List<Bookmark>> searchBookmarks(String query) =>
      _bookmarkDao.search(query);
}
