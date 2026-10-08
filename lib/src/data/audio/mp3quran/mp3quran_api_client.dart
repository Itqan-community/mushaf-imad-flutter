import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/audio_source.dart';
import '../../../domain/models/recitation.dart';
import '../../../domain/models/reciter.dart';
import '../../../domain/models/reciter_timing.dart';
import '../../../domain/models/riwayah.dart';
import '../../../mushaf_library.dart';

/// Resolves the directory used to cache mp3quran responses on disk.
typedef Mp3QuranCacheDirectoryProvider = Future<Directory> Function();

/// HTTP client for the mp3quran.net v3 API.
///
/// Responses are cached on disk. Cache I/O is best-effort: a cache read or
/// write failure never fails a request that the network can satisfy, and only
/// successfully parsed bodies are written to the cache.
class Mp3QuranApiClient {
  static const String _baseUrl = 'https://www.mp3quran.net/api/v3';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _httpClient;
  final bool _internalHttpClient;
  final Mp3QuranCacheDirectoryProvider _cacheDirectoryProvider;

  Mp3QuranApiClient({
    http.Client? httpClient,
    Mp3QuranCacheDirectoryProvider? cacheDirectoryProvider,
  }) : _httpClient = httpClient ?? http.Client(),
       _internalHttpClient = httpClient == null,
       _cacheDirectoryProvider =
           cacheDirectoryProvider ?? _defaultCacheDirectory;

  static Future<Directory> _defaultCacheDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/mushaf_cache/mp3quran');
  }

  void dispose() {
    if (_internalHttpClient) {
      _httpClient.close();
    }
  }

  /// Fetches the list of all reciters (reads) that have ayah timing data.
  ///
  /// Malformed entries are skipped. English reciter and riwayah names are
  /// resolved on a best-effort basis; when unavailable the Arabic name is
  /// used as a fallback.
  Future<List<Recitation>> fetchRecitations() async {
    final reads = await _getJsonList(
      '$_baseUrl/ayat_timing/reads',
      cacheName: 'mp3quran_reads.json',
    );
    final names = await _fetchNameLookups();

    final recitations = <Recitation>[];
    for (final entry in reads) {
      final recitation = _mapToRecitation(entry, names);
      if (recitation != null) recitations.add(recitation);
    }
    return recitations;
  }

  /// Fetches timing for a specific surah and reciter.
  Future<List<AyahTiming>> fetchChapterTiming({
    required int reciterId,
    required int chapterNumber,
  }) async {
    final data = await _getJsonList(
      '$_baseUrl/ayat_timing?surah=$chapterNumber&read=$reciterId',
      cacheName: 'mp3quran_timing_${reciterId}_$chapterNumber.json',
    );
    final timings = <AyahTiming>[];
    for (final entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        timings.add(AyahTiming.fromJson(entry));
      } catch (_) {
        // Skip malformed timing entries.
      }
    }
    return timings;
  }

  // ---------------------------------------------------------------------------
  // Name enrichment
  // ---------------------------------------------------------------------------

  Future<_NameLookups> _fetchNameLookups() async {
    final results = await Future.wait([
      _tryGetJsonMap(
        '$_baseUrl/reciters?language=eng',
        cacheName: 'mp3quran_reciters_eng.json',
      ),
      _tryGetJsonMap(
        '$_baseUrl/riwayat?language=ar',
        cacheName: 'mp3quran_riwayat_ar.json',
      ),
      _tryGetJsonMap(
        '$_baseUrl/riwayat?language=eng',
        cacheName: 'mp3quran_riwayat_eng.json',
      ),
    ]);

    // folder_url -> (reciter id, English reciter name)
    final reciterByServer = <String, (int, String)>{};
    final reciters = results[0]?['reciters'];
    if (reciters is List) {
      for (final r in reciters) {
        if (r is! Map) continue;
        final id = r['id'];
        final name = r['name'];
        final moshafs = r['moshaf'];
        if (id is! int || name is! String || moshafs is! List) continue;
        for (final m in moshafs) {
          final server = m is Map ? m['server'] : null;
          if (server is String) {
            reciterByServer[_normalizeUrl(server)] = (id, name);
          }
        }
      }
    }

    final riwayahIdByArabic = <String, int>{};
    final riwayatAr = results[1]?['riwayat'];
    if (riwayatAr is List) {
      for (final r in riwayatAr) {
        if (r is Map && r['id'] is int && r['name'] is String) {
          riwayahIdByArabic[(r['name'] as String).trim()] = r['id'] as int;
        }
      }
    }

    final riwayahEnglishById = <int, String>{};
    final riwayatEng = results[2]?['riwayat'];
    if (riwayatEng is List) {
      for (final r in riwayatEng) {
        if (r is Map && r['id'] is int && r['name'] is String) {
          riwayahEnglishById[r['id'] as int] = r['name'] as String;
        }
      }
    }

    return _NameLookups(
      reciterByServer: reciterByServer,
      riwayahIdByArabic: riwayahIdByArabic,
      riwayahEnglishById: riwayahEnglishById,
    );
  }

  static String _normalizeUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  Recitation? _mapToRecitation(Object? entry, _NameLookups names) {
    if (entry is! Map) return null;
    final id = entry['id'];
    final name = entry['name'];
    final rewayaName = entry['rewaya'];
    final folderUrl = entry['folder_url'];
    if (id is! int || name is! String || folderUrl is! String) return null;

    final reciterInfo = names.reciterByServer[_normalizeUrl(folderUrl)];
    final riwayahArabic = rewayaName is String ? rewayaName.trim() : '';
    final riwayahId = names.riwayahIdByArabic[riwayahArabic] ?? 0;
    final riwayahEnglish = names.riwayahEnglishById[riwayahId] ?? riwayahArabic;

    return Recitation(
      id: id,
      reciter: Reciter(
        id: reciterInfo?.$1 ?? id,
        nameArabic: name,
        nameEnglish: reciterInfo?.$2 ?? name,
      ),
      riwayah: Riwayah(
        id: riwayahId,
        nameArabic: riwayahArabic,
        nameEnglish: riwayahEnglish,
      ),
      folderUrl: folderUrl,
      audioSource: MushafAudioSource.mp3quran,
    );
  }

  // ---------------------------------------------------------------------------
  // HTTP + cache helpers
  // ---------------------------------------------------------------------------

  /// Fetches a JSON list, preferring the on-disk cache.
  Future<List<dynamic>> _getJsonList(
    String url, {
    required String cacheName,
  }) async {
    final cached = await _readCache(cacheName);
    if (cached is List) return cached;

    final body = await _fetchBody(url);
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON list from mp3quran');
    }
    await _writeCache(cacheName, body);
    return decoded;
  }

  /// Fetches a JSON object, returning null on any failure.
  Future<Map<String, dynamic>?> _tryGetJsonMap(
    String url, {
    required String cacheName,
  }) async {
    try {
      final cached = await _readCache(cacheName);
      if (cached is Map<String, dynamic>) return cached;

      final body = await _fetchBody(url);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      await _writeCache(cacheName, body);
      return decoded;
    } catch (e) {
      MushafLibrary.logger.debug(
        '[Mp3QuranApiClient] Optional lookup failed for $url: $e',
      );
      return null;
    }
  }

  Future<String> _fetchBody(String url) async {
    final response = await _httpClient.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'mp3quran request failed with status ${response.statusCode}',
        Uri.parse(url),
      );
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<File?> _cacheFile(String fileName) async {
    try {
      final dir = await _cacheDirectoryProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File('${dir.path}/$fileName');
    } catch (e) {
      MushafLibrary.logger.debug(
        '[Mp3QuranApiClient] Cache directory unavailable: $e',
      );
      return null;
    }
  }

  /// Returns the decoded cached JSON, or null if missing/corrupted/unavailable.
  Future<Object?> _readCache(String fileName) async {
    try {
      final file = await _cacheFile(fileName);
      if (file == null || !await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (e) {
      MushafLibrary.logger.debug(
        '[Mp3QuranApiClient] Ignoring unreadable cache $fileName: $e',
      );
      return null;
    }
  }

  Future<void> _writeCache(String fileName, String body) async {
    try {
      final file = await _cacheFile(fileName);
      await file?.writeAsString(body);
    } catch (e) {
      MushafLibrary.logger.debug(
        '[Mp3QuranApiClient] Failed to write cache $fileName: $e',
      );
    }
  }
}

class _NameLookups {
  final Map<String, (int, String)> reciterByServer;
  final Map<String, int> riwayahIdByArabic;
  final Map<int, String> riwayahEnglishById;

  const _NameLookups({
    required this.reciterByServer,
    required this.riwayahIdByArabic,
    required this.riwayahEnglishById,
  });
}
