/// Timing data for a reciter.
/// Used for audio-verse synchronization.
/// Public API - exposed to library consumers.
class ReciterTiming {
  final int id;
  final String name;
  final String nameEn;
  final String rewaya;
  final String folderUrl;
  final List<ChapterTiming> chapters;

  const ReciterTiming({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.rewaya,
    required this.folderUrl,
    required this.chapters,
  });

  factory ReciterTiming.fromJson(Map<String, dynamic> json) {
    return ReciterTiming(
      id: json['id'] as int,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      rewaya: json['rewaya'] as String,
      folderUrl: json['folder_url'] as String,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => ChapterTiming.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_en': nameEn,
    'rewaya': rewaya,
    'folder_url': folderUrl,
    'chapters': chapters.map((e) => e.toJson()).toList(),
  };
}

class ChapterTiming {
  final int id;
  final String name;
  final List<AyahTiming> ayaTiming;

  const ChapterTiming({
    required this.id,
    required this.name,
    required this.ayaTiming,
  });

  factory ChapterTiming.fromJson(Map<String, dynamic> json) {
    return ChapterTiming(
      id: json['id'] as int,
      name: json['name'] as String,
      ayaTiming: (json['aya_timing'] as List<dynamic>)
          .map((e) => AyahTiming.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aya_timing': ayaTiming.map((e) => e.toJson()).toList(),
  };
}

class AyahTiming {
  final int ayah;
  final int startTime; // in milliseconds
  final int endTime; // in milliseconds

  const AyahTiming({
    required this.ayah,
    required this.startTime,
    required this.endTime,
  });

  factory AyahTiming.fromJson(Map<String, dynamic> json) {
    return AyahTiming(
      ayah: json['ayah'] as int,
      startTime: json['start_time'] as int,
      endTime: json['end_time'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'ayah': ayah,
    'start_time': startTime,
    'end_time': endTime,
  };
}
