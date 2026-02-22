/// Domain model for Quran Chapter (Surah).
/// Public API - exposed to library consumers.
class Chapter {
  final int identifier;
  final int number;
  final bool isMeccan;
  final String title;
  final String arabicTitle;
  final String englishTitle;
  final String titleCodePoint;
  final String searchableText;
  final String searchableKeywords;
  final int versesCount;

  const Chapter({
    required this.identifier,
    required this.number,
    required this.isMeccan,
    required this.title,
    required this.arabicTitle,
    required this.englishTitle,
    required this.titleCodePoint,
    required this.searchableText,
    required this.searchableKeywords,
    this.versesCount = 0,
  });

  /// Get the display title based on current locale.
  String getDisplayTitle({String languageCode = 'en'}) {
    return languageCode == 'ar' ? arabicTitle : englishTitle;
  }
}
