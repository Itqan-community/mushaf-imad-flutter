import '../models/mushaf_type.dart';
import '../models/page.dart';
import '../models/page_header_info.dart';

/// Repository for Page-related operations.
/// Public API - exposed to library consumers.
abstract class PageRepository {
  /// Get a specific page by number.
  Future<Page?> getPage(int number);

  /// Get total number of pages (default 604).
  Future<int> getTotalPages();

  /// Get page header information.
  Future<PageHeaderInfo?> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs_1441,
  });

  /// Pre-cache a specific page.
  Future<void> cachePage(int pageNumber);

  /// Pre-cache a range of pages.
  Future<void> cachePageRange(int start, int end);

  /// Check if a page is cached.
  Future<bool> isPageCached(int pageNumber);

  /// Clear page cache.
  Future<void> clearPageCache(int pageNumber);

  /// Clear all page caches.
  Future<void> clearAllPageCache();
}
