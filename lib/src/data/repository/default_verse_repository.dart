import '../../domain/error/failure.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/result.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/verse_repository.dart';
import 'database_service.dart';

/// Default implementation of VerseRepository.
class DefaultVerseRepository implements VerseRepository {
  final DatabaseService _databaseService;

  DefaultVerseRepository(this._databaseService);

  @override
  Future<Result<List<Verse>>> getVersesForPage(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs1441,
  }) =>
      Result.runCatching(
        () => _databaseService.getVersesForPage(pageNumber,
            mushafType: mushafType),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch verses for page $pageNumber', e),
      );

  @override
  Future<Result<List<Verse>>> getVersesForChapter(int chapterNumber) =>
      Result.runCatching(
        () => _databaseService.getVersesForChapter(chapterNumber),
        failureMapper: (e) => DatabaseFailure(
            'Failed to fetch verses for chapter $chapterNumber', e),
      );

  @override
  Future<Result<Verse?>> getVerse(int chapterNumber, int verseNumber) =>
      Result.runCatching(
        () => _databaseService.getVerse(chapterNumber, verseNumber),
        failureMapper: (e) => DatabaseFailure(
            'Failed to fetch verse $chapterNumber:$verseNumber', e),
      );

  @override
  Future<Result<List<Verse>>> getSajdaVerses() => Result.runCatching(
        () => _databaseService.getSajdaVerses(),
        failureMapper: (e) => DatabaseFailure('Failed to fetch sajda verses', e),
      );

  @override
  Future<Result<List<Verse>>> searchVerses(String query) => Result.runCatching(
        () => _databaseService.searchVerses(query),
        failureMapper: (e) =>
            DatabaseFailure('Verse search failed for query: $query', e),
      );

  @override
  Future<Result<List<Verse>?>> getCachedVersesForPage(int pageNumber) async =>
      const Success(null); // Not currently using cache for verses in repository

  @override
  Future<Result<List<Verse>?>> getCachedVersesForChapter(
          int chapterNumber) async =>
      const Success(null); // Not currently using cache for verses in repository
}

