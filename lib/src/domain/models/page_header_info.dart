import 'quarter.dart';

/// Summary of a chapter suitable for displaying in headers and lists.
/// Public API - exposed to library consumers.
class ChapterInfo {
  final int number;
  final String arabicTitle;
  final String englishTitle;

  const ChapterInfo({
    required this.number,
    required this.arabicTitle,
    required this.englishTitle,
  });
}

/// Lightweight structure describing the contextual header for a Mushaf page.
/// Public API - exposed to library consumers.
class PageHeaderInfo {
  final int? partNumber;
  final String? partArabicTitle;
  final String? partEnglishTitle;
  final int? hizbNumber;
  final int? hizbFraction;
  final String? quarterArabicTitle;
  final String? quarterEnglishTitle;
  final List<ChapterInfo> chapters;

  const PageHeaderInfo({
    this.partNumber,
    this.partArabicTitle,
    this.partEnglishTitle,
    this.hizbNumber,
    this.hizbFraction,
    this.quarterArabicTitle,
    this.quarterEnglishTitle,
    required this.chapters,
  });

  /// Get the Hizb quarter progress based on fraction.
  HizbQuarterProgress? get hizbQuarterProgress {
    return switch (hizbFraction) {
      1 => HizbQuarterProgress.quarter,
      2 => HizbQuarterProgress.half,
      3 => HizbQuarterProgress.threeQuarters,
      _ => null,
    };
  }

  /// Get the Hizb display string in Arabic.
  String? get hizbDisplay {
    final hizbNum = hizbNumber;
    if (hizbNum == null) return null;
    final fraction = hizbFraction ?? 0;

    return switch (fraction) {
      1 => '¼ الحزب $hizbNum',
      2 => '½ الحزب $hizbNum',
      3 => '¾ الحزب $hizbNum',
      _ => 'الحزب $hizbNum',
    };
  }

  /// Get the Juz display string in Arabic.
  String? get juzDisplay {
    final partNum = partNumber;
    if (partNum == null) return null;
    return 'الجزء $partNum';
  }
}
