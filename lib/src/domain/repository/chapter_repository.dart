import '../models/chapter.dart';
import '../models/chapter_group.dart';

/// Repository for Chapter-related operations.
/// Public API - exposed to library consumers.
abstract class ChapterRepository {
  /// Get all chapters as a Stream for reactive updates.
  Stream<List<Chapter>> getAllChaptersStream();

  /// Get all chapters (one-time fetch).
  Future<List<Chapter>> getAllChapters();

  /// Get a specific chapter by number.
  Future<Chapter?> getChapter(int number);

  /// Get the chapter that appears on a specific page.
  Future<Chapter?> getChapterForPage(int pageNumber);

  /// Get all chapters that appear on a specific page.
  Future<List<Chapter>> getChaptersOnPage(int pageNumber);

  /// Search chapters by query text.
  Future<List<Chapter>> searchChapters(String query);

  /// Get chapters grouped by Part (Juz).
  Future<List<ChaptersByPart>> getChaptersByPart();

  /// Get chapters grouped by Hizb.
  Future<List<ChaptersByHizb>> getChaptersByHizb();

  /// Get chapters grouped by type (Meccan/Medinan).
  Future<List<ChaptersByType>> getChaptersByType();

  /// Load and cache all chapters with progress callback.
  Future<void> loadAndCacheChapters({void Function(int)? onProgress});

  /// Clear chapter cache.
  Future<void> clearCache();
}
