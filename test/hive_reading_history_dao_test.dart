import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => Directory.systemTemp.path,
      );

  late HiveReadingHistoryDao dao;

  setUpAll(() async {
    final testDir = Directory.systemTemp.createTempSync('hive_history_test_');
    Hive.init(testDir.path);
    dao = HiveReadingHistoryDao();
  });

  setUp(() async {
    await dao.deleteAll();
    final positionBox = await Hive.openBox<Map>('last_read_positions');
    await positionBox.clear();
  });

  ReadingHistory _createHistory({
    String id = 'h-1',
    int chapterNumber = 1,
    int verseNumber = 1,
    int pageNumber = 1,
    int timestamp = 1000,
    int durationSeconds = 300,
    MushafType mushafType = MushafType.hafs1441,
  }) {
    return ReadingHistory(
      id: id,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      timestamp: timestamp,
      durationSeconds: durationSeconds,
      mushafType: mushafType,
    );
  }

  group('insertHistory', () {
    test('should store and retrieve a reading history entry', () async {
      await dao.insertHistory(_createHistory());

      final result = await dao.getRecentHistory(10);
      expect(result.length, 1);
      expect(result.first.id, 'h-1');
      expect(result.first.chapterNumber, 1);
      expect(result.first.durationSeconds, 300);
    });

    test('should store entry with specific mushaf type', () async {
      await dao.insertHistory(
        _createHistory(mushafType: MushafType.hafs1405),
      );

      final result = await dao.getRecentHistory(10);
      expect(result.first.mushafType, MushafType.hafs1405);
    });
  });

  group('getRecentHistory', () {
    test('should return empty list when no history', () async {
      final result = await dao.getRecentHistory(10);
      expect(result, isEmpty);
    });

    test('should return entries sorted by timestamp descending', () async {
      await dao.insertHistory(_createHistory(id: 'a', timestamp: 100));
      await dao.insertHistory(_createHistory(id: 'b', timestamp: 300));
      await dao.insertHistory(_createHistory(id: 'c', timestamp: 200));

      final result = await dao.getRecentHistory(10);
      expect(result[0].id, 'b');
      expect(result[1].id, 'c');
      expect(result[2].id, 'a');
    });

    test('should respect the limit parameter', () async {
      for (int i = 0; i < 5; i++) {
        await dao.insertHistory(_createHistory(id: 'h-$i', timestamp: i));
      }

      final result = await dao.getRecentHistory(3);
      expect(result.length, 3);
    });
  });

  group('getHistoryForChapter', () {
    test('should return entries for specific chapter', () async {
      await dao.insertHistory(
        _createHistory(id: '1', chapterNumber: 2),
      );
      await dao.insertHistory(
        _createHistory(id: '2', chapterNumber: 2),
      );
      await dao.insertHistory(
        _createHistory(id: '3', chapterNumber: 36),
      );

      final result = await dao.getHistoryForChapter(2);
      expect(result.length, 2);
      expect(result.every((h) => h.chapterNumber == 2), true);
    });

    test('should return empty list for chapter with no history', () async {
      final result = await dao.getHistoryForChapter(114);
      expect(result, isEmpty);
    });
  });

  group('getHistoryForDateRange', () {
    test('should return entries within timestamp range', () async {
      await dao.insertHistory(_createHistory(id: 'a', timestamp: 100));
      await dao.insertHistory(_createHistory(id: 'b', timestamp: 200));
      await dao.insertHistory(_createHistory(id: 'c', timestamp: 300));
      await dao.insertHistory(_createHistory(id: 'd', timestamp: 400));

      final result = await dao.getHistoryForDateRange(150, 350);
      expect(result.length, 2);
      expect(result.any((h) => h.id == 'b'), true);
      expect(result.any((h) => h.id == 'c'), true);
    });

    test('should return empty list when no entries in range', () async {
      await dao.insertHistory(_createHistory(timestamp: 100));
      final result = await dao.getHistoryForDateRange(500, 600);
      expect(result, isEmpty);
    });
  });

  group('deleteOlderThan', () {
    test('should remove entries older than timestamp', () async {
      await dao.insertHistory(_createHistory(id: 'old', timestamp: 100));
      await dao.insertHistory(_createHistory(id: 'new', timestamp: 500));

      await dao.deleteOlderThan(300);

      final result = await dao.getRecentHistory(10);
      expect(result.length, 1);
      expect(result.first.id, 'new');
    });
  });

  group('deleteAll', () {
    test('should remove all history entries', () async {
      await dao.insertHistory(_createHistory(id: 'a'));
      await dao.insertHistory(_createHistory(id: 'b'));

      await dao.deleteAll();
      final result = await dao.getRecentHistory(10);
      expect(result, isEmpty);
    });
  });

  group('getTotalReadingTime', () {
    test('should return zero when no history', () async {
      final result = await dao.getTotalReadingTime();
      expect(result, 0);
    });

    test('should sum all reading durations', () async {
      await dao.insertHistory(
        _createHistory(id: 'a', durationSeconds: 120),
      );
      await dao.insertHistory(
        _createHistory(id: 'b', durationSeconds: 180),
      );

      final result = await dao.getTotalReadingTime();
      expect(result, 300);
    });
  });

  group('getReadChapters', () {
    test('should return empty list when no history', () async {
      final result = await dao.getReadChapters();
      expect(result, isEmpty);
    });

    test('should return unique sorted chapter numbers', () async {
      await dao.insertHistory(
        _createHistory(id: '1', chapterNumber: 36),
      );
      await dao.insertHistory(
        _createHistory(id: '2', chapterNumber: 1),
      );
      await dao.insertHistory(
        _createHistory(id: '3', chapterNumber: 36),
      );
      await dao.insertHistory(
        _createHistory(id: '4', chapterNumber: 67),
      );

      final result = await dao.getReadChapters();
      expect(result, [1, 36, 67]);
    });
  });

  group('saveLastReadPosition', () {
    test('should save and retrieve last read position', () async {
      final position = LastReadPosition(
        mushafType: MushafType.hafs1441,
        chapterNumber: 2,
        verseNumber: 255,
        pageNumber: 42,
        lastReadAt: 1000,
        scrollPosition: 0.5,
      );

      await dao.saveLastReadPosition(position);
      final result = await dao.getLastReadPosition(MushafType.hafs1441);

      expect(result, isNotNull);
      expect(result!.chapterNumber, 2);
      expect(result.verseNumber, 255);
      expect(result.pageNumber, 42);
      expect(result.scrollPosition, 0.5);
    });

    test('should return null when no position saved', () async {
      final result = await dao.getLastReadPosition(MushafType.hafs1441);
      expect(result, isNull);
    });

    test('should save different positions per mushaf type', () async {
      await dao.saveLastReadPosition(LastReadPosition(
        mushafType: MushafType.hafs1441,
        chapterNumber: 1,
        verseNumber: 1,
        pageNumber: 1,
        lastReadAt: 1000,
      ));
      await dao.saveLastReadPosition(LastReadPosition(
        mushafType: MushafType.hafs1405,
        chapterNumber: 36,
        verseNumber: 1,
        pageNumber: 440,
        lastReadAt: 2000,
      ));

      final pos1441 = await dao.getLastReadPosition(MushafType.hafs1441);
      final pos1405 = await dao.getLastReadPosition(MushafType.hafs1405);

      expect(pos1441!.chapterNumber, 1);
      expect(pos1405!.chapterNumber, 36);
    });

    test('should overwrite previous position for same mushaf type', () async {
      await dao.saveLastReadPosition(LastReadPosition(
        mushafType: MushafType.hafs1441,
        chapterNumber: 1,
        verseNumber: 1,
        pageNumber: 1,
        lastReadAt: 1000,
      ));
      await dao.saveLastReadPosition(LastReadPosition(
        mushafType: MushafType.hafs1441,
        chapterNumber: 67,
        verseNumber: 1,
        pageNumber: 562,
        lastReadAt: 2000,
      ));

      final result = await dao.getLastReadPosition(MushafType.hafs1441);
      expect(result!.chapterNumber, 67);
      expect(result.pageNumber, 562);
    });
  });

  group('watchLastReadPosition', () {
    test('should emit initial position', () async {
      await dao.saveLastReadPosition(LastReadPosition(
        mushafType: MushafType.hafs1441,
        chapterNumber: 18,
        verseNumber: 1,
        pageNumber: 293,
        lastReadAt: 1000,
      ));

      final stream = dao.watchLastReadPosition(MushafType.hafs1441);
      final first = await stream.first;
      expect(first, isNotNull);
      expect(first!.chapterNumber, 18);
    });

    test('should emit null when no position saved', () async {
      final stream = dao.watchLastReadPosition(MushafType.hafs1405);
      final first = await stream.first;
      expect(first, isNull);
    });
  });
}
