import '../models/chapter.dart';
import '../models/chapter_group.dart';
import '../models/result.dart';

/// Repository for Chapter-related operations.
/// Public API - exposed to library consumers.
abstract class ChapterRepository {
  /// Get all chapters as a Stream for reactive updates.
  Stream<List<Chapter>> getAllChaptersStream();

  /// Get all chapters (one-time fetch).
  Future<Result<List<Chapter>>> getAllChapters();

  /// Get a specific chapter by number.
  Future<Result<Chapter?>> getChapter(int number);

  /// Get the chapter that appears on a specific page.
  Future<Result<Chapter?>> getChapterForPage(int pageNumber);

  /// Get all chapters that appear on a specific page.
  Future<Result<List<Chapter>>> getChaptersOnPage(int pageNumber);

  /// Search chapters by query text.
  Future<Result<List<Chapter>>> searchChapters(String query);

  /// Get chapters grouped by Part (Juz).
  Future<Result<List<ChaptersByPart>>> getChaptersByPart();

  /// Get chapters grouped by Hizb.
  Future<Result<List<ChaptersByHizb>>> getChaptersByHizb();

  /// Get chapters grouped by type (Meccan/Medinan).
  Future<Result<List<ChaptersByType>>> getChaptersByType();

  /// Load and cache all chapters with progress callback.
  Future<Result<void>> loadAndCacheChapters({void Function(int)? onProgress});

  /// Clear chapter cache.
  Future<Result<void>> clearCache();
}

