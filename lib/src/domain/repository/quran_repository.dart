import '../models/cache_stats.dart';
import '../models/part.dart';
import '../models/quarter.dart';

/// Repository for general Quran data operations.
/// Public API - exposed to library consumers.
abstract class QuranRepository {
  /// Initialize the Quran database.
  Future<void> initialize();

  /// Check if the database is initialized.
  bool isInitialized();

  // Part (Juz) Operations

  /// Get all parts (30 Juz).
  Future<List<Part>> getAllParts();

  /// Get a specific part by number.
  Future<Part?> getPart(int number);

  /// Get the part for a specific page.
  Future<Part?> getPartForPage(int pageNumber);

  /// Get the part for a specific verse.
  Future<Part?> getPartForVerse(int chapterNumber, int verseNumber);

  // Quarter (Hizb) Operations

  /// Get all quarters (Hizb fractions).
  Future<List<Quarter>> getAllQuarters();

  /// Get a specific quarter by hizb number and fraction.
  Future<Quarter?> getQuarter(int hizbNumber, int fraction);

  /// Get the quarter for a specific page.
  Future<Quarter?> getQuarterForPage(int pageNumber);

  /// Get the quarter for a specific verse.
  Future<Quarter?> getQuarterForVerse(int chapterNumber, int verseNumber);

  // Cache Management

  /// Get cache statistics.
  Future<CacheStats> getCacheStats();

  /// Clear all caches.
  Future<void> clearAllCaches();
}
