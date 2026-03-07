import 'dart:convert';
import '../../domain/error/failure.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/models/search_history.dart';
import '../../domain/models/result.dart';
import '../../domain/models/mushaf_type.dart';
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
  Future<Result<UserDataBackup>> exportUserData({bool includeHistory = true}) =>
      Result.runCatching(
        () async {
          final bookmarksResult = await _bookmarkRepository.getAllBookmarks();
          final bookmarks = bookmarksResult.getOrThrow();

          final bookmarkData = bookmarks
              .map(
                (b) => BookmarkData(
                  chapterNumber: b.chapterNumber,
                  verseNumber: b.verseNumber,
                  pageNumber: b.pageNumber,
                  createdAt: b.timestamp,
                  note: b.note,
                  tags: b.tags,
                ),
              )
              .toList();

          List<ReadingHistoryData> historyData = [];
          if (includeHistory) {
            final historyResult = await _readingHistoryRepository.getRecentHistory(limit: 5000);
            final history = historyResult.getOrThrow();
            historyData = history
                .map(
                  (h) => ReadingHistoryData(
                    chapterNumber: h.chapterNumber,
                    verseNumber: h.verseNumber,
                    pageNumber: h.pageNumber,
                    timestamp: h.timestamp,
                    durationSeconds: h.durationSeconds,
                    mushafType: h.mushafType.index,
                  ),
                )
                .toList();
          }

          final searchHistoryResult = await _searchHistoryRepository.getRecentSearches(limit: 1000);
          final searchHistory = searchHistoryResult.getOrThrow();
          final searchData = searchHistory
              .map(
                (s) => SearchHistoryData(
                    query: s.query,
                    timestamp: s.timestamp,
                    resultCount: s.resultCount,
                    searchType: s.searchType.name,
                ),
              )
              .toList();

          return UserDataBackup(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            bookmarks: bookmarkData,
            readingHistory: historyData,
            searchHistory: searchData,
          );
        },
        failureMapper: (e) => DatabaseFailure('Failed to export user data', e),
      );

  @override
  Future<Result<String>> exportToJson({bool includeHistory = true}) =>
      Result.runCatching(
        () async {
          final backupResult = await exportUserData(includeHistory: includeHistory);
          final backup = backupResult.getOrThrow();
          return jsonEncode(backup.toJson());
        },
        failureMapper: (e) => DatabaseFailure('Failed to export user data to JSON', e),
      );

  @override
  Future<Result<ImportResult>> importUserData(
    UserDataBackup backup, {
    bool mergeWithExisting = true,
  }) =>
      Result.runCatching(
        () async {
          int bookmarksImported = 0;
          int historyImported = 0;
          int searchHistoryImported = 0;
          final errors = <String>[];

          if (!mergeWithExisting) {
            await clearAllUserData();
          }

          // Import Bookmarks
          for (final bm in backup.bookmarks) {
            final result = await _bookmarkRepository.addBookmark(
              chapterNumber: bm.chapterNumber,
              verseNumber: bm.verseNumber,
              pageNumber: bm.pageNumber,
              note: bm.note,
              tags: bm.tags,
            );
            if (result.isSuccess) {
              bookmarksImported++;
            } else {
              errors.add('Failed to import bookmark: ${result.failureOrThrow().message}');
            }
          }

          // Import Reading History
          for (final h in backup.readingHistory) {
            final history = ReadingHistory(
              id: '${h.chapterNumber}_${h.verseNumber}_${h.timestamp}',
              chapterNumber: h.chapterNumber,
              verseNumber: h.verseNumber,
              pageNumber: h.pageNumber,
              timestamp: h.timestamp,
              durationSeconds: h.durationSeconds,
              mushafType: MushafType.values[h.mushafType],
            );
            final result = await _readingHistoryRepository.insertReadingHistory(history);
            if (result.isSuccess) {
              historyImported++;
            } else {
              errors.add('Failed to import history entry: ${result.failureOrThrow().message}');
            }
          }

          // Import Search History
          for (final s in backup.searchHistory) {
            final entry = SearchHistoryEntry(
              id: '${s.query.hashCode}_${s.timestamp}',
              query: s.query,
              timestamp: s.timestamp,
              resultCount: s.resultCount,
              searchType: SearchType.values.byName(s.searchType),
            );
            final result = await _searchHistoryRepository.insertSearchHistory(entry);
            if (result.isSuccess) {
              searchHistoryImported++;
            } else {
              errors.add('Failed to import search: ${result.failureOrThrow().message}');
            }
          }

          return ImportResult(
            bookmarksImported: bookmarksImported,
            lastReadPositionsImported: historyImported,
            searchHistoryImported: searchHistoryImported,
            preferencesImported: false,
            errors: errors,
          );
        },
        failureMapper: (e) => DatabaseFailure('Failed to import user data', e),
      );

  @override
  Future<Result<ImportResult>> importFromJson(
    String json, {
    bool mergeWithExisting = true,
  }) =>
      Result.runCatching(
        () async {
          final decoded = jsonDecode(json);
          if (decoded is! Map<String, dynamic>) {
             throw const FormatException('Invalid backup file: expected a JSON object at root level');
          }
          final backup = UserDataBackup.fromJson(decoded);
          final result = await importUserData(backup, mergeWithExisting: mergeWithExisting);
          return result.getOrThrow();
        },
        failureMapper: (e) => DatabaseFailure('Failed to import user data from JSON', e),
      );

  @override
  Future<Result<void>> clearAllUserData() => Result.runCatching(
        () async {
          await _bookmarkRepository.deleteAllBookmarks();
          await _readingHistoryRepository.deleteAllHistory();
          await _searchHistoryRepository.clearSearchHistory();
          await _preferencesRepository.clearAll();
        },
        failureMapper: (e) => DatabaseFailure('Failed to clear all user data', e),
      );
}
