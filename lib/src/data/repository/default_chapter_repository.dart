import 'dart:async';

import '../../domain/error/failure.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_group.dart';
import '../../domain/models/result.dart';
import '../../domain/repository/chapter_repository.dart';
import '../cache/chapters_data_cache.dart';
import 'database_service.dart';

/// Default implementation of ChapterRepository.
class DefaultChapterRepository implements ChapterRepository {
  final DatabaseService _databaseService;
  final ChaptersDataCache _chaptersDataCache;

  DefaultChapterRepository(this._databaseService, this._chaptersDataCache);

  @override
  Stream<List<Chapter>> getAllChaptersStream() =>
      _chaptersDataCache.allChaptersStream;

  @override
  Future<Result<List<Chapter>>> getAllChapters() => Result.runCatching(
        () async {
          if (_chaptersDataCache.isCached) {
            return _chaptersDataCache.allChapters!;
          }
          final chapters = await _databaseService.fetchAllChapters();
          _chaptersDataCache.cacheAll(chapters);
          return chapters;
        },
        failureMapper: (e) => DatabaseFailure('Failed to fetch chapters', e),
      );

  @override
  Future<Result<Chapter?>> getChapter(int number) => Result.runCatching(
        () async {
          if (_chaptersDataCache.isCached) {
            return _chaptersDataCache.getById(number);
          }
          return _databaseService.getChapter(number);
        },
        failureMapper: (e) => DatabaseFailure('Failed to fetch chapter $number', e),
      );

  @override
  Future<Result<Chapter?>> getChapterForPage(int pageNumber) =>
      Result.runCatching(
        () => _databaseService.getChapterForPage(pageNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch chapter for page $pageNumber', e),
      );

  @override
  Future<Result<List<Chapter>>> getChaptersOnPage(int pageNumber) =>
      Result.runCatching(
        () => _databaseService.getChaptersOnPage(pageNumber),
        failureMapper: (e) =>
            DatabaseFailure('Failed to fetch chapters on page $pageNumber', e),
      );

  @override
  Future<Result<List<Chapter>>> searchChapters(String query) =>
      Result.runCatching(
        () => _databaseService.searchChapters(query),
        failureMapper: (e) =>
            DatabaseFailure('Chapter search failed for query: $query', e),
      );

  @override
  Future<Result<List<ChaptersByPart>>> getChaptersByPart() => Result.runCatching(
        () async {
          final chaptersResult = await getAllChapters();
          final chapters = chaptersResult.getOrThrow();
          return ChaptersByPart.fromChapters(chapters);
        },
        failureMapper: (e) =>
            DatabaseFailure('Failed to group chapters by part', e),
      );

  @override
  Future<Result<List<ChaptersByHizb>>> getChaptersByHizb() => Result.runCatching(
        () async {
          final chaptersResult = await getAllChapters();
          final chapters = chaptersResult.getOrThrow();
          return ChaptersByHizb.fromChapters(chapters);
        },
        failureMapper: (e) =>
            DatabaseFailure('Failed to group chapters by hizb', e),
      );

  @override
  Future<Result<List<ChaptersByType>>> getChaptersByType() => Result.runCatching(
        () async {
          final chaptersResult = await getAllChapters();
          final chapters = chaptersResult.getOrThrow();
          return ChaptersByType.fromChapters(chapters);
        },
        failureMapper: (e) =>
            DatabaseFailure('Failed to group chapters by type', e),
      );

  @override
  Future<Result<void>> loadAndCacheChapters(
          {void Function(int)? onProgress}) async =>
      Result.runCatching(
        () async {
          final chapters = await _databaseService.fetchAllChapters();
          _chaptersDataCache.cacheAll(chapters);
          onProgress?.call(100);
        },
        failureMapper: (e) => DatabaseFailure('Failed to load/cache chapters', e),
      );

  @override
  Future<Result<void>> clearCache() async => Result.runCatching(
        () async => _chaptersDataCache.clear(),
        failureMapper: (e) => DatabaseFailure('Failed to clear chapters cache', e),
      );
}
