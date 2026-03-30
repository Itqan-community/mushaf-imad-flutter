import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

/// Models for Quran.com chapter audio response, including the audio file details and verse timings.
class QuranComAudioFile {
  /// Unique identifier for the audio file.
  final int id;

  /// The chapter ID that this audio file corresponds to.
  final int chapterId;

  /// The size of the audio file in bytes.
  final double? fileSize;

  /// The audio format (e.g., "mp3").
  final String format;

  /// The URL where the audio file can be accessed.
  final String audioUrl;

  /// A list of verse timings that provide detailed timing information for each verse in the chapter.
  final List<AyahTiming>? timestamps;

  QuranComAudioFile({
    required this.id,
    required this.chapterId,
    this.fileSize,
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      chapterId: (json['chapter_id'] as num?)?.toInt() ?? 0,
      fileSize: (json['file_size'] as num?)?.toDouble(),
      format: json['format'] as String? ?? 'mp3',
      audioUrl: json['audio_url'] as String,
      timestamps: timestampsJson != null
          ? [
              for (final x in timestampsJson)
                if (x is Map<String, dynamic>)
                  _parseAyahTiming(x)
                else
                  throw FormatException(
                    "Expected each item in 'timestamps' to be a Map, but got ${x.runtimeType}",
                  ),
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

/// Parses a Quran.com timestamp JSON object into an [AyahTiming].
/// Extracts the ayah number from the "chapter:ayah" format in `verse_key`.
AyahTiming _parseAyahTiming(Map<String, dynamic> json) {
  final verseKey = json['verse_key'] as String? ?? '';
  final parts = verseKey.split(':');
  final ayahNumber = parts.length >= 2 ? (int.tryParse(parts.last) ?? 0) : 0;

  return AyahTiming(
    ayah: ayahNumber,
    startTime: (json['timestamp_from'] as num?)?.toInt() ?? 0,
    endTime: (json['timestamp_to'] as num?)?.toInt() ?? 0,
  );
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
