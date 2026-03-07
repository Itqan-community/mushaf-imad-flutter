import '../models/cache_stats.dart';
import '../models/part.dart';
import '../models/quarter.dart';
import '../models/result.dart';

/// Repository for general Quran data operations.
/// Public API - exposed to library consumers.
abstract class QuranRepository {
  /// Initialize the Quran database.
  Future<Result<void>> initialize();

  /// Check if the database is initialized.
  bool isInitialized();

  // Part (Juz) Operations

  /// Get all parts (30 Juz).
  Future<Result<List<Part>>> getAllParts();

  /// Get a specific part by number.
  Future<Result<Part?>> getPart(int number);

  /// Get the part for a specific page.
  Future<Result<Part?>> getPartForPage(int pageNumber);

  /// Get the part for a specific verse.
  Future<Result<Part?>> getPartForVerse(int chapterNumber, int verseNumber);

  // Quarter (Hizb) Operations

  /// Get all quarters (Hizb fractions).
  Future<Result<List<Quarter>>> getAllQuarters();

  /// Get a specific quarter by hizb number and fraction.
  Future<Result<Quarter?>> getQuarter(int hizbNumber, int fraction);

  /// Get the quarter for a specific page.
  Future<Result<Quarter?>> getQuarterForPage(int pageNumber);

  /// Get the quarter for a specific verse.
  Future<Result<Quarter?>> getQuarterForVerse(int chapterNumber, int verseNumber);

  // Cache Management

  /// Get cache statistics.
  Future<Result<CacheStats>> getCacheStats();

  /// Clear all caches.
  Future<Result<void>> clearAllCaches();
}

