import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/reciter_timing.dart';
import '../../../domain/models/reciter.dart';
import '../../../domain/models/riwayah.dart';
import '../../../domain/models/recitation.dart';
import '../../../domain/models/audio_source.dart';

class Mp3QuranApiClient {
  final http.Client _httpClient;
  final bool _internalHttpClient;

  Mp3QuranApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      _internalHttpClient = httpClient == null;

  void dispose() {
    if (_internalHttpClient) {
      _httpClient.close();
    }
  }

  /// Fetches the list of all reciters (reads) from mp3quran API.
  /// Result is cached to the file system.
  Future<List<Recitation>> fetchRecitations() async {
    const url = 'https://www.mp3quran.net/api/v3/ayat_timing/reads';
    final cachedFile = await _getCacheFile('mp3quran_reads.json');

    // Try cache first
    if (await cachedFile.exists()) {
      try {
        final content = await cachedFile.readAsString();
        final data = jsonDecode(content) as List;
        return data
            .map((e) => _mapToRecitation(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback to fetch if cache is corrupted
      }
    }

    // Fetch from API
    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      // Save to cache
      await cachedFile.writeAsString(response.body);
      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => _mapToRecitation(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch MP3Quran reciters: ${response.statusCode}',
      );
    }
  }

  /// Fetches timing for a specific surah and reciter.
  Future<List<AyahTiming>> fetchChapterTiming({
    required int reciterId,
    required int chapterNumber,
  }) async {
    final url =
        'https://www.mp3quran.net/api/v3/ayat_timing?surah=$chapterNumber&read=$reciterId';
    final cachedFile = await _getCacheFile(
      'mp3quran_timing_${reciterId}_$chapterNumber.json',
    );

    // Try cache first
    if (await cachedFile.exists()) {
      try {
        final content = await cachedFile.readAsString();
        final data = jsonDecode(content) as List;
        return data
            .map((e) => AyahTiming.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Fallback
      }
    }

    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      await cachedFile.writeAsString(response.body);
      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => AyahTiming.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch timings for chapter $chapterNumber from mp3quran',
      );
    }
  }

  Future<File> _getCacheFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/mushaf_cache/mp3quran');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$fileName');
  }

  Recitation _mapToRecitation(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String;
    final rewayaName = json['rewaya'] as String;
    final folderUrl = json['folder_url'] as String;

    return Recitation(
      id: id,
      reciter: Reciter(
        id: id,
        nameArabic: name,
        nameEnglish: name, // The API mostly gives Arabic names
      ),
      riwayah: Riwayah(id: id, nameArabic: rewayaName, nameEnglish: rewayaName),
      folderUrl: folderUrl,
      audioSource: MushafAudioSource.mp3quran,
    );
  }
}
