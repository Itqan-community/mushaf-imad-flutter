/// Information about a Quran reciter.
/// Public API - exposed to library consumers.
class ReciterInfo {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String rewaya; // Recitation style (e.g., "حفص عن عاصم")
  final String folderUrl; // Base URL for audio files

  const ReciterInfo({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.rewaya,
    required this.folderUrl,
  });

  /// Get reciter display name based on language.
  String getDisplayName({String languageCode = 'en'}) {
    return languageCode == 'ar' ? nameArabic : nameEnglish;
  }

  /// Get audio URL for a specific chapter (surah).
  String getAudioUrl(int chapterNumber) {
    final paddedChapter = chapterNumber.toString().padLeft(3, '0');
    return '$folderUrl$paddedChapter.mp3';
  }

  /// ✅ NEW: Get audio URL for a specific ayah.
  /// This builds a URL pattern like: folderUrl/001002.mp3 (Chapter 1, Ayah 2)
  String getAyahUrl({required int chapterNumber, required int ayahNumber}) {
    final paddedChapter = chapterNumber.toString().padLeft(3, '0');
    final paddedAyah = ayahNumber.toString().padLeft(3, '0');
    return '$folderUrl$paddedChapter$paddedAyah.mp3';
  }

  /// ✅ NEW: Get verse count for a chapter.
  /// This is a helper. In a real app, you might fetch this from a metadata list.
  /// For now, we use a standard list of verse counts for the 114 surahs.
  int getChapterVerseCount(int chapterNumber) {
    if (chapterNumber < 1 || chapterNumber > 114) return 0;
    const surahVerseCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
      111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
      54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
      49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
      44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
      26, 30, 20, 15, 21, 11, 8, 8, 11, 5, 4, 5, 6, 3, 6, 3, 5, 4, 5, 3, 6, 3,
      5, 4, 5, 3, 6
    ];
    return surahVerseCounts[chapterNumber - 1];
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
