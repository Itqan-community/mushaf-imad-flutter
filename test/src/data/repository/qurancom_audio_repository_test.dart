import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/flutter_audio_player.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_data_source.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter_provider.dart';
import 'package:imad_flutter/src/data/repository/qurancom_audio_repository.dart';
import 'package:imad_flutter/src/domain/models/audio_player_state.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockQuranComReciterProvider extends Mock implements QuranComReciterProvider {}
class MockAyahTimingService extends Mock implements AyahTimingService {}
class MockQurancomDataSource extends Mock implements QurancomDataSource {}
class MockFlutterAudioPlayer extends Mock implements FlutterAudioPlayer {}
class MockMushafLogger extends Mock implements MushafLogger {}

class _FakeReciterInfo extends Fake implements ReciterInfo {}

void main() {
  late MockQuranComReciterProvider mockReciterProvider;
  late MockAyahTimingService mockTimingService;
  late MockQurancomDataSource mockDataSource;
  late MockFlutterAudioPlayer mockAudioPlayer;
  late MockMushafLogger mockLogger;
  late QuranComAudioRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeReciterInfo());
    registerFallbackValue(LogCategory.audio);
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockReciterProvider = MockQuranComReciterProvider();
    mockTimingService = MockAyahTimingService();
    mockDataSource = MockQurancomDataSource();
    mockAudioPlayer = MockFlutterAudioPlayer();
    mockLogger = MockMushafLogger();

    // Default stub for player stream to prevent early null crashes in stream-based tests
    when(() => mockAudioPlayer.domainStateStream)
        .thenAnswer((_) => const Stream.empty());

    repository = QuranComAudioRepository(
      reciterProvider: mockReciterProvider,
      timingService: mockTimingService,
      dataSource: mockDataSource,
      audioPlayer: mockAudioPlayer,
      logger: mockLogger,
    );
  });

  group('QuranComAudioRepository', () {
    test('loadChapter fetches audio URL and calls player with it', () async {
      const chapterNumber = 1;
      const reciterId = 7;
      const audioUrl = 'https://example.com/audio.mp3';
      final reciter = _FakeReciterInfo();

      when(() => mockReciterProvider.getReciterById(reciterId))
          .thenAnswer((_) async => reciter);
      when(() => mockDataSource.fetchChapterAudioUrl(reciterId, chapterNumber))
          .thenAnswer((_) async => audioUrl);
      when(() => mockAudioPlayer.loadChapter(
            any(),
            any(),
            autoPlay: any(named: 'autoPlay'),
            audioUrl: any(named: 'audioUrl'),
          )).thenAnswer((_) async {});

      repository.loadChapter(chapterNumber, reciterId);

      verify(() => mockDataSource.fetchChapterAudioUrl(reciterId, chapterNumber))
          .called(1);
      verify(() => mockAudioPlayer.loadChapter(
            chapterNumber,
            reciter,
            autoPlay: false,
            audioUrl: audioUrl,
          )).called(1);
    });

    test('loadChapter logs error when fetching audio URL fails', () async {
      final reciter = _FakeReciterInfo();
      when(() => mockReciterProvider.getReciterById(any()))
          .thenAnswer((_) async => reciter);
      when(() => mockDataSource.fetchChapterAudioUrl(any(), any()))
          .thenThrow(Exception('API Error'));

      repository.loadChapter(1, 7);

      verify(() => mockLogger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
            category: LogCategory.audio,
          )).called(1);
    });

    test('getPlayerStateStream enriches state with verse number', () async {
      final playerState = const AudioPlayerState().copyWith(
        currentReciterId: 7,
        currentChapter: 1,
        currentPositionMs: 5000,
      );

      final controller = StreamController<AudioPlayerState>();
      when(() => mockAudioPlayer.domainStateStream)
          .thenAnswer((_) => controller.stream);
      when(() => mockTimingService.getCurrentVerse(7, 1, 5000))
          .thenAnswer((_) async => 3);

      final stream = repository.getPlayerStateStream();
      final expectation = expectLater(
        stream,
        emits(predicate<AudioPlayerState>((s) => s.currentVerse == 3)),
      );

      controller.add(playerState);
      await expectation;
      controller.close();
    });

    test('release stops player and clears provider cache', () {
      when(() => mockAudioPlayer.stop()).thenAnswer((_) async {});
      when(() => mockReciterProvider.clearCache()).thenReturn(null);

      repository.release();

      verify(() => mockAudioPlayer.stop()).called(1);
      verify(() => mockReciterProvider.clearCache()).called(1);
    });
  });
}
