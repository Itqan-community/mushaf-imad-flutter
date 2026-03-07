import '../models/mushaf_type.dart';
import '../models/page.dart';
import '../models/page_header_info.dart';
import '../models/result.dart';

/// Repository for Page-related operations.
/// Public API - exposed to library consumers.
abstract class PageRepository {
  /// Get a specific page by number.
  Future<Result<Page?>> getPage(int number);

  /// Get total number of pages (default 604).
  Future<Result<int>> getTotalPages();

  /// Get page header information.
  Future<Result<PageHeaderInfo?>> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs1441,
  });

  /// Pre-cache a specific page.
  Future<Result<void>> cachePage(int pageNumber);

  /// Pre-cache a range of pages.
  Future<Result<void>> cachePageRange(int start, int end);

  /// Check if a page is cached.
  Future<Result<bool>> isPageCached(int pageNumber);

  /// Clear page cache.
  Future<Result<void>> clearPageCache(int pageNumber);

  /// Clear all page caches.
  Future<Result<void>> clearAllPageCache();
}

