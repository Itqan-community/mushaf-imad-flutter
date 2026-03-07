import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:imad_flutter/src/data/audio/ayah_timing_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => Directory.systemTemp.path,
      );

  const testReciterId = 1;
  const testTimingJson = {
    'id': 1,
    'name': 'عبد الباسط عبد الصمد',
    'name_en': 'Abdul Basit',
    'rewaya': 'حفص عن عاصم',
    'folder_url': 'https://example.com/audio/',
    'chapters': [
      {
        'id': 1,
        'name': 'الفاتحة',
        'aya_timing': [
          {'ayah': 1, 'start_time': 0, 'end_time': 5000},
          {'ayah': 2, 'start_time': 5000, 'end_time': 9000},
          {'ayah': 3, 'start_time': 9000, 'end_time': 12000},
          {'ayah': 4, 'start_time': 12000, 'end_time': 16000},
          {'ayah': 5, 'start_time': 16000, 'end_time': 20000},
          {'ayah': 6, 'start_time': 20000, 'end_time': 30000},
          {'ayah': 7, 'start_time': 30000, 'end_time': 38000},
        ],
      },
      {
        'id': 2,
        'name': 'البقرة',
        'aya_timing': [
          {'ayah': 1, 'start_time': 0, 'end_time': 8000},
          {'ayah': 2, 'start_time': 8000, 'end_time': 25000},
        ],
      },
    ],
  };

  late AyahTimingService service;

  setUp(() {
    service = AyahTimingService();

    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key ==
            'packages/imad_flutter/assets/ayah_timing/read_$testReciterId.json') {
          final jsonStr = jsonEncode(testTimingJson);
          return ByteData.view(Uint8List.fromList(utf8.encode(jsonStr)).buffer);
        }
        return null;
      },
    );
  });

  tearDown(() {
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
  });

  group('loadTimingData', () {
    test('should load timing data for valid reciter', () async {
      final result = await service.loadTimingData(testReciterId);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.nameEn, 'Abdul Basit');
      expect(result.chapters.length, 2);
    });

    test('should return null for non-existent reciter', () async {
      final result = await service.loadTimingData(999);
      expect(result, isNull);
    });

    test('should cache loaded timing data', () async {
      await service.loadTimingData(testReciterId);
      expect(service.hasTimingForReciter(testReciterId), true);

      final cached = await service.loadTimingData(testReciterId);
      expect(cached, isNotNull);
      expect(cached!.id, 1);
    });
  });

  group('getAyahTiming', () {
    test('should return timing for specific ayah', () async {
      final result = await service.getAyahTiming(testReciterId, 1, 1);

      expect(result, isNotNull);
      expect(result!.ayah, 1);
      expect(result.startTime, 0);
      expect(result.endTime, 5000);
    });

    test('should return correct timing for middle ayah', () async {
      final result = await service.getAyahTiming(testReciterId, 1, 4);

      expect(result, isNotNull);
      expect(result!.startTime, 12000);
      expect(result.endTime, 16000);
    });

    test('should return null for non-existent chapter', () async {
      final result = await service.getAyahTiming(testReciterId, 114, 1);
      expect(result, isNull);
    });

    test('should return null for non-existent ayah', () async {
      final result = await service.getAyahTiming(testReciterId, 1, 99);
      expect(result, isNull);
    });

    test('should return null for non-existent reciter', () async {
      final result = await service.getAyahTiming(999, 1, 1);
      expect(result, isNull);
    });
  });

  group('getCurrentVerse', () {
    test('should return verse at given playback time', () async {
      final result = await service.getCurrentVerse(testReciterId, 1, 6000);
      expect(result, 2); // 5000-9000 range
    });

    test('should return first verse at time zero', () async {
      final result = await service.getCurrentVerse(testReciterId, 1, 0);
      expect(result, 1);
    });

    test('should return last verse near end', () async {
      final result = await service.getCurrentVerse(testReciterId, 1, 35000);
      expect(result, 7); // 30000-38000 range
    });

    test('should return null when time is beyond all ayahs', () async {
      final result = await service.getCurrentVerse(testReciterId, 1, 50000);
      expect(result, isNull);
    });

    test('should return null for non-existent reciter', () async {
      final result = await service.getCurrentVerse(999, 1, 0);
      expect(result, isNull);
    });
  });

  group('getChapterTimings', () {
    test('should return all timings for a chapter', () async {
      final result = await service.getChapterTimings(testReciterId, 1);

      expect(result.length, 7);
      expect(result.first.ayah, 1);
      expect(result.last.ayah, 7);
    });

    test('should return timings for second chapter', () async {
      final result = await service.getChapterTimings(testReciterId, 2);
      expect(result.length, 2);
    });

    test('should return empty list for non-existent chapter', () async {
      final result = await service.getChapterTimings(testReciterId, 114);
      expect(result, isEmpty);
    });

    test('should return empty list for non-existent reciter', () async {
      final result = await service.getChapterTimings(999, 1);
      expect(result, isEmpty);
    });
  });

  group('hasTimingForReciter', () {
    test('should return false before loading', () {
      expect(service.hasTimingForReciter(testReciterId), false);
    });

    test('should return true after loading', () async {
      await service.loadTimingData(testReciterId);
      expect(service.hasTimingForReciter(testReciterId), true);
    });
  });

  group('preloadTiming', () {
    test('should preload timing data into cache', () async {
      expect(service.hasTimingForReciter(testReciterId), false);
      await service.preloadTiming(testReciterId);
      expect(service.hasTimingForReciter(testReciterId), true);
    });
  });
}
