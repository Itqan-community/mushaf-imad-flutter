import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../domain/models/audio_source.dart';
import '../../../domain/models/reciter_info.dart';
import '../../../mushaf_library.dart';
import '../base/audio_reciter_provider.dart';
import 'itqan_audio_config.dart';

/// [AudioReciterProvider] implementation that fetches reciters from the
/// Itqan CMS `/reciters/` endpoint.
///
/// All returned [ReciterInfo] objects are tagged with [MushafAudioSource.itqan].
class ItqanReciterProvider implements AudioReciterProvider {
  final ItqanAudioConfig _config;
  final http.Client? _client;

  List<ReciterInfo>? _cache;

  ItqanReciterProvider({required ItqanAudioConfig config, http.Client? client})
    : _config = config,
      _client = client;

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) {
    if (_client != null) {
      return _client.get(url, headers: headers);
    }
    return http.get(url, headers: headers);
  }

  @override
  MushafAudioSource get source => MushafAudioSource.itqan;

  @override
  Future<List<ReciterInfo>> getAllReciters() async {
    if (_cache != null) return _cache!;

    try {
      final response = await _get(
        Uri.parse('${_config.baseUrl}/reciters/'),
        headers: _config.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        _cache = results.map((json) {
          final name = json['name'] as String? ?? 'Unknown';
          return ReciterInfo(
            id: json['id'] as int,
            nameArabic: name,
            nameEnglish: name,
            rewaya: 'Various',
            folderUrl: '',
            audioSource: MushafAudioSource.itqan,
          );
        }).toList();
        return _cache!;
      }
    } catch (e) {
      MushafLibrary.logger.error(
        '[ItqanReciterProvider] Error fetching reciters: $e',
      );
    }

    // Fallback if the API call fails.
    _cache = [
      ReciterInfo(
        id: _config.defaultReciterId,
        nameArabic: 'مقرئ إتقان',
        nameEnglish: 'Itqan Reciter',
        rewaya: 'Hafs',
        folderUrl: '',
        audioSource: MushafAudioSource.itqan,
      ),
    ];
    return _cache!;
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
      if (languageCode == 'ar') return r.nameArabic.contains(normalizedQuery);
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
      nameArabic: 'مقرئ إتقان',
      nameEnglish: 'Itqan Reciter',
      rewaya: 'Hafs',
      folderUrl: '',
      audioSource: MushafAudioSource.itqan,
    );
  }

  /// Clears the in-memory reciter cache.
  void clearCache() => _cache = null;
}
