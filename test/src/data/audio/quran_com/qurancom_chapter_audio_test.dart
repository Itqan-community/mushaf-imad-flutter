import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_chapter_audio.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_verse_timing.dart';

void main() {
  group('QuranComVerseTiming', () {
    test('fromJson should parse verse timing with segments correctly', () {
      final json = {
        "verse_key": "1:2",
        "timestamp_from": 4072,
        "timestamp_to": 9705,
        "duration": -5633,
        "segments": [
          [1, 4072, 5312],
          [2, 5312, 6322],
          [3, 6322, 6882],
          [4, 6882, 9307],
        ],
      };

      final timing = QuranComVerseTiming.fromJson(json);

      expect(timing.verseKey, "1:2");
      expect(timing.timestampFrom, 4072);
      expect(timing.timestampTo, 9705);
      expect(timing.duration, -5633);
      expect(timing.segments, isNotNull);
      expect(timing.segments!.length, 4);
      expect(timing.segments![0].wordIndex, 1);
      expect(timing.segments![0].startMs, 4072);
      expect(timing.segments![3].endMs, 9307);
    });

    test('fromJson should handle null segments', () {
      final json = {
        "verse_key": "1:1",
        "timestamp_from": 0,
        "timestamp_to": 4072,
        "duration": 4072,
        "segments": null,
      };

      final timing = QuranComVerseTiming.fromJson(json);
      expect(timing.segments, isNull);
    });

    test('toJson should preserve segment structure', () {
      final segments = [(wordIndex: 1, startMs: 100, endMs: 200)];
      final timing = QuranComVerseTiming(
        verseKey: "2:1",
        timestampFrom: 100,
        timestampTo: 200,
        duration: 100,
        segments: segments,
      );

      final json = timing.toJson();
      expect(json['segments'], isList);
      expect(json['segments'][0], [1, 100, 200]);
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
      expect(audioFile.timestamps![0].verseKey, "1:1");
      expect(audioFile.timestamps![0].segments!.length, 4);
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
