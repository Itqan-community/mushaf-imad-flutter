import 'dart:async';

import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_group.dart';
import '../../domain/repository/chapter_repository.dart';
import '../cache/chapters_data_cache.dart';
import 'database_service.dart';

/// Default implementation of ChapterRepository.
class DefaultChapterRepository implements ChapterRepository {
  final DatabaseService _databaseService;
  final ChaptersDataCache _chaptersDataCache;
  final StreamController<List<Chapter>> _chaptersController =
      StreamController<List<Chapter>>.broadcast();

  DefaultChapterRepository(this._databaseService, this._chaptersDataCache);

  @override
  Stream<List<Chapter>> getAllChaptersStream() => _chaptersController.stream;

  @override
  Future<List<Chapter>> getAllChapters() async {
    if (_chaptersDataCache.isCached) return _chaptersDataCache.chapters!;
    final chapters = await _databaseService.fetchAllChapters();
    _chaptersDataCache.setChapters(chapters);
    _chaptersController.add(chapters);
    return chapters;
  }

  @override
  Future<Chapter?> getChapter(int number) =>
      _databaseService.getChapter(number);

  @override
  Future<Chapter?> getChapterForPage(int pageNumber) =>
      _databaseService.getChapterForPage(pageNumber);

  @override
  Future<List<Chapter>> getChaptersOnPage(int pageNumber) =>
      _databaseService.getChaptersOnPage(pageNumber);

  @override
  Future<List<Chapter>> searchChapters(String query) =>
      _databaseService.searchChapters(query);

  @override
  Future<List<ChaptersByPart>> getChaptersByPart() async {
    // TODO: Implement grouping logic
    return [];
  }

  @override
  Future<List<ChaptersByHizb>> getChaptersByHizb() async {
    // TODO: Implement grouping logic
    return [];
  }

  @override
  Future<List<ChaptersByType>> getChaptersByType() async {
    // TODO: Implement grouping logic
    return [];
  }

  @override
  Future<void> loadAndCacheChapters({void Function(int)? onProgress}) async {
    final chapters = await _databaseService.fetchAllChapters();
    _chaptersDataCache.setChapters(chapters);
    _chaptersController.add(chapters);
    onProgress?.call(100);
  }

  @override
  Future<void> clearCache() async {
    _chaptersDataCache.clear();
  }
}
