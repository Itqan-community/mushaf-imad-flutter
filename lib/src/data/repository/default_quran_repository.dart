import '../../domain/models/cache_stats.dart';
import '../../domain/models/part.dart';
import '../../domain/models/quarter.dart';
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
  Future<void> initialize() async {
    await _databaseService.initialize();
    _isInitialized = true;
  }

  @override
  bool isInitialized() => _isInitialized;

  @override
  Future<List<Part>> getAllParts() => _databaseService.fetchAllParts();

  @override
  Future<Part?> getPart(int number) => _databaseService.getPart(number);

  @override
  Future<Part?> getPartForPage(int pageNumber) =>
      _databaseService.getPartForPage(pageNumber);

  @override
  Future<Part?> getPartForVerse(int chapterNumber, int verseNumber) =>
      _databaseService.getPartForVerse(chapterNumber, verseNumber);

  @override
  Future<List<Quarter>> getAllQuarters() => _databaseService.fetchAllQuarters();

  @override
  Future<Quarter?> getQuarter(int hizbNumber, int fraction) =>
      _databaseService.getQuarter(hizbNumber, fraction);

  @override
  Future<Quarter?> getQuarterForPage(int pageNumber) =>
      _databaseService.getQuarterForPage(pageNumber);

  @override
  Future<Quarter?> getQuarterForVerse(int chapterNumber, int verseNumber) =>
      _databaseService.getQuarterForVerse(chapterNumber, verseNumber);

  @override
  Future<CacheStats> getCacheStats() async =>
      _quranDataCacheService.getCacheStats();

  @override
  Future<void> clearAllCaches() async {
    _chaptersDataCache.clear();
    _quranDataCacheService.clearAllCache();
  }
}
