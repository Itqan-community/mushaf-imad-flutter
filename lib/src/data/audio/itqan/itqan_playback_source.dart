import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_info.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../mushaf_library.dart';
import '../base/audio_playback_source.dart';
import '../flutter_audio_player.dart';
import 'itqan_audio_config.dart';
import 'itqan_audio_models.dart';
import 'itqan_reciter_provider.dart';

/// [AudioPlaybackSource] implementation for the Itqan CMS API.
///
/// Fetches recitation tracks (audio URL + ayah timings) from the CMS
/// `/recitations/` endpoints and drives playback via the shared
/// [FlutterAudioPlayer].
class ItqanPlaybackSource implements AudioPlaybackSource {
  final ItqanAudioConfig _config;
  final ItqanReciterProvider _reciterProvider;
  final FlutterAudioPlayer _audioPlayer;
  final http.Client? _client;

  // Maps reciter ID -> primary recitation asset ID.
  final Map<int, int> _reciterToAssetCache = {};

  // Maps asset ID -> list of surah tracks.
  final Map<int, List<ItqanRecitationSurahTrack>> _tracksCache = {};

  // In-memory ayah timings for the currently loaded chapter.
  List<AyahTiming> _currentChapterTimings = [];

  ItqanPlaybackSource({
    required ItqanAudioConfig config,
    required ItqanReciterProvider reciterProvider,
    required FlutterAudioPlayer audioPlayer,
    http.Client? client,
  }) : _config = config,
       _reciterProvider = reciterProvider,
       _audioPlayer = audioPlayer,
       _client = client;

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) {
    if (_client != null) return _client.get(url, headers: headers);
    return http.get(url, headers: headers);
  }

  @override
  MushafAudioSource get source => MushafAudioSource.itqan;

  // ---------------------------------------------------------------------------
  // AudioPlaybackSource
  // ---------------------------------------------------------------------------

  @override
  Future<void> loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    try {
      final assetId = await _fetchAssetIdForReciter(reciterId);
      if (assetId == null) {
        throw Exception('No recitation asset found for reciter $reciterId');
      }

      List<ItqanRecitationSurahTrack> tracks;

      if (_tracksCache.containsKey(assetId)) {
        tracks = _tracksCache[assetId]!;
      } else {
        final endpoint =
            '${_config.baseUrl}/recitations/$assetId/?page_size=114';
        final response = await _get(
          Uri.parse(endpoint),
          headers: _config.headers,
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final results = json['results'] as List<dynamic>? ?? [];
          tracks = results
              .map((e) => ItqanRecitationSurahTrack.fromJson(e))
              .toList();
          _tracksCache[assetId] = tracks;
        } else {
          throw Exception(
            'Failed to load recitation tracks: ${response.statusCode}',
          );
        }
      }

      final surahTrack = tracks.firstWhere(
        (t) => t.surahNumber == chapterNumber,
        orElse: () =>
            throw Exception('Surah $chapterNumber not found in track list'),
      );

      _currentChapterTimings = surahTrack.ayahsTimings
          .map((t) => t.toAyahTiming())
          .toList();

      final ReciterInfo reciter =
          await _reciterProvider.getReciterById(reciterId) ??
          await _reciterProvider.getDefaultReciter();

      await _audioPlayer.loadFromUrl(
        surahTrack.audioUrl,
        chapterNumber: chapterNumber,
        reciter: reciter,
        autoPlay: false,
      );

      if (startVerseNumber > 1) {
        try {
          final timing = _currentChapterTimings.firstWhere(
            (a) => a.ayah == startVerseNumber,
          );
          MushafLibrary.logger.debug(
            '[ItqanPlaybackSource] Seeking to verse=$startVerseNumber '
            'at ${timing.startTime}ms',
          );
          await _audioPlayer.seek(Duration(milliseconds: timing.startTime));
        } catch (_) {
          await _audioPlayer.seek(Duration.zero);
        }
      } else {
        await _audioPlayer.seek(Duration.zero);
      }

      if (autoPlay) await _audioPlayer.play();
    } catch (e) {
      MushafLibrary.logger.error(
        '[ItqanPlaybackSource] Error loading chapter: $e',
      );
    }
  }

  @override
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) async => _currentChapterTimings;

  @override
  Future<AyahTiming?> getAyahTiming(
    int reciterId,
    int chapterNumber,
    int ayahNumber,
  ) async {
    try {
      return _currentChapterTimings.firstWhere((a) => a.ayah == ayahNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getCurrentVerse(
    int reciterId,
    int chapterNumber,
    int currentTimeMs,
  ) async {
    for (final timing in _currentChapterTimings) {
      if (currentTimeMs >= timing.startTime && currentTimeMs < timing.endTime) {
        return timing.ayah;
      }
    }
    return null;
  }

  @override
  bool hasTimingForReciter(int reciterId) =>
      // Itqan always provides timing via the API payload.
      true;

  @override
  Future<void> preloadTiming(int reciterId) async {
    // Timing is bundled with the audio load request -- no separate preload needed.
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<int?> _fetchAssetIdForReciter(int reciterId) async {
    if (_reciterToAssetCache.containsKey(reciterId)) {
      return _reciterToAssetCache[reciterId]!;
    }

    try {
      final endpoint =
          '${_config.baseUrl}/recitations/?reciter_id=$reciterId';
      final response = await _get(
        Uri.parse(endpoint),
        headers: _config.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final assetId = results.first['id'] as int;
          _reciterToAssetCache[reciterId] = assetId;
          return assetId;
        }
      }
    } catch (e) {
      MushafLibrary.logger.error(
        '[ItqanPlaybackSource] Error fetching asset for reciter $reciterId: $e',
      );
    }
    return null;
  }
}
