import 'dart:async';
import 'package:collection/collection.dart';

import 'package:imad_flutter/imad_flutter.dart';

import 'mushaf_audio_data_source.dart';

/// Service for loading and querying verse timing data for audio sync.
/// Internal implementation.
class AyahTimingService {
  /// Cache for dynamically fetched chapter timings.
  /// Keyed by reciterId -> chapterNumber.
  final Map<int, Map<int, List<AyahTiming>>> _dynamicChapterCache = {};

  final MushafAudioDataSource? _dataSource;

  AyahTimingService({MushafAudioDataSource? dataSource})
    : _dataSource = dataSource;

  /// Get verse timing for a specific ayah.
  Future<AyahTiming?> getAyahTiming(
    int recitationId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    final timings = await getChapterTimings(recitationId, chapterNumber);
    if (timings.isEmpty) return null;

    return timings.firstWhereOrNull((a) => a.ayah == ayahNumber);
  }

  /// Get the current verse being recited based on playback position.
  Future<int?> getCurrentVerse(
    int recitationId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    final timings = await getChapterTimings(recitationId, chapterNumber);
    if (timings.isEmpty) return null;

    for (final timing in timings) {
      if (currentTimeMs >= timing.startTime && currentTimeMs < timing.endTime) {
        return timing.ayah;
      }
    }
    return null;
  }

  /// Get all timing data for a chapter.
  /// This method implements a "Local-First -> API-Fallback" strategy.
  Future<List<AyahTiming>> getChapterTimings(
    int recitationId,
    int chapterNumber,
  ) async {
    // 1. Check if this specific chapter was dynamically fetched and cached
    if (_dynamicChapterCache[recitationId]?.containsKey(chapterNumber) ??
        false) {
      return _dynamicChapterCache[recitationId]![chapterNumber]!;
    }

    // 2. Fetch from MushafAudioDataSource (e.g., MP3Quran API or Quran.com API)
    final dataSource = _dataSource;
    if (dataSource != null) {
      try {
        final remoteTimings = await dataSource.fetchChapterTiming(
          recitationId,
          chapterNumber,
        );
        if (remoteTimings != null) {
          // Cache the dynamic result in memory
          _dynamicChapterCache.putIfAbsent(
            recitationId,
            () => {},
          )[chapterNumber] = remoteTimings;
          return remoteTimings;
        }
      } catch (e) {
        MushafLibrary.logger.debug(
          '[AyahTimingService] Error fetching timing dynamically: $e',
        );
        // Fallback to empty list gracefully so the audio player doesn't crash
        return [];
      }
    }

    return [];
  }

  /// Check if timing data is available for a recitation.
  bool hasTimingForRecitation(int recitationId) {
    // With dynamic fetching, assume true if we have a data source
    return _dataSource != null;
  }

  /// Preload timing data for better performance.
  Future<void> preloadTiming(int recitationId) async {
    // Dynamic preloading is handled by the data source or client cache.
  }
}
