import '../../domain/models/cache_stats.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/verse.dart';

/// Service to cache Quran data for quick access.
/// Internal API - not exposed to library consumers.
class QuranDataCacheService {
  // Cached data structures
  final Map<int, List<Verse>> _cachedVerses = {}; // Page number -> Verses
  final Map<int, PageHeaderInfo> _cachedPageHeaders =
      {}; // Page number -> Header
  final Map<int, List<Verse>> _cachedChapterVerses =
      {}; // Chapter number -> Verses

  // MARK: - Cache Retrieval

  /// Get cached verses for a page (returns null if not cached).
  List<Verse>? getCachedVerses(int forPage) => _cachedVerses[forPage];

  /// Get cached page header (returns null if not cached).
  PageHeaderInfo? getCachedPageHeader(int forPage) =>
      _cachedPageHeaders[forPage];

  /// Get cached verses for a chapter (returns null if not cached).
  List<Verse>? getCachedChapterVerses(int forChapter) =>
      _cachedChapterVerses[forChapter];

  /// Check if page data is cached.
  bool isPageCached(int pageNumber) =>
      _cachedVerses.containsKey(pageNumber) &&
      _cachedPageHeaders.containsKey(pageNumber);

  // MARK: - Cache Storage

  /// Cache verses for a page.
  void cacheVersesForPage(int pageNumber, List<Verse> verses) {
    _cachedVerses[pageNumber] = verses;
  }

  /// Cache page header.
  void cachePageHeader(int pageNumber, PageHeaderInfo headerInfo) {
    _cachedPageHeaders[pageNumber] = headerInfo;
  }

  /// Cache verses for a chapter.
  void cacheChapterVerses(int chapterNumber, List<Verse> verses) {
    _cachedChapterVerses[chapterNumber] = verses;
  }

  // MARK: - Cache Management

  /// Clear cached data for a specific page.
  void clearPageCache(int pageNumber) {
    _cachedVerses.remove(pageNumber);
    _cachedPageHeaders.remove(pageNumber);
  }

  /// Clear cached data for a chapter.
  void clearChapterCache(int chapterNumber) {
    _cachedChapterVerses.remove(chapterNumber);
  }

  /// Clear all cached data.
  void clearAllCache() {
    _cachedVerses.clear();
    _cachedPageHeaders.clear();
    _cachedChapterVerses.clear();
  }

  /// Get cache statistics.
  CacheStats getCacheStats() {
    return CacheStats(
      cachedPagesCount: _cachedVerses.length,
      cachedChaptersCount: _cachedChapterVerses.length,
      totalVersesCached: _cachedVerses.values.fold(
        0,
        (sum, v) => sum + v.length,
      ),
    );
  }
}
