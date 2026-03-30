import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_chapter_audio.dart';
import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

void main() {
  group('AyahTiming parsing via QuranComAudioFile', () {
    test(
      'fromJson should parse verse timing correctly from Quran.com JSON',
      () {
        final json = {
          "id": 1,
          "chapter_id": 1,
          "file_size": 100.0,
          "format": "mp3",
          "audio_url": "https://example.com/1.mp3",
          "timestamps": [
            {
              "verse_key": "1:2",
              "timestamp_from": 4072,
              "timestamp_to": 9705,
              "duration": -5633,
              "segments": [
                [1, 4072, 5312],
                [2, 5312, 6322],
              ],
            },
          ],
        };

        final audioFile = QuranComAudioFile.fromJson(json);

        expect(audioFile.timestamps, isNotNull);
        expect(audioFile.timestamps!.length, 1);

        final timing = audioFile.timestamps!.first;
        expect(timing.ayah, 2);
        expect(timing.startTime, 4072);
        expect(timing.endTime, 9705);
      },
    );

    test('fromJson should handle null timestamps', () {
      final json = {
        "id": 1,
        "chapter_id": 1,
        "file_size": 100.0,
        "format": "mp3",
        "audio_url": "https://example.com/1.mp3",
      };

      final audioFile = QuranComAudioFile.fromJson(json);
      expect(audioFile.timestamps, isNull);
    });

    test('toJson should serialize AyahTiming list correctly', () {
      final audioFile = QuranComAudioFile(
        id: 7,
        chapterId: 114,
        fileSize: 500,
        format: "mp3",
        audioUrl: "url",
        timestamps: [AyahTiming(ayah: 1, startTime: 100, endTime: 200)],
      );

      final json = audioFile.toJson();
      expect(json['timestamps'], isList);
      expect(json['timestamps'].length, 1);
      expect(json['timestamps'][0]['ayah'], 1);
      expect(json['timestamps'][0]['start_time'], 100);
      expect(json['timestamps'][0]['end_time'], 200);
    });
  });

  group('QuranComAudioFile', () {
    test('fromJson should parse complete audio file data with timestamps', () {
      final json = {
        "id": 457,
        "chapter_id": 1,
        "file_size": 710784,
        "format": "mp3",
        "audio_url":
            "https://download.quranicaudio.com/qdc/abu_bakr_shatri/murattal/1.mp3",
        "timestamps": [
          {
            "verse_key": "1:1",
            "timestamp_from": 0,
            "timestamp_to": 6493,
            "duration": -6493,
            "segments": [
              [1, 0, 630],
              [2, 650, 1570],
              [3, 1570, 3110],
              [4, 3110, 5590],
            ],
          },
        ],
      };

      final audioFile = QuranComAudioFile.fromJson(json);

      expect(audioFile.id, 457);
      expect(audioFile.chapterId, 1);
      expect(audioFile.fileSize, 710784);
      expect(audioFile.format, "mp3");
      expect(
        audioFile.audioUrl,
        "https://download.quranicaudio.com/qdc/abu_bakr_shatri/murattal/1.mp3",
      );
      expect(audioFile.timestamps, isNotNull);
      expect(audioFile.timestamps!.length, 1);
      // Now we get AyahTiming, not QuranComVerseTiming
      expect(audioFile.timestamps![0].ayah, 1);
      expect(audioFile.timestamps![0].startTime, 0);
      expect(audioFile.timestamps![0].endTime, 6493);
    });

    test('fromJson should handle audio file without timestamps', () {
      final json = {
        "id": 457,
        "chapter_id": 1,
        "file_size": 710784,
        "format": "mp3",
        "audio_url":
            "https://download.quranicaudio.com/qdc/abu_bakr_shatri/murattal/1.mp3",
      };

      final audioFile = QuranComAudioFile.fromJson(json);

      expect(audioFile.id, 457);
      expect(audioFile.timestamps, isNull);
    });

    test('toJson should correctly serialize audio file', () {
      final audioFile = QuranComAudioFile(
        id: 7,
        chapterId: 114,
        fileSize: 500,
        format: "mp3",
        audioUrl: "url",
        timestamps: [],
      );

      final json = audioFile.toJson();
      expect(json['id'], 7);
      expect(json['chapter_id'], 114);
      expect(json['timestamps'], isEmpty);
    });
  });

  group('QuranComChapterAudioResponse', () {
    test('fromJson should parse top-level response correctly', () {
      final json = {
        "audio_file": {
          "id": 457,
          "chapter_id": 1,
          "file_size": 710784,
          "format": "mp3",
          "audio_url":
              "https://download.quranicaudio.com/qdc/abu_bakr_shatri/murattal/1.mp3",
        },
      };

      final response = QuranComChapterAudioResponse.fromJson(json);

      expect(response.audioFile.id, 457);
      expect(response.audioFile.chapterId, 1);
    });

    test('toJson should produce correct top-level key', () {
      final audioFile = QuranComAudioFile(
        id: 1,
        chapterId: 1,
        fileSize: 100,
        format: 'mp3',
        audioUrl: 'url',
      );
      final response = QuranComChapterAudioResponse(audioFile: audioFile);

      final json = response.toJson();
      expect(json['audio_file'], isMap);
      expect(json['audio_file']['id'], 1);
    });
  });
}
