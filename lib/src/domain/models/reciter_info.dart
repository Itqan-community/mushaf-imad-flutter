/// Information about a Quran reciter.
/// Public API - exposed to library consumers.
class ReciterInfo {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String rewaya; // Recitation style (e.g., "حفص عن عاصم")
  final String folderUrl; // Base URL for audio files
  final Map<int, String> chapterAudioUrls;

  const ReciterInfo({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.rewaya,
    required this.folderUrl,
    this.chapterAudioUrls = const {},
  });

  /// Get reciter display name based on language.
  String getDisplayName({String languageCode = 'en'}) {
    return languageCode == 'ar' ? nameArabic : nameEnglish;
  }

  /// Get audio URL for a specific chapter (surah).
  String getAudioUrl(int chapterNumber) {
    final chapterUrl = chapterAudioUrls[chapterNumber];
    if (chapterUrl != null && chapterUrl.isNotEmpty) {
      return chapterUrl;
    }
    final paddedChapter = chapterNumber.toString().padLeft(3, '0');
    return '$folderUrl$paddedChapter.mp3';
  }

  /// Check if this reciter uses Hafs recitation.
  bool get isHafs =>
      rewaya.toLowerCase().contains('حفص') ||
      rewaya.toLowerCase().contains('hafs');

  /// Check if this reciter uses Warsh recitation.
  bool get isWarsh =>
      rewaya.toLowerCase().contains('ورش') ||
      rewaya.toLowerCase().contains('warsh');
}
