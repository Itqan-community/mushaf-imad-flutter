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
    final timestampsJson = json['timestamps'];

    if (timestampsJson != null && timestampsJson is! List) {
      throw FormatException(
        "Expected 'timestamps' to be a List, but got ${timestampsJson.runtimeType}",
      );
    }

    return QuranComAudioFile(
      id: (json['id'] as num).toInt(),
      chapterId: (json['chapter_id'] as num).toInt(),
      fileSize: (json['file_size'] as num).toDouble(),
      format: json['format'] as String,
      audioUrl: json['audio_url'] as String,
      timestamps: timestampsJson != null
          ? [
              for (final x in timestampsJson)
                if (x is Map<String, dynamic>)
                  QuranComVerseTiming.fromJson(x)
                else
                  throw FormatException(
                    "Expected each item in 'timestamps' to be a Map, but got ${x.runtimeType}",
                  )
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
    final audioFileJson = json['audio_file'];
    if (audioFileJson is! Map<String, dynamic>) {
      throw FormatException(
        "Missing, null, or non-object 'audio_file' in QuranComChapterAudioResponse.fromJson. Got: ${audioFileJson.runtimeType}",
      );
    }
    return QuranComChapterAudioResponse(
      audioFile: QuranComAudioFile.fromJson(audioFileJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {'audio_file': audioFile.toJson()};
  }
}
