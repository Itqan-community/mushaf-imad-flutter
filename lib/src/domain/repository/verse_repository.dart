import '../models/advanced_search.dart';
import '../models/mushaf_type.dart';
import '../models/verse.dart';

/// Repository for Verse-related operations.
/// Public API - exposed to library consumers.
abstract class VerseRepository {
  /// Get all verses for a specific page.
  Future<List<Verse>> getVersesForPage(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs1441,
  });

  /// Get all verses for a specific chapter.
  Future<List<Verse>> getVersesForChapter(int chapterNumber);

  /// Get a specific verse by chapter and verse number.
  Future<Verse?> getVerse(int chapterNumber, int verseNumber);

  /// Get all verses that contain sajda (prostration).
  Future<List<Verse>> getSajdaVerses();

  /// Search verses by query text.
  Future<List<Verse>> searchVerses(String query);

  /// Advanced verse search with match modes and Arabic processing options.
  ///
  /// Default implementation throws UnimplementedError to maintain backward
  /// compatibility. Override in concrete implementations to enable advanced search.
  Future<List<Verse>> searchVersesAdvanced(VerseAdvancedSearchQuery query) {
    throw UnimplementedError(
      'searchVersesAdvanced(VerseAdvancedSearchQuery) is not implemented. '
      'Override this method in your concrete VerseRepository implementation '
      'to enable advanced search functionality.',
    );
  }

  /// Get cached verses for a page (returns null if not cached).
  Future<List<Verse>?> getCachedVersesForPage(int pageNumber);

  /// Get cached verses for a chapter (returns null if not cached).
  Future<List<Verse>?> getCachedVersesForChapter(int chapterNumber);
}
