import '../../domain/error/failure.dart';
import '../../domain/models/cache_stats.dart';
import '../../domain/models/part.dart';
import '../../domain/models/quarter.dart';
import '../../domain/models/result.dart';
import '../../domain/repository/quran_repository.dart';
import '../cache/chapters_data_cache.dart';
import '../cache/quran_data_cache_service.dart';
import 'database_service.dart';

/// Default implementation of QuranRepository.
class DefaultQuranRepository implements QuranRepository {
  final DatabaseService _databaseService;
  final ChaptersDataCache _chaptersDataCache;
  final QuranDataCacheService _quranDataCacheService;
  bool _isInitialized = false;

  DefaultQuranRepository(
    this._databaseService,
    this._chaptersDataCache,
    this._quranDataCacheService,
  );

  @override
  Future<Result<void>> initialize() async {
    return Result.runCatching(
      () async {
        await _databaseService.initialize();
        _isInitialized = true;
      },
      failureMapper: (e) => DatabaseFailure('Failed to initialize database', e),
    );
  }

  @override
  bool isInitialized() => _isInitialized;

  @override
  Future<Result<List<Part>>> getAllParts() => Result.runCatching(
        () => _databaseService.fetchAllParts(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch all parts', e),
      );

  @override
  Future<Result<Part?>> getPart(int number) => Result.runCatching(
        () => _databaseService.getPart(number),
        failureMapper: (e) => DatabaseFailure('Failed to fetch part $number', e),
      );

  @override
  Future<Result<Part?>> getPartForPage(int pageNumber) => Result.runCatching(
        () => _databaseService.getPartForPage(pageNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch part for page $pageNumber', e),
      );

  @override
  Future<Result<Part?>> getPartForVerse(int chapterNumber, int verseNumber) =>
      Result.runCatching(
        () => _databaseService.getPartForVerse(chapterNumber, verseNumber),
        failureMapper: (e) => DatabaseFailure(
            'Failed to fetch part for verse $chapterNumber:$verseNumber', e),
      );

  @override
  Future<Result<List<Quarter>>> getAllQuarters() => Result.runCatching(
        () => _databaseService.fetchAllQuarters(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch all quarters', e),
      );

  @override
  Future<Result<Quarter?>> getQuarter(int hizbNumber, int fraction) =>
      Result.runCatching(
        () => _databaseService.getQuarter(hizbNumber, fraction),
        failureMapper: (e) => DatabaseFailure(
            'Failed to fetch quarter for $hizbNumber (fraction $fraction)', e),
      );

  @override
  Future<Result<Quarter?>> getQuarterForPage(int pageNumber) =>
      Result.runCatching(
        () => _databaseService.getQuarterForPage(pageNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch quarter for page $pageNumber', e),
      );

  @override
  Future<Result<Quarter?>> getQuarterForVerse(int chapterNumber, int verseNumber) =>
      Result.runCatching(
        () => _databaseService.getQuarterForVerse(chapterNumber, verseNumber),
        failureMapper: (e) => DatabaseFailure(
            'Failed to fetch quarter for verse $chapterNumber:$verseNumber', e),
      );

  @override
  Future<Result<CacheStats>> getCacheStats() => Result.runCatching(
        () => _quranDataCacheService.getCacheStats(),
        failureMapper: (e) => CacheFailure('Failed to fetch cache stats', e),
      );

  @override
  Future<Result<void>> clearAllCaches() async {
    return Result.runCatching(
      () async {
        _chaptersDataCache.clear();
        _quranDataCacheService.clearAllCache();
      },
      failureMapper: (e) => CacheFailure('Failed to clear caches', e),
    );
  }
}

