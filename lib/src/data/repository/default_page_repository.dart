import '../../domain/models/mushaf_type.dart';
import '../../domain/models/page.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/repository/page_repository.dart';
import '../cache/quran_data_cache_service.dart';
import 'database_service.dart';

/// Default implementation of PageRepository.
class DefaultPageRepository implements PageRepository {
  final DatabaseService _databaseService;
  final QuranDataCacheService _cacheService;

  DefaultPageRepository(this._databaseService, this._cacheService);

  @override
  Future<Page?> getPage(int number) => _databaseService.getPage(number);

  @override
  Future<int> getTotalPages() => _databaseService.getTotalPages();

  @override
  Future<PageHeaderInfo?> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs_1441,
  }) async {
    final cached = _cacheService.getCachedPageHeader(pageNumber);
    if (cached != null) return cached;

    final headerInfo = await _databaseService.getPageHeaderInfo(
      pageNumber,
      mushafType: mushafType,
    );
    if (headerInfo != null) {
      _cacheService.cachePageHeader(pageNumber, headerInfo);
    }
    return headerInfo;
  }

  @override
  Future<void> cachePage(int pageNumber) async {
    final verses = await _databaseService.getVersesForPage(pageNumber);
    _cacheService.cacheVersesForPage(pageNumber, verses);
    final header = await _databaseService.getPageHeaderInfo(pageNumber);
    if (header != null) {
      _cacheService.cachePageHeader(pageNumber, header);
    }
  }

  @override
  Future<void> cachePageRange(int start, int end) async {
    for (var i = start; i <= end; i++) {
      await cachePage(i);
    }
  }

  @override
  Future<bool> isPageCached(int pageNumber) async =>
      _cacheService.isPageCached(pageNumber);

  @override
  Future<void> clearPageCache(int pageNumber) async =>
      _cacheService.clearPageCache(pageNumber);

  @override
  Future<void> clearAllPageCache() async => _cacheService.clearAllCache();
}
