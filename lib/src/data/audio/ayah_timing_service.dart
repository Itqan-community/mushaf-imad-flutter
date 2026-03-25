import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:imad_flutter/imad_flutter.dart';

/// Service for loading and querying verse timing data for audio sync.
/// Internal implementation.
class AyahTimingService {
  final Map<int, ReciterTiming> _timingCache = {};

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
    final timing = await loadTimingData(reciterId);
    if (timing == null) {
      MushafLibrary.logger.debug(
        '[AyahTimingService] ❌ No timing data for reciter=$reciterId',
      );
      return null;
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
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) async {
    final timing = await loadTimingData(reciterId);
    if (timing == null) return [];

    try {
      final chapter = timing.chapters.firstWhere((c) => c.id == chapterNumber);
      return chapter.ayaTiming;
    } catch (_) {
      return [];
    }
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
