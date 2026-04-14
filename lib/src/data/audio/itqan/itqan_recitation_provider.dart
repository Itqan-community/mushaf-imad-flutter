import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../domain/models/audio_source.dart';
import '../../../domain/models/recitation.dart';
import '../../../domain/models/reciter.dart';
import '../../../domain/models/riwayah.dart';
import '../../../mushaf_library.dart';
import '../base/audio_recitation_provider.dart';
import 'itqan_audio_config.dart';

/// [AudioRecitationProvider] implementation that fetches recitations from the
/// Itqan CMS `/recitations/` endpoint.
///
/// All returned [Recitation] objects are tagged with [MushafAudioSource.itqan].
class ItqanRecitationProvider implements AudioRecitationProvider {
  final ItqanAudioConfig _config;
  final http.Client? _client;

  List<Recitation>? _cache;

  ItqanRecitationProvider({
    required ItqanAudioConfig config,
    http.Client? client,
  }) : _config = config,
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
  Future<List<Recitation>> getAllRecitations() async {
    if (_cache != null) return _cache!;

    try {
      final response = await _get(
        Uri.parse('${_config.baseUrl}/recitations/'),
        headers: _config.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        _cache = results.map((json) {
          final id = json['id'] as int;

          final reciterObj = json['reciter'] as Map<String, dynamic>?;
          final reciterName = reciterObj?['name'] as String? ?? 'Unknown';
          final reciterId = reciterObj?['id'] as int? ?? id;

          final riwayahObj = json['riwayah'] as Map<String, dynamic>?;
          final riwayahName = riwayahObj?['name'] as String? ?? 'Unknown';
          final riwayahId = riwayahObj?['id'] as int? ?? id;

          return Recitation(
            id: id,
            reciter: Reciter(
              id: reciterId,
              nameArabic: reciterName,
              nameEnglish: reciterName,
            ),
            riwayah: Riwayah(
              id: riwayahId,
              nameArabic: riwayahName,
              nameEnglish: riwayahName,
            ),
            folderUrl: '',
            audioSource: MushafAudioSource.itqan,
          );
        }).toList();
        return _cache!;
      }
    } catch (e) {
      MushafLibrary.logger.error(
        '[ItqanRecitationProvider] Error fetching recitations: $e',
      );
    }

    // Fallback if the API call fails.
    _cache = [
      Recitation(
        id: _config.defaultReciterId,
        reciter: Reciter(
          id: _config.defaultReciterId,
          nameArabic: 'مقرئ إتقان',
          nameEnglish: 'Itqan Reciter',
        ),
        riwayah: const Riwayah(
          id: 1,
          nameArabic: 'حفص عن عاصم',
          nameEnglish: 'Hafs an Asim',
        ),
        folderUrl: '',
        audioSource: MushafAudioSource.itqan,
      ),
    ];
    return _cache!;
  }

  @override
  Future<Recitation?> getRecitationById(int recitationId) async {
    final recitations = await getAllRecitations();
    try {
      return recitations.firstWhere((r) => r.id == recitationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) async {
    final recitations = await getAllRecitations();
    final normalizedQuery = query.toLowerCase();
    return recitations.where((r) {
      if (languageCode == 'ar') {
        return r.reciter.nameArabic.contains(normalizedQuery) ||
            r.riwayah.nameArabic.contains(normalizedQuery);
      }
      return r.reciter.nameEnglish.toLowerCase().contains(normalizedQuery) ||
          r.riwayah.nameEnglish.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<Recitation> getDefaultRecitation() async {
    final recitations = await getAllRecitations();
    if (recitations.isNotEmpty) return recitations.first;
    return Recitation(
      id: _config.defaultReciterId,
      reciter: Reciter(
        id: _config.defaultReciterId,
        nameArabic: 'مقرئ إتقان',
        nameEnglish: 'Itqan Reciter',
      ),
      riwayah: const Riwayah(
        id: 1,
        nameArabic: 'حفص عن عاصم',
        nameEnglish: 'Hafs an Asim',
      ),
      folderUrl: '',
      audioSource: MushafAudioSource.itqan,
    );
  }

  /// Clears the in-memory recitation cache.
  void clearCache() => _cache = null;
}
