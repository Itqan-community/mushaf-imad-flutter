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
      verseKey: json['verse_key'],
      timestampFrom: json['timestamp_from'],
      timestampTo: json['timestamp_to'],
      duration: json['duration'],
      segments: json['segments'] != null
          // After searching for which is more efficient here (for loop VS map)
          // Where list.map is more readable , I chose for loop because it is more efficient
          ? [
              for (final segment in json['segments'])
                (
                  wordIndex: segment[0] as int,
                  startMs: segment[1] as int,
                  endMs: segment[2] as int,
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
