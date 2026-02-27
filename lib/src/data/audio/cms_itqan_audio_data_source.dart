import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import 'audio_source_config.dart';

/// CMS-backed source for reciters, chapter audio URLs, and ayah timings.
class CmsItqanAudioDataSource implements MushafAudioDataSource {
  final CmsAudioSourceConfig _config;
  final http.Client _client;

  List<ReciterInfo>? _recitersCache;
  final Map<int, ReciterInfo> _recitersById = {};
  final Map<int, List<_CmsTrack>> _tracksByAssetId = {};

  CmsItqanAudioDataSource({
    CmsAudioSourceConfig config = const CmsAudioSourceConfig(),
    http.Client? client,
  }) : _config = config,
       _client = client ?? http.Client();

  @override
  Future<List<ReciterInfo>> fetchAllReciters() async {
    if (_recitersCache != null) return _recitersCache!;

    final rows = await _fetchPaged('/recitations/');
    final reciters = <ReciterInfo>[];

    for (final row in rows) {
      final id = _asInt(row['id']);
      if (id == null) continue;

      final reciterJson = row['reciter'];
      final riwayahJson = row['riwayah'];

      final reciterName = reciterJson is Map<String, dynamic>
          ? (reciterJson['name']?.toString() ?? 'Unknown Reciter')
          : 'Unknown Reciter';

      final riwayahName = riwayahJson is Map<String, dynamic>
          ? (riwayahJson['name']?.toString() ?? 'Unknown Riwayah')
          : 'Unknown Riwayah';

      final reciter = ReciterInfo(
        id: id,
        nameArabic: reciterName,
        nameEnglish: reciterName,
        rewaya: riwayahName,
        folderUrl: '',
      );

      reciters.add(reciter);
      _recitersById[id] = reciter;
    }

    _recitersCache = reciters;
    return reciters;
  }

  @override
  Future<ReciterTiming?> fetchReciterTiming(int reciterId) async {
    final reciter = await _getReciterById(reciterId);
    if (reciter == null) return null;

    final tracks = await _fetchTracksForAsset(reciterId);
    if (tracks.isEmpty) return null;

    final chapters = tracks.map((track) {
      final ayahTiming = track.ayahTimings
          .map(
            (timing) => AyahTiming(
              ayah: timing.ayah,
              startTime: timing.startMs,
              endTime: timing.endMs,
            ),
          )
          .toList();

      return ChapterTiming(
        id: track.surahNumber,
        name: track.surahName,
        ayaTiming: ayahTiming,
      );
    }).toList()..sort((a, b) => a.id.compareTo(b.id));

    return ReciterTiming(
      id: reciter.id,
      name: reciter.nameArabic,
      nameEn: reciter.nameEnglish,
      rewaya: reciter.rewaya,
      folderUrl: reciter.folderUrl,
      chapters: chapters,
    );
  }

  @override
  Future<String?> fetchChapterAudioUrl(int reciterId, int chapterNumber) async {
    final tracks = await _fetchTracksForAsset(reciterId);
    for (final track in tracks) {
      if (track.surahNumber == chapterNumber) {
        return track.audioUrl;
      }
    }
    return null;
  }

  Future<ReciterInfo?> _getReciterById(int reciterId) async {
    if (_recitersById.containsKey(reciterId)) {
      return _recitersById[reciterId];
    }

    final all = await fetchAllReciters();
    for (final reciter in all) {
      if (reciter.id == reciterId) return reciter;
    }
    return null;
  }

  Future<List<_CmsTrack>> _fetchTracksForAsset(int assetId) async {
    if (_tracksByAssetId.containsKey(assetId)) {
      return _tracksByAssetId[assetId]!;
    }

    final rows = await _fetchPaged('/recitations/$assetId/');
    final tracks = <_CmsTrack>[];

    for (final row in rows) {
      final surahNumber = _asInt(row['surah_number']);
      final audioUrl = row['audio_url']?.toString();
      if (surahNumber == null || audioUrl == null || audioUrl.isEmpty) {
        continue;
      }

      final ayahsTimings = row['ayahs_timings'];
      final ayahTimings = <_CmsAyahTiming>[];
      if (ayahsTimings is List<dynamic>) {
        for (final value in ayahsTimings) {
          if (value is! Map<String, dynamic>) continue;
          final ayahNumber = _parseAyahKey(value['ayah_key']?.toString());
          final startMs = _asInt(value['start_ms']);
          final endMs = _asInt(value['end_ms']);

          if (ayahNumber == null || startMs == null || endMs == null) continue;

          ayahTimings.add(
            _CmsAyahTiming(ayah: ayahNumber, startMs: startMs, endMs: endMs),
          );
        }
      }

      tracks.add(
        _CmsTrack(
          surahNumber: surahNumber,
          surahName:
              row['surah_name']?.toString() ??
              row['surah_name_en']?.toString() ??
              'Surah $surahNumber',
          audioUrl: audioUrl,
          ayahTimings: ayahTimings,
        ),
      );
    }

    _tracksByAssetId[assetId] = tracks;
    return tracks;
  }

  Future<List<Map<String, dynamic>>> _fetchPaged(String path) async {
    final result = <Map<String, dynamic>>[];
    var page = 1;
    final pageSize = _config.pageSize;

    while (true) {
      final uri = Uri.parse(
        '${_config.apiBaseUrl}$path',
      ).replace(queryParameters: {'page': '$page', 'page_size': '$pageSize'});

      final response = await _client.get(uri).timeout(_config.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'CMS request failed (${response.statusCode}) for ${uri.path}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('CMS response is not a JSON object');
      }

      final rows = decoded['results'];
      final count = _asInt(decoded['count']);
      if (rows is! List<dynamic>) {
        throw const FormatException('CMS response is missing results list');
      }

      for (final row in rows) {
        if (row is Map<String, dynamic>) result.add(row);
      }

      if (rows.isEmpty) {
        break;
      }
      if (count != null && result.length >= count) {
        break;
      }
      if (count == null && rows.length < pageSize) {
        break;
      }
      page += 1;
    }

    return result;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? _parseAyahKey(String? ayahKey) {
    if (ayahKey == null || ayahKey.isEmpty) return null;
    final parts = ayahKey.split(':');
    final raw = parts.length == 2 ? parts[1] : parts[0];
    return int.tryParse(raw);
  }
}

class _CmsTrack {
  final int surahNumber;
  final String surahName;
  final String audioUrl;
  final List<_CmsAyahTiming> ayahTimings;

  const _CmsTrack({
    required this.surahNumber,
    required this.surahName,
    required this.audioUrl,
    required this.ayahTimings,
  });
}

class _CmsAyahTiming {
  final int ayah;
  final int startMs;
  final int endMs;

  const _CmsAyahTiming({
    required this.ayah,
    required this.startMs,
    required this.endMs,
  });
}
