/// Enum representing Hizb quarter progress.
enum HizbQuarterProgress { quarter, half, threeQuarters }

/// Domain model for Quran Quarter (Hizb fraction).
/// Represents one-quarter of a Hizb.
/// Public API - exposed to library consumers.
class Quarter {
  final int identifier;
  final int hizbNumber;
  final int hizbFraction; // 0=start, 1=quarter, 2=half, 3=three-quarters
  final String arabicTitle;
  final String englishTitle;
  final int partNumber;

  const Quarter({
    required this.identifier,
    required this.hizbNumber,
    required this.hizbFraction,
    required this.arabicTitle,
    required this.englishTitle,
    this.partNumber = 0,
  });

  /// Get the display title based on current locale.
  String getDisplayTitle({String languageCode = 'en'}) {
    return languageCode == 'ar' ? arabicTitle : englishTitle;
  }

  /// Get the Hizb quarter progress as a fraction.
  HizbQuarterProgress? getProgressFraction() {
    return switch (hizbFraction) {
      1 => HizbQuarterProgress.quarter,
      2 => HizbQuarterProgress.half,
      3 => HizbQuarterProgress.threeQuarters,
      _ => null,
    };
  }
}
