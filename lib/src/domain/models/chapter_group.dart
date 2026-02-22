import 'chapter.dart';
import 'verse.dart';

/// Chapters grouped by Juz (Part).
/// Public API - exposed to library consumers.
class ChaptersByPart {
  final int id;
  final int partNumber;
  final String arabicTitle;
  final String englishTitle;
  final List<Chapter> chapters;
  final int? firstPage;
  final Verse? firstVerse;

  const ChaptersByPart({
    required this.id,
    required this.partNumber,
    required this.arabicTitle,
    required this.englishTitle,
    required this.chapters,
    this.firstPage,
    this.firstVerse,
  });
}

/// Chapters grouped by Quarter (Rub al-Hizb).
/// Public API - exposed to library consumers.
class ChaptersByQuarter {
  final int id;
  final int quarterNumber;
  final int hizbNumber;
  final int hizbFraction;
  final String arabicTitle;
  final String englishTitle;
  final List<Chapter> chapters;
  final int? firstPage;
  final Verse? firstVerse;

  const ChaptersByQuarter({
    required this.id,
    required this.quarterNumber,
    required this.hizbNumber,
    required this.hizbFraction,
    required this.arabicTitle,
    required this.englishTitle,
    required this.chapters,
    this.firstPage,
    this.firstVerse,
  });
}

/// Chapters grouped by Hizb.
/// Public API - exposed to library consumers.
class ChaptersByHizb {
  final int id;
  final int hizbNumber;
  final List<ChaptersByQuarter> quarters;

  const ChaptersByHizb({
    required this.id,
    required this.hizbNumber,
    required this.quarters,
  });

  String get hizbTitle => 'الحزب $hizbNumber';
}

/// Chapters grouped by type (Meccan/Medinan).
/// Public API - exposed to library consumers.
class ChaptersByType {
  final String id;
  final String type;
  final String arabicType;
  final List<Chapter> chapters;
  final int? firstPage;
  final Verse? firstVerse;

  const ChaptersByType({
    required this.id,
    required this.type,
    required this.arabicType,
    required this.chapters,
    this.firstPage,
    this.firstVerse,
  });

  bool get isMeccan => id == 'meccan';
}
