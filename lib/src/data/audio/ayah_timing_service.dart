import 'dart:async';

import '../../domain/models/reciter_timing.dart';
import 'audio_source_config.dart';

/// Service for loading and querying verse timing data for audio sync.
/// Internal implementation.
class AyahTimingService {
  final MushafAudioDataSource _audioDataSource;
  final Map<int, ReciterTiming> _timingCache = {};

  AyahTimingService(this._audioDataSource);

  /// Load timing data for a specific reciter from assets.
  Future<ReciterTiming?> loadTimingData(int reciterId) async {
    if (_timingCache.containsKey(reciterId)) {
      return _timingCache[reciterId];
    }

    try {
      final timing = await _audioDataSource.fetchReciterTiming(reciterId);
      if (timing == null) return null;
      _timingCache[reciterId] = timing;
      return timing;
    } catch (_) {
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
    if (timing == null) return null;

    try {
      final chapter = timing.chapters.firstWhere((c) => c.id == chapterNumber);
      return chapter.ayaTiming.firstWhere((a) => a.ayah == ayahNumber);
    } catch (_) {
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
