import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:imad_flutter/src/data/audio/flutter_audio_player.dart';

// Fake audio player to avoid just_audio dependency issues in tests
class FakeFlutterAudioPlayer implements FlutterAudioPlayer {
  @override
  Stream<AudioPlayerState> get domainStateStream => const Stream.empty();

  @override
  Future<void> loadFromUrl(
    String url, {
    int chapterNumber = 0,
    ReciterInfo? reciter,
    bool autoPlay = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CmsAudioRepository', () {
    late CmsAudioConfig config;
    late FakeFlutterAudioPlayer audioPlayer;
    late MockClient mockClient;
    late CmsAudioRepository repository;

    setUp(() {
      config = const CmsAudioConfig(
        baseUrl: 'https://api.cms.itqan.dev',
        defaultReciterId: 1,
      );
      audioPlayer = FakeFlutterAudioPlayer();

      mockClient = MockClient((request) async {
        if (request.url.path.contains('/reciters/')) {
          return http.Response(
            jsonEncode({
              'count': 1,
              'results': [
                {'id': 1, 'name': 'Mishari Al-afasi', 'bio': 'Test bio'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/recitations/') &&
            request.url.query.contains('reciter_id=1')) {
          return http.Response(
            jsonEncode({
              'count': 1,
              'results': [
                {
                  'id': 123,
                  'name': 'Mishari Hafs',
                  'description': 'Test recitation',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/recitations/123/')) {
          return http.Response(
            jsonEncode({
              'count': 1,
              'results': [
                {
                  'surah_number': 1,
                  'audio_url': 'https://cms.itqan.dev/audio/1.mp3',
                  'ayahs_timings': [
                    {'ayah_key': '1:1', 'start_ms': 0, 'end_ms': 5000},
                    {'ayah_key': '1:2', 'start_ms': 5000, 'end_ms': 10000},
                  ],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      repository = CmsAudioRepository(config, audioPlayer, client: mockClient);
    });

    test('getAllReciters parses CMS response correctly', () async {
      final reciters = await repository.getAllReciters();
      expect(reciters.length, equals(1));
      expect(reciters.first.id, equals(1));
      expect(reciters.first.nameEnglish, equals('Mishari Al-afasi'));
    });

    test('loadChapter fetches timestamps and caches them', () async {
      // Act
      repository.loadChapter(1, 1);

      // Wait for async load (we have to delay briefly since loadChapter doesn't return a Future)
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final timings = await repository.getChapterTimings(1, 1);
      expect(timings.length, equals(2));

      expect(timings[0].ayah, equals(1));
      expect(timings[0].startTime, equals(0));
      expect(timings[0].endTime, equals(5000));

      expect(timings[1].ayah, equals(2));
      expect(timings[1].startTime, equals(5000));
      expect(timings[1].endTime, equals(10000));
    });
  });
}
