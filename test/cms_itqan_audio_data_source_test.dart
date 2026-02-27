import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imad_flutter/src/data/audio/audio_source_config.dart';
import 'package:imad_flutter/src/data/audio/cms_itqan_audio_data_source.dart';

void main() {
  group('CmsItqanAudioDataSource', () {
    test('fetchAllReciters maps recitations payload to ReciterInfo', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/recitations/')) {
          final page = request.url.queryParameters['page'];
          if (page == '1') {
            return http.Response(
              jsonEncode({
                'count': 2,
                'results': [
                  {
                    'id': 11,
                    'reciter': {'id': 1, 'name': 'Abdul Basit'},
                    'riwayah': {'id': 1, 'name': 'Hafs'},
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'count': 2,
              'results': [
                {
                  'id': 22,
                  'reciter': {'id': 2, 'name': 'Minshawi'},
                  'riwayah': {'id': 1, 'name': 'Hafs'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final source = CmsItqanAudioDataSource(
        config: const CmsAudioSourceConfig(apiBaseUrl: 'https://example.test'),
        client: client,
      );

      final reciters = await source.fetchAllReciters();
      expect(reciters.length, 2);
      expect(reciters.first.id, 11);
      expect(reciters.first.nameEnglish, 'Abdul Basit');
      expect(reciters.first.rewaya, 'Hafs');
    });

    test(
      'fetchReciterTiming and fetchChapterAudioUrl parse tracks payload',
      () async {
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/recitations/')) {
            return http.Response(
              jsonEncode({
                'count': 1,
                'results': [
                  {
                    'id': 11,
                    'reciter': {'id': 1, 'name': 'Abdul Basit'},
                    'riwayah': {'id': 1, 'name': 'Hafs'},
                  },
                ],
              }),
              200,
            );
          }

          if (request.url.path.endsWith('/recitations/11/')) {
            return http.Response(
              jsonEncode({
                'count': 1,
                'results': [
                {
                  'surah_number': 1,
                  'surah_name': 'Al-Fatihah',
                  'surah_name_en': 'Al-Fatihah',
                    'audio_url': 'https://cdn.example.test/001.mp3',
                    'ayahs_timings': [
                      {
                        'ayah_key': '1:1',
                        'start_ms': 0,
                        'end_ms': 4000,
                        'duration_ms': 4000,
                      },
                      {
                        'ayah_key': '1:2',
                        'start_ms': 4000,
                        'end_ms': 7200,
                        'duration_ms': 3200,
                      },
                    ],
                  },
                ],
              }),
              200,
            );
          }

          return http.Response('{}', 404);
        });

        final source = CmsItqanAudioDataSource(
          config: const CmsAudioSourceConfig(
            apiBaseUrl: 'https://example.test',
          ),
          client: client,
        );

        final timing = await source.fetchReciterTiming(11);
        expect(timing, isNotNull);
        expect(timing!.chapters.length, 1);
        expect(timing.chapters.first.id, 1);
        expect(timing.chapters.first.ayaTiming.length, 2);
        expect(timing.chapters.first.ayaTiming.first.ayah, 1);
        expect(timing.chapters.first.ayaTiming.first.startTime, 0);
        expect(timing.chapters.first.ayaTiming.first.endTime, 4000);

        final audioUrl = await source.fetchChapterAudioUrl(11, 1);
        expect(audioUrl, 'https://cdn.example.test/001.mp3');
      },
    );
  });
}
