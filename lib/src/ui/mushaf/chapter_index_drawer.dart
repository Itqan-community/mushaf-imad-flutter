import 'package:flutter/material.dart';
import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../theme/mushaf_theme_scope.dart';
import '../theme/reading_theme.dart';

/// Drawer showing all 114 surahs for quick navigation.
///
/// Each surah shows its Arabic title, English title, and starting page.
/// Tapping a surah navigates to its starting page.
///
/// When a [MushafThemeScope] ancestor exists, colors are derived from the
/// active [ReadingThemeData] (matching Android's `MushafColors` pattern).
class ChapterIndexDrawer extends StatelessWidget {
  /// Callback when a chapter is selected, passes the starting page number.
  final ValueChanged<int> onChapterSelected;

  /// Currently displayed page number (to highlight the active chapter).
  final int currentPage;

  const ChapterIndexDrawer({
    super.key,
    required this.onChapterSelected,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final dataProvider = QuranDataProvider.instance;
    final chapters = dataProvider.getAllChapters();
    final currentChapters = dataProvider.getChaptersForPage(currentPage);
    final currentChapterNumbers = currentChapters.map((c) => c.number).toSet();

    // Read theme from scope (matching Android LocalMushafColors pattern)
    final scopeNotifier = MushafThemeScope.maybeOf(context);
    final theme =
        scopeNotifier?.themeData ??
        ReadingThemeData.fromTheme(ReadingTheme.light);

    return Drawer(
      backgroundColor: theme.backgroundColor,
      child: Column(
        children: [
          // Premium Header (Issue #52)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.accentColor,
                  theme.accentColor.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative element (faded icon)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    left: 20,
                    right: 20,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'فهرس السور',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '١١٤ سورة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chapter Index · Choose a Surah to start reading',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search/filter area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'Page ${QuranDataProvider.toArabicNumerals(currentPage)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.swipe, size: 16, color: theme.secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  'Tap to jump',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.secondaryTextColor.withValues(alpha: 0.3),
          ),

          // Chapter list
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isActive = currentChapterNumbers.contains(chapter.number);

                return _ChapterListItem(
                  chapter: chapter,
                  isActive: isActive,
                  themeData: theme,
                  onTap: () {
                    onChapterSelected(chapter.startPage);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterListItem extends StatelessWidget {
  final ChapterData chapter;
  final bool isActive;
  final ReadingThemeData themeData;
  final VoidCallback onTap;

  const _ChapterListItem({
    required this.chapter,
    required this.isActive,
    required this.themeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? themeData.highlightColor.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Chapter number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? themeData.accentColor
                      : themeData.surfaceColor,
                  border: Border.all(
                    color: themeData.secondaryTextColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${chapter.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : themeData.textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Chapter details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.arabicTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: themeData.textColor,
                        fontFamily: 'serif',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      chapter.englishTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeData.secondaryTextColor.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Verse count & page number
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'p. ${chapter.startPage}',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeData.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${chapter.versesCount} ayat',
                    style: TextStyle(
                      fontSize: 11,
                      color: themeData.secondaryTextColor.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
