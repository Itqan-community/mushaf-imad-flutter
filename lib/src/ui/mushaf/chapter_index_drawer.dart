import 'package:flutter/material.dart';
import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/quran_metadata.dart';
import '../theme/mushaf_theme_scope.dart';
import '../theme/reading_theme.dart';

enum _ChapterFilter { all, meccan, medinan }

class ChapterIndexDrawer extends StatefulWidget {
  final ValueChanged<int> onChapterSelected;
  final int currentPage;

  const ChapterIndexDrawer({
    super.key,
    required this.onChapterSelected,
    required this.currentPage,
  });

  @override
  State<ChapterIndexDrawer> createState() => _ChapterIndexDrawerState();
}

class _ChapterIndexDrawerState extends State<ChapterIndexDrawer> {
  _ChapterFilter _filter = _ChapterFilter.all;

  List<ChapterData> _applyFilter(List<ChapterData> chapters) {
    switch (_filter) {
      case _ChapterFilter.all:
        return chapters;
      case _ChapterFilter.meccan:
        return chapters.where((c) => c.isMeccan).toList();
      case _ChapterFilter.medinan:
        return chapters.where((c) => !c.isMeccan).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = QuranDataProvider.instance;
    final allChapters = dataProvider.getAllChapters();
    final filteredChapters = _applyFilter(allChapters);
    final currentChapters = dataProvider.getChaptersForPage(widget.currentPage);
    final currentChapterNumbers = currentChapters.map((c) => c.number).toSet();

    final scopeNotifier = MushafThemeScope.maybeOf(context);
    final theme =
        scopeNotifier?.themeData ??
        ReadingThemeData.fromTheme(ReadingTheme.light);

    return Drawer(
      backgroundColor: theme.backgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(color: theme.accentColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فهرس السور',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  'Chapter Index · ${allChapters.length} Surahs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'الكل',
                  selected: _filter == _ChapterFilter.all,
                  theme: theme,
                  onTap: () => setState(() => _filter = _ChapterFilter.all),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'مكية',
                  selected: _filter == _ChapterFilter.meccan,
                  theme: theme,
                  onTap: () => setState(() => _filter = _ChapterFilter.meccan),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'مدنية',
                  selected: _filter == _ChapterFilter.medinan,
                  theme: theme,
                  onTap: () => setState(() => _filter = _ChapterFilter.medinan),
                ),
                const Spacer(),
                Text(
                  'Page ${QuranDataProvider.toArabicNumerals(widget.currentPage)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.secondaryTextColor.withValues(alpha: 0.3),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredChapters.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final chapter = filteredChapters[index];
                final isActive = currentChapterNumbers.contains(chapter.number);

                return _ChapterListItem(
                  chapter: chapter,
                  isActive: isActive,
                  themeData: theme,
                  onTap: () {
                    widget.onChapterSelected(chapter.startPage);
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ReadingThemeData theme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.accentColor : theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.accentColor
                : theme.secondaryTextColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : theme.textColor,
          ),
          textDirection: TextDirection.rtl,
        ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chapter.isMeccan ? 'مكية' : 'مدنية',
                        style: TextStyle(
                          fontSize: 10,
                          color: themeData.secondaryTextColor.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(width: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
