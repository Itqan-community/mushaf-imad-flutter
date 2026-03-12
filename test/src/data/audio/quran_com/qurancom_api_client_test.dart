import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_client.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late QuranComApiClient apiClient;
  late MockHttpClient httpClient;
  late QuranComApiConfig config;

  const testClientId = 'test_id';
  const testClientSecret = 'test_secret';
  const validToken = 'valid_token';

  // Helper to generate a successful token response
  String mockTokenJson(String token, {int expires = 3600}) => jsonEncode({
    'access_token': token,
    'expires_in': expires,
    'token_type': 'Bearer',
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    httpClient = MockHttpClient();
    config = QuranComApiConfig(
      clientId: testClientId,
      clientSecret: testClientSecret,
      environment: QuranComEnvironment.prelive,
    );
    apiClient = QuranComApiClient(config: config, httpClient: httpClient);
  });

  tearDown(() {
    apiClient.dispose();
  });

  group('OAuth2 Authentication & Caching', () {
    test('should fetch token on first request and cache it', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'recitations': []}), 200),
      );

      // Act
      await apiClient.fetchReciters(); // 1st call: fetch token + fetch data
      await apiClient
          .fetchReciters(); // 2nd call: use cached token + fetch data

      // Assert
      verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
      verify(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).called(2);
    });

    test('should retry request once after 401 Unauthorized', () async {
      // Arrange
      // 1. Initial token fetch
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson('old_token'), 200));

      // 2. First GET fails with 401, Second GET succeeds
      var getCallCount = 0;
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async {
        getCallCount++;
        if (getCallCount == 1) return http.Response('Unauthorized', 401);
        return http.Response(jsonEncode({'recitations': []}), 200);
      });

      // Act
      await apiClient.fetchReciters();

      // Assert
      // 1st post for initial token, 2nd post after 401
      verify(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(2);
      expect(getCallCount, 2);
    });

    test(
      'should throw Exception if retry after 401 also fails with non-200',
      () async {
        // Arrange
        when(
          () => httpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response(mockTokenJson('token'), 200));

        var getCallCount = 0;
        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async {
          getCallCount++;
          if (getCallCount == 1) return http.Response('Unauthorized', 401);
          return http.Response('Internal Server Error', 500);
        });

        // Act & Assert
        await expectLater(apiClient.fetchReciters(), throwsException);
        expect(getCallCount, 2);
      },
    );

    test('should throw Exception if token fetch fails', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Error', 500));

      // Act & Assert
      expect(() => apiClient.fetchReciters(), throwsException);
    });
  });

  group('API Methods Parsing', () {
    test('fetchReciters parses complex reciter list correctly', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      final jsonMap = {
        'recitations': [
          {
            'id': 7,
            'reciter_name': 'Mishari Rashid al-`Afasy',
            'style': 'Murattal',
            'translated_name': {
              'name': 'Mishari al-Afasy',
              'language_name': 'english',
            },
          },
          {
            'id': 10,
            'reciter_name': 'Abdur-Rashid Sufi',
            'style': 'Mujawwad',
            'translated_name': {
              'name': 'Abdur-Rashid Sufi',
              'language_name': 'english',
            },
          },
        ],
      };
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode(jsonMap), 200));

      // Act
      final result = await apiClient.fetchReciters();

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 7);
      expect(result[0].reciterName, contains('Afasy'));
      expect(result[1].style, 'Mujawwad');
    });

    test('fetchChapterAudio parses timings and segments correctly', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      final jsonMap = {
        'audio_file': {
          'id': 1,
          'file_size': 123456.0,
          'chapter_id': 1,
          'audio_url': 'https://download.quran.com/1.mp3',
          'duration': 12345,
          'format': 'mp3',
          'timestamps': [
            {
              'verse_key': '1:1',
              'timestamp_from': 100,
              'timestamp_to': 500,
              'duration': 400,
              'segments': [
                [1, 100, 200],
                [2, 200, 500],
              ],
            },
          ],
        },
      };
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode(jsonMap), 200));

      // Act
      final result = await apiClient.fetchChapterAudio(
        reciterId: 7,
        chapterNumber: 1,
      );

      // Assert
      expect(result.chapterId, 1);
      expect(result.audioUrl, contains('1.mp3'));
      expect(result.timestamps?.length, 1);
      expect(result.timestamps?.first.verseKey, '1:1');
      expect(result.timestamps?.first.segments?.length, 2);
      expect(result.timestamps?.first.segments?.first.wordIndex, 1);
    });
  });

  group('Edge Cases & Errors', () {
    test('should throw Exception when JSON is malformed', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Invalid JSON', 200));

      // Act & Assert
      expect(() => apiClient.fetchReciters(), throwsA(isA<FormatException>()));
    });

    test('should throw Exception when API returns 500', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server error', 500));

      // Act & Assert
      expect(() => apiClient.fetchReciters(), throwsException);
    });

    test('should throw Exception when API returns 404', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      // Act & Assert
      expect(() => apiClient.fetchReciters(), throwsException);
    });

    test(
      'should propagate SocketException on network failure during token fetch',
      () async {
        // Arrange
        when(
          () => httpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(const SocketException('No Internet'));

        // Act & Assert
        expect(
          () => apiClient.fetchReciters(),
          throwsA(isA<SocketException>()),
        );
      },
    );

    test(
      'should propagate SocketException on network failure during data fetch',
      () async {
        // Arrange
        when(
          () => httpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(mockTokenJson(validToken), 200),
        );

        when(
          () => httpClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(const SocketException('Connection lost'));

        // Act & Assert
        expect(
          () => apiClient.fetchReciters(),
          throwsA(isA<SocketException>()),
        );
      },
    );

    test('should include segments query param in URL when requested', () async {
      // Arrange
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response(mockTokenJson(validToken), 200));

      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'audio_file': {
              'id': 1,
              'file_size': 100.0,
              'chapter_id': 1,
              'audio_url': 'url',
              'duration': 1,
              'format': 'mp3',
              'timestamps': [],
            },
          }),
          200,
        ),
      );

      // Act
      await apiClient.fetchChapterAudio(
        reciterId: 7,
        chapterNumber: 1,
        segments: true,
      );

      // Assert
      final capturedUri =
          verify(
                () => httpClient.get(
                  captureAny(),
                  headers: any(named: 'headers'),
                ),
              ).captured.single
              as Uri;
      expect(capturedUri.queryParameters['segments'], 'true');
    });
  });
}
