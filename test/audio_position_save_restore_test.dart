import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:imad_flutter/src/data/audio/audio_player_interface.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'package:imad_flutter/src/data/audio/reciter_service.dart';
import 'package:imad_flutter/src/data/repository/default_audio_repository.dart';
import 'package:imad_flutter/src/domain/models/audio_player_state.dart';
import 'package:imad_flutter/src/domain/models/mushaf_type.dart';
import 'package:imad_flutter/src/domain/models/reciter_info.dart';
import 'package:imad_flutter/src/domain/models/theme.dart';
import 'package:imad_flutter/src/domain/repository/preferences_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────

class FakePreferencesRepository implements PreferencesRepository {
  int? lastAudioChapter;
  int lastAudioPositionMs = 0;
  final List<int> savedPositions = [];
  final List<int?> savedChapters = [];

  @override
  Future<int?> getLastAudioChapter() async => lastAudioChapter;

  @override
  Future<void> setLastAudioChapter(int? chapter) async {
    lastAudioChapter = chapter;
    savedChapters.add(chapter);
  }

  @override
  Future<int> getLastAudioPositionMs() async => lastAudioPositionMs;

  @override
  Future<void> setLastAudioPositionMs(int ms) async {
    lastAudioPositionMs = ms;
    savedPositions.add(ms);
  }

  // ── Unused stubs ──────────────────────────────────────────────────────────
  @override Stream<MushafType> getMushafTypeStream() => const Stream.empty();
  @override Future<void> setMushafType(MushafType t) async {}
  @override Stream<int> getCurrentPageStream() => const Stream.empty();
  @override Future<int> getCurrentPage() async => 1;
  @override Future<void> setCurrentPage(int p) async {}
  @override Stream<int?> getLastReadChapterStream() => const Stream.empty();
  @override Future<void> setLastReadChapter(int c) async {}
  @override Stream<(int, int)?> getLastReadVerseStream() => const Stream.empty();
  @override Future<void> setLastReadVerse(int c, int v) async {}
  @override Stream<double> getFontSizeMultiplierStream() => const Stream.empty();
  @override Future<void> setFontSizeMultiplier(double m) async {}
  @override Stream<bool> getShowTranslationStream() => const Stream.empty();
  @override Future<void> setShowTranslation(bool s) async {}
  @override Stream<int> getSelectedReciterIdStream() => const Stream.empty();
  @override Future<int> getSelectedReciterId() async => 1;
  @override Future<void> setSelectedReciterId(int id) async {}
  @override Stream<double> getPlaybackSpeedStream() => const Stream.empty();
  @override Future<double> getPlaybackSpeed() async => 1.0;
  @override Future<void> setPlaybackSpeed(double s) async {}
  @override Stream<bool> getRepeatModeStream() => const Stream.empty();
  @override Future<bool> getRepeatMode() async => false;
  @override Future<void> setRepeatMode(bool e) async {}
  @override Stream<int?> getLastAudioChapterStream() => const Stream.empty();
  @override Stream<int?> getLastAudioVerseStream() => const Stream.empty();
  @override Future<int?> getLastAudioVerse() async => null;
  @override Future<void> setLastAudioVerse(int? v) async {}
  @override Stream<int> getLastAudioPositionMsStream() => const Stream.empty();
  @override Stream<ThemeConfig> getThemeConfigStream() => const Stream.empty();
  @override Future<ThemeConfig> getThemeConfig() async => const ThemeConfig();
  @override Future<void> setThemeMode(MushafThemeMode m) async {}
  @override Future<void> setColorScheme(MushafColorScheme s) async {}
  @override Future<void> setAmoledMode(bool e) async {}
  @override Future<void> updateThemeConfig(ThemeConfig c) async {}
  @override Future<void> clearAll() async {}
}

/// Pure Dart fake — no Flutter binding required.
class FakeAudioPlayer implements AudioPlayerInterface {
  final _stateController = StreamController<AudioPlayerState>.broadcast();
  final List<Duration> seekCalls = [];
  final List<int> loadedChapters = [];

  @override
  Stream<AudioPlayerState> get domainStateStream => _stateController.stream;

  void emitState(AudioPlayerState state) => _stateController.add(state);

  void close() => _stateController.close();

  @override
  Future<void> loadChapter(
    int chapterNumber,
    ReciterInfo reciter, {
    bool autoPlay = false,
  }) async {
    loadedChapters.add(chapterNumber);
  }

  @override
  Future<void> seek(Duration position) async => seekCalls.add(position);

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async => _stateController.close();

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setRepeatModeBool(bool enabled) async {}

  @override
  bool isRepeatMode() => false;
}

class FakeReciterService extends ReciterService {
  final ReciterInfo? reciter;
  FakeReciterService({this.reciter});

  @override
  ReciterInfo? getReciterById(int id) => reciter;

  @override
  void dispose() {}
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  late FakePreferencesRepository prefs;
  late FakeAudioPlayer player;
  late FakeReciterService reciterService;
  late DefaultAudioRepository repo;

  const testReciter = ReciterInfo(
    id: 1,
    nameArabic: 'اختبار',
    nameEnglish: 'Test',
    rewaya: 'Hafs',
    folderUrl: 'https://example.com/',
  );

  setUp(() {
    prefs = FakePreferencesRepository();
    player = FakeAudioPlayer();
    reciterService = FakeReciterService(reciter: testReciter);
    repo = DefaultAudioRepository(
      reciterService,
      AyahTimingService(),
      player,
      prefs,
    );
  });

  tearDown(() {
    repo.release();
  });

  group('position saving', () {
    test('saves position when playback pauses', () async {
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.paused,
        currentPositionMs: 12000,
      ));
      await Future.delayed(Duration.zero);

      expect(prefs.savedPositions, contains(12000));
    });

    test('saves position when playback stops', () async {
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.stopped,
        currentPositionMs: 8000,
      ));
      await Future.delayed(Duration.zero);

      expect(prefs.savedPositions, contains(8000));
    });

    test('saves position periodically during playback (every 5s)', () async {
      // At 0ms — no save (diff = 0)
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.playing,
        currentPositionMs: 0,
      ));
      await Future.delayed(Duration.zero);

      // At 3000ms — diff < 5000, no save
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.playing,
        currentPositionMs: 3000,
      ));
      await Future.delayed(Duration.zero);

      // At 5001ms — diff >= 5000, should save
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.playing,
        currentPositionMs: 5001,
      ));
      await Future.delayed(Duration.zero);

      expect(prefs.savedPositions, contains(5001));
      expect(prefs.savedPositions, isNot(contains(3000)));
    });

    test('does not save duplicate position', () async {
      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.paused,
        currentPositionMs: 5000,
      ));
      await Future.delayed(Duration.zero);

      player.emitState(const AudioPlayerState(
        playbackState: PlaybackState.paused,
        currentPositionMs: 5000,
      ));
      await Future.delayed(Duration.zero);

      expect(prefs.savedPositions.where((p) => p == 5000).length, 1);
    });
  });

  group('position restore on loadChapter', () {
    test('restores saved position when loading same chapter', () async {
      prefs.lastAudioChapter = 2;
      prefs.lastAudioPositionMs = 30000;

      repo.loadChapter(2, 1);
      await Future.delayed(Duration.zero);

      expect(player.seekCalls, contains(const Duration(milliseconds: 30000)));
    });

    test('does not restore position when loading a different chapter', () async {
      prefs.lastAudioChapter = 3;
      prefs.lastAudioPositionMs = 30000;

      repo.loadChapter(2, 1);
      await Future.delayed(Duration.zero);

      expect(player.seekCalls, isEmpty);
    });

    test('does not seek when saved position is 0', () async {
      prefs.lastAudioChapter = 2;
      prefs.lastAudioPositionMs = 0;

      repo.loadChapter(2, 1);
      await Future.delayed(Duration.zero);

      expect(player.seekCalls, isEmpty);
    });

    test('saves chapter number when loading', () async {
      prefs.lastAudioChapter = null;
      prefs.lastAudioPositionMs = 0;

      repo.loadChapter(5, 1);
      await Future.delayed(Duration.zero);

      expect(prefs.savedChapters, contains(5));
    });

    test('does nothing when reciter not found', () async {
      final noReciterPlayer = FakeAudioPlayer();
      final noReciterPrefs = FakePreferencesRepository();
      final repoWithNoReciter = DefaultAudioRepository(
        FakeReciterService(reciter: null),
        AyahTimingService(),
        noReciterPlayer,
        noReciterPrefs,
      );

      repoWithNoReciter.loadChapter(1, 99);
      await Future.delayed(Duration.zero);

      expect(noReciterPlayer.loadedChapters, isEmpty);
      expect(noReciterPrefs.savedChapters, isEmpty);

      repoWithNoReciter.release();
    });
  });
}
