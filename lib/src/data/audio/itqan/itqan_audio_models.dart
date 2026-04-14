import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

/// Data models specifically for the Itqan CMS API payload.

class ItqanRecitationSurahTrack {
  final int surahNumber;
  final String audioUrl;
  final List<ItqanAyahTiming> ayahsTimings;

  ItqanRecitationSurahTrack({
    required this.surahNumber,
    required this.audioUrl,
    required this.ayahsTimings,
  });

  factory ItqanRecitationSurahTrack.fromJson(Map<String, dynamic> json) {
    return ItqanRecitationSurahTrack(
      surahNumber: json['surah_number'] as int,
      audioUrl: json['audio_url'] as String,
      ayahsTimings:
          (json['ayahs_timings'] as List<dynamic>?)
              ?.map((e) => ItqanAyahTiming.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ItqanAyahTiming {
  final String ayahKey;
  final int startMs;
  final int endMs;

  ItqanAyahTiming({
    required this.ayahKey,
    required this.startMs,
    required this.endMs,
  });

  factory ItqanAyahTiming.fromJson(Map<String, dynamic> json) {
    return ItqanAyahTiming(
      ayahKey: json['ayah_key'] as String,
      startMs: json['start_ms'] as int,
      endMs: json['end_ms'] as int,
    );
  }

  /// Convert the CMS verseKey ("chapter:ayah") into the unified library model `AyahTiming`.
  AyahTiming toAyahTiming() {
    final parts = ayahKey.split(':');
    final ayahNum = parts.length > 1 ? int.parse(parts[1]) : 0;

    return AyahTiming(ayah: ayahNum, startTime: startMs, endTime: endMs);
  }
}
