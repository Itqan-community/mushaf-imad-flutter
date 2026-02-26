import '../../domain/models/mushaf_type.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/verse_repository.dart';
import '../cache/quran_data_cache_service.dart';
import 'database_service.dart';

/// Default implementation of VerseRepository.
class DefaultVerseRepository implements VerseRepository {
  final DatabaseService _databaseService;
  final QuranDataCacheService _cacheService;

  DefaultVerseRepository(this._databaseService, this._cacheService);

  @override
  Future<List<Verse>> getVersesForPage(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs_1441,
  }) async {
    // Check cache first
    final cached = _cacheService.getCachedVerses(pageNumber);
    if (cached != null) return cached;

    final verses = await _databaseService.getVersesForPage(
      pageNumber,
      mushafType: mushafType,
    );
    _cacheService.cacheVersesForPage(pageNumber, verses);
    return verses;
  }

  @override
  Future<List<Verse>> getVersesForChapter(int chapterNumber) async {
    final cached = _cacheService.getCachedChapterVerses(chapterNumber);
    if (cached != null) return cached;

    final verses = await _databaseService.getVersesForChapter(chapterNumber);
    _cacheService.cacheChapterVerses(chapterNumber, verses);
    return verses;
  }

  @override
  Future<Verse?> getVerse(int chapterNumber, int verseNumber) =>
      _databaseService.getVerse(chapterNumber, verseNumber);

  @override
  Future<List<Verse>> getSajdaVerses() => _databaseService.getSajdaVerses();

  @override
  Future<List<Verse>> searchVerses(String query) =>
      _databaseService.searchVerses(query);

  @override
  Future<List<Verse>?> getCachedVersesForPage(int pageNumber) async =>
      _cacheService.getCachedVerses(pageNumber);

  @override
  Future<List<Verse>?> getCachedVersesForChapter(int chapterNumber) async =>
      _cacheService.getCachedChapterVerses(chapterNumber);
}
