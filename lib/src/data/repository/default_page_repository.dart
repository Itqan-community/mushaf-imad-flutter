import '../../domain/error/failure.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/page.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/result.dart';
import '../../domain/repository/page_repository.dart';
import '../cache/quran_data_cache_service.dart';
import 'database_service.dart';

/// Default implementation of PageRepository.
class DefaultPageRepository implements PageRepository {
  final DatabaseService _databaseService;
  final QuranDataCacheService _cacheService;

  DefaultPageRepository(this._databaseService, this._cacheService);

  @override
  Future<Result<Page?>> getPage(int number) => Result.runCatching(
        () => _databaseService.getPage(number),
        failureMapper: (e) => DatabaseFailure('Failed to fetch page $number', e),
      );

  @override
  Future<Result<int>> getTotalPages() => Result.runCatching(
        () => _databaseService.getTotalPages(),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch total pages count', e),
      );

  @override
  Future<Result<PageHeaderInfo?>> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs1441,
  }) async {
    return Result.runCatching(
      () async {
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
      },
      failureMapper: (e) => DatabaseFailure(
          'Failed to fetch header info for page $pageNumber', e),
    );
  }

  @override
  Future<Result<void>> cachePage(int pageNumber) => Result.runCatching(
        () => _cacheService.cachePage(pageNumber),
        failureMapper: (e) => CacheFailure('Failed to cache page $pageNumber', e),
      );

  @override
  Future<Result<void>> cachePageRange(int start, int end) => Result.runCatching(
        () async {
          for (int i = start; i <= end; i++) {
            await _cacheService.cachePage(i);
          }
        },
        failureMapper: (e) =>
            CacheFailure('Failed to cache page range $start-$end', e),
      );

  @override
  Future<Result<bool>> isPageCached(int pageNumber) => Result.runCatching(
        () => _cacheService.isPageCached(pageNumber),
        failureMapper: (e) =>
            CacheFailure('Failed to check cache status for page $pageNumber', e),
      );

  @override
  Future<Result<void>> clearPageCache(int pageNumber) => Result.runCatching(
        () => _cacheService.clearPageCache(pageNumber),
        failureMapper: (e) =>
            CacheFailure('Failed to clear cache for page $pageNumber', e),
      );

  @override
  Future<Result<void>> clearAllPageCache() => Result.runCatching(
        () => _cacheService.clearAllCache(),
        failureMapper: (e) => CacheFailure('Failed to clear all page caches', e),
      );
}

