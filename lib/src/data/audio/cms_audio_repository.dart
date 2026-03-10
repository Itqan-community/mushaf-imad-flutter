import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import '../../domain/repository/audio_repository.dart';
import '../../mushaf_library.dart';
import '../audio/flutter_audio_player.dart';
import 'cms_audio_config.dart';
import 'cms_audio_models.dart';

/// CMS-based implementation of AudioRepository.
class CmsAudioRepository implements AudioRepository {
  final CmsAudioConfig _config;
  final FlutterAudioPlayer _audioPlayer;
  final http.Client? client;

  // In-memory cache for API responses
  final Map<int, List<ReciterInfo>> _recitersCache = {};
  
  // Maps reciter ID to their primary recitation asset ID
  final Map<int, int> _reciterToAssetCache = {};
  
  // Maps asset ID to a list of surah tracks
  final Map<int, List<CmsRecitationSurahTrack>> _tracksCache = {};
  
  // Track selected reciter
  final _selectedReciterStream = StreamController<ReciterInfo?>.broadcast();

  // Track the current chapter timing for highlighting
  List<AyahTiming> _currentChapterTimings = [];

  CmsAudioRepository(
    this._config,
    this._audioPlayer, {
    this.client,
  });

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) {
    if (client != null) {
      return client!.get(url, headers: headers);
    }
    return http.get(url, headers: headers);
  }

  @override
  Future<List<ReciterInfo>> getAllReciters() async {
    // Note: If /reciters/ endpoint is fully implemented in CMS we'd fetch here.
    // As per instructions, we map what we need. For demonstration, we could return a 
    // basic list or fetch from API. We'll implement a basic fetch.
    try {
      final response = await _get(
        Uri.parse('${_config.baseUrl}/reciters/'),
        headers: _config.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        
        final reciters = results.map((json) {
          return ReciterInfo(
            id: json['id'] as int,
            nameArabic: json['name'] as String? ?? 'غير معروف',
            nameEnglish: json['name'] as String? ?? 'Unknown',
            rewaya: 'Various', // Riwayah info now lives in asset, use generic
            folderUrl: '', // URL is fetched per recitation in CMS
          );
        }).toList();
        
        _recitersCache[1] = reciters;
        return reciters;
      }
    } catch (e) {
      MushafLibrary.logger.error('[CmsAudioRepository] Error fetching reciters: $e');
    }
    
    // Fallback if API fails or doesn't match
    return [
      ReciterInfo(
        id: _config.defaultReciterId,
        nameArabic: 'مقرئ CMS',
        nameEnglish: 'CMS Reciter',
        rewaya: 'Hafs',
        folderUrl: '',
      ),
    ];
  }

  @override
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    final reciters = await getAllReciters();
    try {
      return reciters.firstWhere((r) => r.id == reciterId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    final reciters = await getAllReciters();
    final normalizedQuery = query.toLowerCase();
    
    return reciters.where((r) {
      if (languageCode == 'ar') {
        return r.nameArabic.contains(normalizedQuery);
      }
      return r.nameEnglish.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<List<ReciterInfo>> getHafsReciters() async {
    final reciters = await getAllReciters();
    return reciters.where((r) => r.isHafs).toList();
  }

  @override
  Future<ReciterInfo> getDefaultReciter() async {
    final reciters = await getAllReciters();
    if (reciters.isNotEmpty) return reciters.first;
    
    return ReciterInfo(
      id: _config.defaultReciterId,
      nameArabic: 'مقرئ الافتراضي',
      nameEnglish: 'Default Reciter',
      rewaya: 'Hafs',
      folderUrl: '',
    );
  }

  @override
  void saveSelectedReciter(ReciterInfo reciter) {
    _selectedReciterStream.add(reciter);
  }

  @override
  Stream<ReciterInfo?> getSelectedReciterStream() =>
      _selectedReciterStream.stream;

  @override
  Stream<AudioPlayerState> getPlayerStateStream() async* {
    await for (final state in _audioPlayer.domainStateStream) {
      int? verse;
      
      // Calculate current verse using in-memory timings from the CMS response
      if (_currentChapterTimings.isNotEmpty) {
        for (final timing in _currentChapterTimings) {
          if (state.currentPositionMs >= timing.startTime && 
              state.currentPositionMs < timing.endTime) {
            verse = timing.ayah;
            break;
          }
        }
      }

      yield state.copyWith(currentVerse: verse);
    }
  }

  // Helper to fetch the primary recitation asset ID for a reciter
  Future<int?> _fetchAssetIdForReciter(int reciterId) async {
    if (_reciterToAssetCache.containsKey(reciterId)) {
      return _reciterToAssetCache[reciterId]!;
    }
    
    try {
      final endpoint = '${_config.baseUrl}/recitations/?reciter_id=$reciterId';
      final response = await _get(Uri.parse(endpoint), headers: _config.headers);
      
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
      MushafLibrary.logger.error('[CmsAudioRepository] Error fetching asset for reciter $reciterId: $e');
    }
    return null;
  }

  @override
  void loadChapter(
    int chapterNumber,
    int reciterId, {
    bool autoPlay = false,
  }) async {
    try {
      final assetId = await _fetchAssetIdForReciter(reciterId);
      if (assetId == null) {
        throw Exception('No recitation asset found for reciter $reciterId');
      }

      List<CmsRecitationSurahTrack> tracks;

      if (_tracksCache.containsKey(assetId)) {
        tracks = _tracksCache[assetId]!;
      } else {
        // Fetch tracks from the CMS API for this asset
        final endpoint = '${_config.baseUrl}/recitations/$assetId/?page_size=114';
        final response = await _get(Uri.parse(endpoint), headers: _config.headers);
        
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final results = json['results'] as List<dynamic>? ?? [];
          tracks = results.map((e) => CmsRecitationSurahTrack.fromJson(e)).toList();
          _tracksCache[assetId] = tracks;
        } else {
          throw Exception('Failed to load recitation tracks: ${response.statusCode}');
        }
      }

      // Find the specific surah track
      final surahTrack = tracks.firstWhere(
        (t) => t.surahNumber == chapterNumber,
        orElse: () => throw Exception('Surah $chapterNumber not found in track list'),
      );

      // Map timestamps to library AyahTiming model
      _currentChapterTimings = surahTrack.ayahsTimings
          .map((t) => t.toAyahTiming())
          .toList();

      final reciter = await getReciterById(reciterId) ?? 
          await getDefaultReciter();

      // Pass the audio URL to the flutter audio player
      await _audioPlayer.loadFromUrl(
        surahTrack.audioUrl,
        chapterNumber: chapterNumber,
        reciter: reciter,
        autoPlay: autoPlay,
      );
      
    } catch (e) {
      MushafLibrary.logger.error('[CmsAudioRepository] Error loading chapter from CMS: $e');
    }
  }

  @override
  void play() => _audioPlayer.play();

  @override
  void pause() => _audioPlayer.pause();

  @override
  void stop() => _audioPlayer.stop();

  @override
  void seekTo(int positionMs) =>
      _audioPlayer.seek(Duration(milliseconds: positionMs));

  @override
  void setPlaybackSpeed(double speed) => _audioPlayer.setSpeed(speed);

  @override
  void setRepeatMode(bool enabled) => _audioPlayer.setRepeatModeBool(enabled);

  @override
  bool isRepeatEnabled() => _audioPlayer.isRepeatMode();

  @override
  int getCurrentPosition() => 0;

  @override
  int getDuration() => 0;

  @override
  bool isCurrentlyPlaying() => false;

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
  Future<List<AyahTiming>> getChapterTimings(
    int reciterId,
    int chapterNumber,
  ) async {
    return _currentChapterTimings;
  }

  @override
  bool hasTimingForReciter(int reciterId) {
    // CMS always implies timing is available via API payload
    return true; 
  }

  @override
  Future<void> preloadTiming(int reciterId) async {
    // Preload not strictly needed for CMS since it comes with the audio play request,
    // or could fetch the full JSON ahead of time here.
  }

  @override
  void release() {
    _audioPlayer.stop();
    _selectedReciterStream.close();
  }
}
