import 'package:imad_flutter/src/data/audio/base/audio_recitation_provider.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/domain/models/audio_source.dart';
import 'package:imad_flutter/src/domain/models/recitation.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

/// Provides high-level recitation management for the Quran.com audio source.
///
/// Wraps [QurancomDataSource] with in-memory caching, search,
/// and filtering logic so that the Repository layer stays thin.
class QuranComRecitationProvider implements AudioRecitationProvider {
  final QurancomDataSource _dataSource;
  final MushafLogger? _logger;

  /// In-memory cache, populated on first call to [getAllRecitations].
  List<Recitation>? _cache;

  QuranComRecitationProvider({
    required QurancomDataSource dataSource,
    MushafLogger? logger,
  }) : _dataSource = dataSource,
       _logger = logger;

  // ---------------------------------------------------------------------------
  // AudioRecitationProvider
  // ---------------------------------------------------------------------------

  @override
  MushafAudioSource get source => MushafAudioSource.quranCom;

  /// Returns all available recitations from the Quran.com API.
  ///
  /// Results are cached in memory after the first successful fetch.
  /// Throws if the underlying data source fails and no cache is available.
  @override
  Future<List<Recitation>> getAllRecitations() async {
    if (_cache != null) return _cache!;

    try {
      final recitations = await _dataSource.fetchAllRecitations();
      _cache = recitations;
      return _cache!;
    } catch (e, s) {
      _logger?.error(
        'Failed to fetch recitations from Quran.com',
        error: e,
        stackTrace: s,
        category: LogCategory.audio,
      );
      return [];
    }
  }

  /// Returns the recitation matching [recitationId], or `null` if not found.
  @override
  Future<Recitation?> getRecitationById(int recitationId) async {
    final recitations = await getAllRecitations();
    return recitations.where((r) => r.id == recitationId).firstOrNull;
  }

  /// Searches recitations by partial, case-insensitive name match.
  ///
  /// Checks both the English and Arabic display names for reciter and riwayah.
  @override
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) async {
    if (query.trim().isEmpty) return await getAllRecitations();

    final normalised = query.trim().toLowerCase();
    final recitations = await getAllRecitations();

    return recitations.where((r) {
      if (languageCode == 'ar') {
        return r.reciter.nameArabic.contains(normalised) ||
            r.riwayah.nameArabic.contains(normalised);
      }
      return r.reciter.nameEnglish.toLowerCase().contains(normalised) ||
          r.riwayah.nameEnglish.toLowerCase().contains(normalised);
    }).toList();
  }

  /// Returns a sensible default recitation.
  ///
  /// Throws if the list is empty.
  @override
  Future<Recitation> getDefaultRecitation() async {
    final recitations = await getAllRecitations();

    if (recitations.isEmpty) {
      throw StateError(
        'QuranComRecitationProvider: No recitations available from Quran.com API.',
      );
    }
    return recitations.first;
  }

  /// Clears the in-memory recitation cache, forcing a fresh fetch on the next call.
  void clearCache() => _cache = null;
}
