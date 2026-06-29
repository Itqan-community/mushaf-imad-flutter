import '../../domain/models/chapter_filter.dart';
import 'quran_metadata.dart';

/// Provides Quran page data — chapters, juz, and page metadata.
///
/// Uses static metadata from [quran_metadata.dart] for fast lookups
/// without needing database access.
class QuranDataProvider {
  QuranDataProvider._();

  static final QuranDataProvider _instance = QuranDataProvider._();
  static QuranDataProvider get instance => _instance;

  /// Total pages in the Mushaf.
  static const int totalPages = 604;

  /// Total chapters in the Quran.
  static const int totalChapters = 114;

  /// Lines per page.
  static const int linesPerPage = 15;

  /// Get all chapters.
  List<ChapterData> getAllChapters() => allChapters;

  /// Get chapter by number (1-indexed).
  ChapterData getChapter(int chapterNumber) {
    return allChapters[chapterNumber - 1];
  }

  /// Get chapters appearing on a given page.
  List<ChapterData> getChaptersForPage(int pageNumber) {
    final chapters = <ChapterData>[];
    for (int i = 0; i < allChapters.length; i++) {
      final chapter = allChapters[i];
      final nextChapterStart = i + 1 < allChapters.length
          ? allChapters[i + 1].startPage
          : totalPages + 1;

      if (chapter.startPage <= pageNumber && nextChapterStart > pageNumber) {
        chapters.add(chapter);
      }
      // Also add chapter that starts on this exact page
      if (chapter.startPage == pageNumber && !chapters.contains(chapter)) {
        chapters.add(chapter);
      }
    }
    // Deduplicate
    final seen = <int>{};
    return chapters.where((c) => seen.add(c.number)).toList();
  }

  /// Get chapters filtered by the given [filter] criteria.
  ///
  /// Returns all 114 chapters when no filter is applied.
  /// Example:
  /// ```dart
  /// final meccanChapters = QuranDataProvider.instance.getFilteredChapters(
  ///   const ChapterFilter(revelationType: RevelationType.meccan),
  /// );
  /// ```
  List<ChapterData> getFilteredChapters(ChapterFilter filter) {
    return switch (filter.revelationType) {
      RevelationType.all => [...getAllChapters()],
      RevelationType.meccan =>
        getAllChapters().where((c) => c.isMeccan).toList(growable: false),
      RevelationType.medinan =>
        getAllChapters().where((c) => !c.isMeccan).toList(growable: false),
    };
  }

  /// Get juz number for a given page.
  int getJuzForPage(int pageNumber) {
    for (int i = juzStartPages.length - 1; i >= 0; i--) {
      if (pageNumber >= juzStartPages[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Get the starting page for a chapter.
  int getPageForChapter(int chapterNumber) {
    return allChapters[chapterNumber - 1].startPage;
  }

  /// Get the starting page for a juz.
  int getPageForJuz(int juzNumber) {
    return juzStartPages[juzNumber - 1];
  }

  /// Get the asset path for a line image.
  static String getLineImagePath(int page, int line) {
    return 'assets/quran-images/$page/$line.png';
  }

  /// Convert a number to Arabic-Indic numerals.
  static String toArabicNumerals(int number) {
    const arabicNumerals = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return number
        .toString()
        .split('')
        .map((d) => arabicNumerals[d] ?? d)
        .join();
  }
}
