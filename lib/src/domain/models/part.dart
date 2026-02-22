/// Domain model for Quran Part (Juz).
/// Represents one of the 30 parts of the Quran.
/// Public API - exposed to library consumers.
class Part {
  final int identifier;
  final int number;
  final String arabicTitle;
  final String englishTitle;

  const Part({
    required this.identifier,
    required this.number,
    required this.arabicTitle,
    required this.englishTitle,
  });

  /// Get the display title based on current locale.
  String getDisplayTitle({String languageCode = 'en'}) {
    return languageCode == 'ar' ? arabicTitle : englishTitle;
  }
}
