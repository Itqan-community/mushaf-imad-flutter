import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:imad_flutter/src/data/local/dao/hive/hive_preferences_dao.dart';
import 'package:imad_flutter/src/domain/models/mushaf_type.dart';
import 'package:imad_flutter/src/domain/models/theme.dart';

void main() {
  late HivePreferencesDao dao;

  setUp(() async {
    Hive.init('test_hive_${DateTime.now().microsecondsSinceEpoch}');
    dao = HivePreferencesDao();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // ── Reading ───────────────────────────────────────────────────────────────

  group('currentPage', () {
    test('default is 1', () async {
      expect(await dao.getCurrentPage(), 1);
    });

    test('persists value', () async {
      await dao.setCurrentPage(42);
      expect(await dao.getCurrentPage(), 42);
    });

    test('clamps to [1, 604]', () async {
      await dao.setCurrentPage(0);
      expect(await dao.getCurrentPage(), 1);
      await dao.setCurrentPage(999);
      expect(await dao.getCurrentPage(), 604);
    });
  });

  group('mushafType', () {
    test('default is hafs1441', () async {
      expect(await dao.getMushafType(), MushafType.hafs1441);
    });

    test('persists hafs1405', () async {
      await dao.setMushafType(MushafType.hafs1405);
      expect(await dao.getMushafType(), MushafType.hafs1405);
    });
  });

  group('lastReadChapter', () {
    test('default is null', () async {
      expect(await dao.getLastReadChapter(), isNull);
    });

    test('persists value', () async {
      await dao.setLastReadChapter(18);
      expect(await dao.getLastReadChapter(), 18);
    });
  });

  group('lastReadVerse', () {
    test('default is null', () async {
      expect(await dao.getLastReadVerse(), isNull);
    });

    test('persists chapter and verse', () async {
      await dao.setLastReadVerse(2, 255);
      final result = await dao.getLastReadVerse();
      expect(result, isNotNull);
      expect(result!.$1, 2);
      expect(result.$2, 255);
    });
  });

  group('fontSizeMultiplier', () {
    test('default is 1.0', () async {
      expect(await dao.getFontSizeMultiplier(), 1.0);
    });

    test('persists value', () async {
      await dao.setFontSizeMultiplier(1.5);
      expect(await dao.getFontSizeMultiplier(), 1.5);
    });

    test('clamps to [0.5, 2.0]', () async {
      await dao.setFontSizeMultiplier(0.1);
      expect(await dao.getFontSizeMultiplier(), 0.5);
      await dao.setFontSizeMultiplier(5.0);
      expect(await dao.getFontSizeMultiplier(), 2.0);
    });
  });

  group('showTranslation', () {
    test('default is false', () async {
      expect(await dao.getShowTranslation(), false);
    });

    test('persists true', () async {
      await dao.setShowTranslation(true);
      expect(await dao.getShowTranslation(), true);
    });
  });

  // ── Audio ─────────────────────────────────────────────────────────────────

  group('selectedReciterId', () {
    test('default is 1', () async {
      expect(await dao.getSelectedReciterId(), 1);
    });

    test('persists value', () async {
      await dao.setSelectedReciterId(5);
      expect(await dao.getSelectedReciterId(), 5);
    });
  });

  group('playbackSpeed', () {
    test('default is 1.0', () async {
      expect(await dao.getPlaybackSpeed(), 1.0);
    });

    test('persists value', () async {
      await dao.setPlaybackSpeed(1.5);
      expect(await dao.getPlaybackSpeed(), 1.5);
    });
  });

  group('repeatMode', () {
    test('default is false', () async {
      expect(await dao.getRepeatMode(), false);
    });

    test('persists true', () async {
      await dao.setRepeatMode(true);
      expect(await dao.getRepeatMode(), true);
    });
  });

  group('lastAudioChapter', () {
    test('default is null', () async {
      expect(await dao.getLastAudioChapter(), isNull);
    });

    test('persists value', () async {
      await dao.setLastAudioChapter(36);
      expect(await dao.getLastAudioChapter(), 36);
    });

    test('can be cleared to null', () async {
      await dao.setLastAudioChapter(36);
      await dao.setLastAudioChapter(null);
      expect(await dao.getLastAudioChapter(), isNull);
    });
  });

  group('lastAudioVerse', () {
    test('default is null', () async {
      expect(await dao.getLastAudioVerse(), isNull);
    });

    test('persists value', () async {
      await dao.setLastAudioVerse(83);
      expect(await dao.getLastAudioVerse(), 83);
    });

    test('can be cleared to null', () async {
      await dao.setLastAudioVerse(83);
      await dao.setLastAudioVerse(null);
      expect(await dao.getLastAudioVerse(), isNull);
    });
  });

  group('lastAudioPositionMs', () {
    test('default is 0', () async {
      expect(await dao.getLastAudioPositionMs(), 0);
    });

    test('persists value', () async {
      await dao.setLastAudioPositionMs(12345);
      expect(await dao.getLastAudioPositionMs(), 12345);
    });
  });

  // ── Theme ─────────────────────────────────────────────────────────────────

  group('themeConfig', () {
    test('default is system/defaultScheme/no-amoled', () async {
      final config = await dao.getThemeConfig();
      expect(config.mode, MushafThemeMode.system);
      expect(config.colorScheme, MushafColorScheme.defaultScheme);
      expect(config.useAmoled, false);
    });

    test('persists full config', () async {
      await dao.setThemeConfig(const ThemeConfig(
        mode: MushafThemeMode.dark,
        colorScheme: MushafColorScheme.sepia,
        useAmoled: true,
      ));
      final config = await dao.getThemeConfig();
      expect(config.mode, MushafThemeMode.dark);
      expect(config.colorScheme, MushafColorScheme.sepia);
      expect(config.useAmoled, true);
    });
  });

  // ── clearAll ──────────────────────────────────────────────────────────────

  group('clearAll', () {
    test('resets all values to defaults', () async {
      await dao.setCurrentPage(300);
      await dao.setSelectedReciterId(9);
      await dao.setThemeConfig(const ThemeConfig(mode: MushafThemeMode.dark));
      await dao.setLastAudioChapter(5);

      await dao.clearAll();

      expect(await dao.getCurrentPage(), 1);
      expect(await dao.getSelectedReciterId(), 1);
      expect((await dao.getThemeConfig()).mode, MushafThemeMode.system);
      expect(await dao.getLastAudioChapter(), isNull);
    });
  });
}
