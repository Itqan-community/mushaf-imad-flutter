import 'dart:convert';

import '../../domain/models/user_data_backup.dart';
import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// Default implementation of DataExportRepository.
class DefaultDataExportRepository implements DataExportRepository {
  final BookmarkRepository _bookmarkRepository;
  final ReadingHistoryRepository _readingHistoryRepository;
  final SearchHistoryRepository _searchHistoryRepository;
  final PreferencesRepository _preferencesRepository;

  DefaultDataExportRepository(
    this._bookmarkRepository,
    this._readingHistoryRepository,
    this._searchHistoryRepository,
    this._preferencesRepository,
  );

  @override
  Future<UserDataBackup> exportUserData({bool includeHistory = true}) async {
    final bookmarks = await _bookmarkRepository.getAllBookmarks();
    final bookmarkData = bookmarks
        .map(
          (b) => BookmarkData(
            chapterNumber: b.chapterNumber,
            verseNumber: b.verseNumber,
            pageNumber: b.pageNumber,
            createdAt: b.createdAt,
            note: b.note,
            tags: b.tags,
          ),
        )
        .toList();

    return UserDataBackup(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      bookmarks: bookmarkData,
    );
  }

  @override
  Future<String> exportToJson({bool includeHistory = true}) async {
    final backup = await exportUserData(includeHistory: includeHistory);
    return jsonEncode(backup.toJson());
  }

  @override
  Future<ImportResult> importUserData(
    UserDataBackup backup, {
    bool mergeWithExisting = true,
  }) async {
    int bookmarksImported = 0;
    final errors = <String>[];

    if (!mergeWithExisting) {
      await _bookmarkRepository.deleteAllBookmarks();
    }

    for (final bm in backup.bookmarks) {
      try {
        await _bookmarkRepository.addBookmark(
          chapterNumber: bm.chapterNumber,
          verseNumber: bm.verseNumber,
          pageNumber: bm.pageNumber,
          note: bm.note,
          tags: bm.tags,
        );
        bookmarksImported++;
      } catch (e) {
        errors.add('Failed to import bookmark: $e');
      }
    }

    return ImportResult(
      bookmarksImported: bookmarksImported,
      lastReadPositionsImported: 0,
      searchHistoryImported: 0,
      preferencesImported: false,
      errors: errors,
    );
  }

  @override
  Future<ImportResult> importFromJson(
    String json, {
    bool mergeWithExisting = true,
  }) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final backup = UserDataBackup.fromJson(data);
    return importUserData(backup, mergeWithExisting: mergeWithExisting);
  }

  @override
  Future<void> clearAllUserData() async {
    await _bookmarkRepository.deleteAllBookmarks();
    await _readingHistoryRepository.deleteAllHistory();
    await _searchHistoryRepository.clearSearchHistory();
    await _preferencesRepository.clearAll();
  }
}
