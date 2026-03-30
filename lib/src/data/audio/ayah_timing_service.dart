import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:imad_flutter/imad_flutter.dart';

import 'mushaf_audio_data_source.dart';

/// Service for loading and querying verse timing data for audio sync.
/// Internal implementation.
class AyahTimingService {
  final Map<int, ReciterTiming> _timingCache = {};

  /// Cache for dynamically fetched chapter timings (not from bulk JSON assets).
  /// Keyed by reciterId -> chapterNumber.
  final Map<int, Map<int, List<AyahTiming>>> _dynamicChapterCache = {};

  final MushafAudioDataSource? _dataSource;

  AyahTimingService({MushafAudioDataSource? dataSource})
    : _dataSource = dataSource;

  /// Load timing data for a specific reciter from assets.
  Future<ReciterTiming?> loadTimingData(int reciterId) async {
    if (_timingCache.containsKey(reciterId)) {
      return _timingCache[reciterId];
    }

    try {
      final jsonString = await rootBundle.loadString(
        'packages/imad_flutter/assets/ayah_timing/read_$reciterId.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final timing = ReciterTiming.fromJson(json);
      _timingCache[reciterId] = timing;
      return timing;
    } catch (e) {
      return null;
    }
  }

  /// Get verse timing for a specific ayah.
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    final timings = await getChapterTimings(reciterId, chapterNumber);
    if (timings.isEmpty) return null;
    final timing = await loadTimingData(reciterId);
    if (timing == null) {
      MushafLibrary.logger.debug(
        '[AyahTimingService] ❌ No timing data for reciter=$reciterId',
      );
      return timings.firstWhereOrNull((a) => a.ayah == ayahNumber);
    }
    try {
      final chapter = timing.chapters.firstWhere((c) => c.id == chapterNumber);
      final ayah = chapter.ayaTiming.firstWhere((a) => a.ayah == ayahNumber);

      // DEBUG: print what we found
      MushafLibrary.logger.debug(
        '[AyahTimingService] getAyahTiming → '
        'reciter=$reciterId, chapter=$chapterNumber, ayah=$ayahNumber → '
        'start=${ayah.startTime}ms, end=${ayah.endTime}ms',
      );
      if (kDebugMode) {
        // DEBUG: also print surrounding ayahs for context
        final idx = chapter.ayaTiming.indexOf(ayah);
        for (
          int i = (idx - 2).clamp(0, chapter.ayaTiming.length - 1);
          i <= (idx + 2).clamp(0, chapter.ayaTiming.length - 1);
          i++
        ) {
          final t = chapter.ayaTiming[i];
          final marker = t.ayah == ayahNumber ? ' ◄◄◄' : '';
          MushafLibrary.logger.debug(
            '[AyahTimingService]   [$i] ayah=${t.ayah}, '
            'start=${t.startTime}ms, end=${t.endTime}ms$marker',
          );
        }
      }

      return ayah;
    } catch (_) {
      MushafLibrary.logger.debug(
        '[AyahTimingService] ❌ ayah=$ayahNumber not found in chapter=$chapterNumber',
      );
      return null;
    }
  }

  /// Get the current verse being recited based on playback position.
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    final timings = await getChapterTimings(reciterId, chapterNumber);
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
    int reciterId,
    int chapterNumber,
  ) async {
    // 1. Check if the entire reciter profile is already cached (bulk JSON)
    if (_timingCache.containsKey(reciterId)) {
      try {
        final chapter = _timingCache[reciterId]!.chapters.firstWhere(
          (c) => c.id == chapterNumber,
        );
        return chapter.ayaTiming;
      } catch (_) {
        // Not in this bulk file, but continue to other sources
      }
    }

    // 2. Check if this specific chapter was dynamically fetched and cached
    if (_dynamicChapterCache[reciterId]?.containsKey(chapterNumber) ?? false) {
      return _dynamicChapterCache[reciterId]![chapterNumber]!;
    }

    // 3. Try loading from local assets (first-time load for bulk JSON)
    final bulkTiming = await loadTimingData(reciterId);
    if (bulkTiming != null) {
      try {
        final chapter = bulkTiming.chapters.firstWhere(
          (c) => c.id == chapterNumber,
        );
        return chapter.ayaTiming;
      } catch (_) {
        // Asset exists but lacks this chapter
      }
    }

    // 4. Fallback: Fetch from MushafAudioDataSource (e.g., Quran.com API)
    final dataSource = _dataSource;
    if (dataSource != null) {
      try {
        final remoteTimings = await dataSource.fetchChapterTiming(
          reciterId,
          chapterNumber,
        );
        if (remoteTimings != null) {
          // Cache the dynamic result
          _dynamicChapterCache.putIfAbsent(reciterId, () => {})[chapterNumber] =
              remoteTimings;
          return remoteTimings;
        }
      } catch (e) {
        // Fallback to empty list gracefully so the audio player doesn't crash
        return [];
      }
    }

    return [];
  }

  /// Check if timing data is available for a reciter.
  bool hasTimingForReciter(int reciterId) {
    return _timingCache.containsKey(reciterId);
  }

  /// Preload timing data for better performance.
  Future<void> preloadTiming(int reciterId) async {
    await loadTimingData(reciterId);
  }
}
