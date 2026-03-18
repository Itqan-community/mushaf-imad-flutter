/// A class that represents the timing of a verse in the Quran.
/// Related to (QuranComAudioFile) class.
class QuranComVerseTiming {
  /// The verse key in the format "chapter:verse".
  final String verseKey;

  /// The timestamp from which the verse starts (in milliseconds).
  final int timestampFrom;

  /// The timestamp at which the verse ends (in milliseconds).
  final int timestampTo;

  /// The duration of the verse (in milliseconds).
  final int duration;

  /// The segments of the verse (word_index, start_ms, end_ms) triplets.
  ///
  /// For efficient memory storage, I used a List of Records (tuples) instead of a List of Lists.
  /// Note: The segments field is optional and may be null if timing data is not available.
  final List<({int wordIndex, int startMs, int endMs})>? segments;

  QuranComVerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
    this.segments,
  });

  factory QuranComVerseTiming.fromJson(Map<String, dynamic> json) {
    return QuranComVerseTiming(
      verseKey: json['verse_key'] as String? ?? '',
      timestampFrom: (json['timestamp_from'] as num?)?.toInt() ?? 0,
      timestampTo: (json['timestamp_to'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      segments: json['segments'] != null
          // After searching for which is more efficient here (for loop VS map)
          // Where list.map is more readable , I chose for loop because it is more efficient
          ? [
              for (final segment in json['segments'])
                if (segment is List && segment.isNotEmpty)
                  (
                    wordIndex: (segment[0] as num?)?.toInt() ?? 0,
                    startMs: segment.length > 1
                        ? (segment[1] as num?)?.toInt() ?? 0
                        : 0,
                    endMs:
                        segment.length > 2 ? (segment[2] as num?)?.toInt() ?? 0 : 0,
                  ),
            ]
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verse_key': verseKey,
      'timestamp_from': timestampFrom,
      'timestamp_to': timestampTo,
      'duration': duration,
      'segments': segments
          ?.map((e) => [e.wordIndex, e.startMs, e.endMs])
          .toList(),
    };
  }
}
