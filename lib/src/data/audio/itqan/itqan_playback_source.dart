import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../domain/models/audio_source.dart';
import '../../../domain/models/recitation.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../mushaf_library.dart';
import '../base/audio_playback_source.dart';
import '../flutter_audio_player.dart';
import 'itqan_audio_config.dart';
import 'itqan_audio_models.dart';
import 'itqan_recitation_provider.dart';

/// [AudioPlaybackSource] implementation for the Itqan CMS API.
///
/// Fetches recitation tracks (audio URL + ayah timings) from the CMS
/// `/recitations/` endpoints and drives playback via the shared
/// [FlutterAudioPlayer].
class ItqanPlaybackSource implements AudioPlaybackSource {
  final ItqanAudioConfig _config;
  final ItqanRecitationProvider _recitationProvider;
  final FlutterAudioPlayer _audioPlayer;
  final http.Client? _client;

  // Maps recitation ID -> list of surah tracks.
  final Map<int, List<ItqanRecitationSurahTrack>> _tracksCache = {};

  // In-memory ayah timings for the currently loaded chapter.
  List<AyahTiming> _currentChapterTimings = [];

  ItqanPlaybackSource({
    required ItqanAudioConfig config,
    required ItqanRecitationProvider recitationProvider,
    required FlutterAudioPlayer audioPlayer,
    http.Client? client,
  }) : _config = config,
       _recitationProvider = recitationProvider,
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
    int recitationId, {
    bool autoPlay = false,
    int startVerseNumber = 1,
  }) async {
    try {
      List<ItqanRecitationSurahTrack> tracks;

      if (_tracksCache.containsKey(recitationId)) {
        tracks = _tracksCache[recitationId]!;
      } else {
        final endpoint =
            '${_config.baseUrl}/recitations/$recitationId/?page_size=114';
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
          _tracksCache[recitationId] = tracks;
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

      final Recitation recitation =
          await _recitationProvider.getRecitationById(recitationId) ??
          await _recitationProvider.getDefaultRecitation();

      await _audioPlayer.loadFromUrl(
        surahTrack.audioUrl,
        chapterNumber: chapterNumber,
        recitation: recitation,
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
    int recitationId,
    int chapterNumber,
  ) async => _currentChapterTimings;

  @override
  Future<AyahTiming?> getAyahTiming(
    int recitationId,
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
    int recitationId,
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
  bool hasTimingForRecitation(int recitationId) => true;

  @override
  Future<void> preloadTiming(int recitationId) async {
    // Timing is bundled with the audio load request -- no separate preload needed.
  }
}
