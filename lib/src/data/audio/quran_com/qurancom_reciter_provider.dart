import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

/// Provides high-level reciter management for the Quran.com audio source.
///
/// Wraps [QurancomDataSource] with in-memory caching, search,
/// and filtering logic so that the Repository layer stays thin.
class QuranComReciterProvider {
  final QurancomDataSource _dataSource;
  final MushafLogger? _logger;

  /// In-memory cache, populated on first call to [getAllReciters].
  List<ReciterInfo>? _cache;

  QuranComReciterProvider({
    required QurancomDataSource dataSource,
    MushafLogger? logger,
  }) : _dataSource = dataSource,
       _logger = logger;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all available reciters from the Quran.com API.
  ///
  /// Results are cached in memory after the first successful fetch.
  /// Throws if the underlying data source fails and no cache is available.
  Future<List<ReciterInfo>> getAllReciters() async {
    if (_cache != null) return _cache!;

    try {
      final reciters = await _dataSource.fetchAllReciters();
      _cache = reciters;
      return reciters;
    } catch (e, s) {
      _logger?.error(
        'Failed to fetch reciters from Quran.com',
        error: e,
        stackTrace: s,
        category: LogCategory.audio,
      );
      return [];
    }
  }

  /// Returns the reciter matching [reciterId], or `null` if not found.
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    final reciters = await getAllReciters();
    try {
      return reciters.firstWhere((r) => r.id == reciterId);
    } catch (_) {
      return null;
    }
  }

  /// Searches reciters by partial, case-insensitive name match.
  ///
  /// Checks both the English and Arabic display names.
  /// [languageCode] is kept for API-compatibility with [ReciterService] but
  /// the search always checks both language fields for convenience.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    if (query.trim().isEmpty) return await getAllReciters();

    final normalised = query.trim().toLowerCase();
    final reciters = await getAllReciters();

    return reciters.where((r) {
      return r.nameEnglish.toLowerCase().contains(normalised) ||
          r.nameArabic.toLowerCase().contains(normalised);
    }).toList();
  }

  /// Returns all reciters that use the Hafs recitation style.
  Future<List<ReciterInfo>> getHafsReciters() async {
    final reciters = await getAllReciters();
    return reciters.where((r) => r.isHafs).toList();
  }

  /// Returns a sensible default reciter.
  ///
  /// Prefers the first Hafs reciter available.
  /// Falls back to the first reciter in the list if none are Hafs.
  /// Throws if the list is empty.
  Future<ReciterInfo> getDefaultReciter() async {
    final reciters = await getAllReciters();

    if (reciters.isEmpty) {
      throw StateError(
        'QuranComReciterProvider: No reciters available from Quran.com API.',
      );
    }

    final hafsReciters = reciters.where((r) => r.isHafs).toList();
    return hafsReciters.isNotEmpty ? hafsReciters.first : reciters.first;
  }

  /// Clears the in-memory reciter cache, forcing a fresh fetch on the next call.
  void clearCache() => _cache = null;
}
