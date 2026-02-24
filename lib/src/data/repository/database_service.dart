import '../../domain/models/advanced_search.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/models/page.dart';
import '../../domain/models/page_header_info.dart';
import '../../domain/models/part.dart';
import '../../domain/models/quarter.dart';
import '../../domain/models/verse.dart';

/// Facade around the database that powers Quran metadata.
/// Internal API - not exposed to library consumers.
///
/// This abstraction allows swapping the underlying database implementation
/// (e.g., from Hive to Realm or SQLite) without changing the repository layer.
abstract class DatabaseService {
  /// Initialize the database.
  Future<void> initialize();

  /// Check if database is initialized.
  bool get isInitialized;

  // MARK: - Chapter (Surah) Operations

  /// Fetch all chapters sorted by number.
  Future<List<Chapter>> fetchAllChapters();

  /// Get a specific chapter by number.
  Future<Chapter?> getChapter(int number);

  /// Get the chapter that appears on a specific page.
  Future<Chapter?> getChapterForPage(int pageNumber);

  /// Get all chapters that appear on a specific page.
  Future<List<Chapter>> getChaptersOnPage(int pageNumber);

  // MARK: - Page Operations

  /// Get a specific page by number.
  Future<Page?> getPage(int number);

  /// Get total number of pages (default 604).
  Future<int> getTotalPages();

  // MARK: - Page Header Operations

  /// Get page header information for a specific page.
  Future<PageHeaderInfo?> getPageHeaderInfo(
    int pageNumber, {
    MushafType mushafType = MushafType.hafs1441,
  });

  // MARK: - Verse Operations

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

  // MARK: - Part (Juz) Operations

  /// Get a specific part by number.
  Future<Part?> getPart(int number);

  /// Get the part for a specific page.
  Future<Part?> getPartForPage(int pageNumber);

  /// Get the part for a specific verse.
  Future<Part?> getPartForVerse(int chapterNumber, int verseNumber);

  /// Fetch all parts sorted by number.
  Future<List<Part>> fetchAllParts();

  // MARK: - Quarter (Hizb) Operations

  /// Get a specific quarter by hizb number and fraction.
  Future<Quarter?> getQuarter(int hizbNumber, int fraction);

  /// Get the quarter for a specific page.
  Future<Quarter?> getQuarterForPage(int pageNumber);

  /// Get the quarter for a specific verse.
  Future<Quarter?> getQuarterForVerse(int chapterNumber, int verseNumber);

  /// Fetch all quarters sorted by hizb number and fraction.
  Future<List<Quarter>> fetchAllQuarters();

  // MARK: - Search Operations

  /// Search verses by query text.
  Future<List<Verse>> searchVerses(String query);

  /// Search chapters by query text.
  Future<List<Chapter>> searchChapters(String query);

  /// Advanced verse search with match modes and Arabic processing options.
  Future<List<Verse>> searchVersesAdvanced(VerseAdvancedSearchQuery query);

  /// Dispose resources.
  Future<void> dispose();
}
