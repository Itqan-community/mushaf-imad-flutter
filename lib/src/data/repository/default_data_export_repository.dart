import 'dart:convert';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/user_data_backup.dart';
import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/reading_history_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../domain/repository/preferences_repository.dart';

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

    final lastReadPositions = <LastReadPositionData>[];
    for (final type in MushafType.values) {
      final pos = await _readingHistoryRepository.getLastReadPosition(type);
      if (pos != null) {
        lastReadPositions.add(LastReadPositionData(
          mushafType: type.name,
          chapterNumber: pos.chapterNumber,
          verseNumber: pos.verseNumber,
          pageNumber: pos.pageNumber,
          lastReadAt: pos.lastReadAt,
          scrollPosition: pos.scrollPosition,
        ));
      }
    }

    var searchHistoryData = <SearchHistoryData>[];
    var readingHistoryExport = <Map<String, dynamic>>[];

    if (includeHistory) {
      final searchEntries = await _searchHistoryRepository.getRecentSearches(
        limit: 1000,
      );
      searchHistoryData = searchEntries
          .map(
            (s) => SearchHistoryData(
              query: s.query,
              timestamp: s.timestamp,
              resultCount: s.resultCount,
              searchType: s.searchType.name,
            ),
          )
          .toList();

      final readingHistory = await _readingHistoryRepository.getRecentHistory(
        limit: 1000,
      );
      readingHistoryExport = readingHistory
          .map(
            (h) => {
              'chapterNumber': h.chapterNumber,
              'verseNumber': h.verseNumber,
              'pageNumber': h.pageNumber,
              'timestamp': h.timestamp,
              'durationSeconds': h.durationSeconds,
              'mushafType': h.mushafType.name,
            },
          )
          .toList();
    }

    final themeConfig = await _preferencesRepository.getThemeConfig();
    final reciterId = await _preferencesRepository.getSelectedReciterId();
    final playbackSpeed = await _preferencesRepository.getPlaybackSpeed();
    final repeatMode = await _preferencesRepository.getRepeatMode();

    final preferencesData = PreferencesData(
      mushafType: MushafType.hafs1441.name,
      currentPage: 1,
      fontSizeMultiplier: 1.0,
      selectedReciterId: reciterId,
      playbackSpeed: playbackSpeed,
      repeatMode: repeatMode,
      themeMode: themeConfig.mode.name,
      colorScheme: themeConfig.colorScheme.name,
      useAmoled: themeConfig.useAmoled,
    );

    return UserDataBackup(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      bookmarks: bookmarkData,
      lastReadPositions: lastReadPositions,
      searchHistory: searchHistoryData,
      preferences: preferencesData,
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
    int searchHistoryImported = 0;
    int lastReadPositionsImported = 0;
    bool preferencesImported = false;
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
        errors.add('Failed to import bookmark ${bm.chapterNumber}:${bm.verseNumber}: $e');
      }
    }

    for (final pos in backup.lastReadPositions) {
      try {
        final mushafType = MushafType.values.firstWhere(
          (t) => t.name == pos.mushafType,
          orElse: () => MushafType.hafs1441,
        );
        await _readingHistoryRepository.updateLastReadPosition(
          mushafType: mushafType,
          chapterNumber: pos.chapterNumber,
          verseNumber: pos.verseNumber,
          pageNumber: pos.pageNumber,
          scrollPosition: pos.scrollPosition,
        );
        lastReadPositionsImported++;
      } catch (e) {
        errors.add('Failed to import last read position: $e');
      }
    }

    for (final search in backup.searchHistory) {
      try {
        await _searchHistoryRepository.recordSearch(
          query: search.query,
          resultCount: search.resultCount,
        );
        searchHistoryImported++;
      } catch (e) {
        errors.add('Failed to import search history: $e');
      }
    }

    if (backup.preferences != null) {
      try {
        final prefs = backup.preferences!;
        await _preferencesRepository.setSelectedReciterId(
          prefs.selectedReciterId,
        );
        await _preferencesRepository.setPlaybackSpeed(prefs.playbackSpeed);
        await _preferencesRepository.setRepeatMode(prefs.repeatMode);
        preferencesImported = true;
      } catch (e) {
        errors.add('Failed to import preferences: $e');
      }
    }

    return ImportResult(
      bookmarksImported: bookmarksImported,
      lastReadPositionsImported: lastReadPositionsImported,
      searchHistoryImported: searchHistoryImported,
      preferencesImported: preferencesImported,
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
