import 'package:imad_flutter/src/data/audio/quran_com/qurancom_verse_timing.dart';

/// Models for Quran.com chapter audio response, including the audio file details and verse timings.
class QuranComAudioFile {
  /// Unique identifier for the audio file.
  final int id;
  /// The chapter ID that this audio file corresponds to.
  final int chapterId;
  /// The size of the audio file in bytes.
  final double fileSize;
  /// The audio format (e.g., "mp3").
  final String format;
  /// The URL where the audio file can be accessed.
  final String audioUrl;
  /// A list of verse timings that provide detailed timing information for each verse in the chapter.
  final List<QuranComVerseTiming>? timestamps;

  QuranComAudioFile({
    required this.id,
    required this.chapterId,
    required this.fileSize,
    required this.format,
    required this.audioUrl,
    this.timestamps,
  });

  factory QuranComAudioFile.fromJson(Map<String, dynamic> json) {
    return QuranComAudioFile(
      id: json['id'] as int,
      chapterId: json['chapter_id'] as int,
      fileSize: (json['file_size'] as num).toDouble(),
      format: json['format'],
      audioUrl: json['audio_url'],
      timestamps: json['timestamps'] != null
          ? [
              for (final x in json['timestamps'])
                QuranComVerseTiming.fromJson(x),
            ]
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'file_size': fileSize,
      'format': format,
      'audio_url': audioUrl,
      'timestamps': timestamps?.map((x) => x.toJson()).toList(),
    };
  }
}

/// Wrapper for chapter audio response which typically contains an 'audio_file' key.
class QuranComChapterAudioResponse {
  final QuranComAudioFile audioFile;

  QuranComChapterAudioResponse({required this.audioFile});

  factory QuranComChapterAudioResponse.fromJson(Map<String, dynamic> json) {
    return QuranComChapterAudioResponse(
      audioFile: QuranComAudioFile.fromJson(json['audio_file']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'audio_file': audioFile.toJson()};
  }
}
