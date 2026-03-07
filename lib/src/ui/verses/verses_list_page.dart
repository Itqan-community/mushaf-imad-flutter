import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../di/core_module.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/verse_repository.dart';
import '../../domain/repository/preferences_repository.dart';
import 'verses_list_view_model.dart';

/// A page that displays all 6,236 Quran verses in a scrollable list with
/// toggles for three text-display modes:
///
///  • **Uthmanic** – the ʿUthmānī Ḥafṣ orthography.
///  • **Plain (with Tashkīl)** – standard Arabic with diacritics.
///  • **Plain (without Tashkīl)** – simplified text without diacritics.
///
/// ## Usage
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => VersesListPage(
///       onVerseSelected: (pageNumber) {
///         // Navigate to the Mushaf page
///       },
///     ),
///   ),
/// );
/// ```
class VersesListPage extends StatefulWidget {
  /// Called when a verse is tapped – receives the Mushaf page number.
  final void Function(int pageNumber)? onVerseSelected;

  const VersesListPage({super.key, this.onVerseSelected});

  @override
  State<VersesListPage> createState() => _VersesListPageState();
}

class _VersesListPageState extends State<VersesListPage> {
  late final VersesListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VersesListViewModel(
      verseRepository: mushafGetIt<VerseRepository>(),
      chapterRepository: mushafGetIt<ChapterRepository>(),
      preferencesRepository: mushafGetIt<PreferencesRepository>(),
    );
    _viewModel.loadAllVerses();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Column(
          children: [
            // Display-mode toggle chips
            _buildDisplayModeChips(context),

            // Content area
            Expanded(child: _buildContent(context)),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Display Mode Chips
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDisplayModeChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected:
                _viewModel.displayMode == VerseTextDisplayMode.uthmanic,
            label: const Text('Uthmanic'),
            onSelected: (_) =>
                _viewModel.setDisplayMode(VerseTextDisplayMode.uthmanic),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _viewModel.displayMode ==
                VerseTextDisplayMode.plainWithTashkil,
            label: const Text('Plain (Tashkīl)'),
            onSelected: (_) => _viewModel
                .setDisplayMode(VerseTextDisplayMode.plainWithTashkil),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _viewModel.displayMode ==
                VerseTextDisplayMode.plainWithoutTashkil,
            label: const Text('Plain'),
            onSelected: (_) => _viewModel
                .setDisplayMode(VerseTextDisplayMode.plainWithoutTashkil),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content Router
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    // Loading state with progress indicator
    if (_viewModel.isLoading) {
      return _buildLoadingView(context);
    }

    // Error state
    if (_viewModel.error != null) {
      return _buildErrorView(context);
    }

    // Empty state (shouldn't happen, but safety-first)
    if (_viewModel.verses.isEmpty) {
      return _buildEmptyView(context);
    }

    // Verse list
    return _buildVerseList(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: _viewModel.loadProgress),
          const SizedBox(height: 16),
          Text(
            'Loading verses… ${(_viewModel.loadProgress * 100).toInt()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_viewModel.totalVerses} verses loaded',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Error',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _viewModel.error ?? '',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _viewModel.clearError,
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _viewModel.loadAllVerses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No verses available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Verse List (lazy – uses ListView.builder for 6 236 items)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVerseList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${_viewModel.totalVerses} verses',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // The list itself
        Expanded(
          child: ListView.builder(
            itemCount: _viewModel.verses.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = _viewModel.verses[index];

              // Show a chapter-header divider when we enter a new chapter.
              final isNewChapter = index == 0 ||
                  _viewModel.verses[index - 1].chapter.number !=
                      item.chapter.number;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isNewChapter)
                    _ChapterHeader(
                      chapter: item.chapter,
                      multiplier: _viewModel.fontSizeMultiplier,
                    ),
                  _VerseCard(
                    verseWithChapter: item,
                    displayText: _viewModel.getDisplayText(item.verse),
                    multiplier: _viewModel.fontSizeMultiplier,
                    onTap: () => widget.onVerseSelected
                        ?.call(item.verse.pageNumber),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Private helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Sticky-looking chapter header shown before the first verse of each surah.
class _ChapterHeader extends StatelessWidget {
  final Chapter chapter;
  final double multiplier;

  const _ChapterHeader({required this.chapter, required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 18,
            child: Text(
              '${chapter.number}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
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
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) * multiplier,
                  ),
                ),
                Text(
                  '${chapter.englishTitle} · ${chapter.versesCount} verses',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single verse card — displays number badge, text, and page number.
class _VerseCard extends StatelessWidget {
  final VerseWithChapter verseWithChapter;
  final String displayText;
  final double multiplier;
  final VoidCallback? onTap;

  const _VerseCard({
    required this.verseWithChapter,
    required this.displayText,
    required this.multiplier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verse = verseWithChapter.verse;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: verse number + page badge
              Row(
                children: [
                  // Verse number badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      QuranDataProvider.toArabicNumerals(verse.number),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Page ${verse.pageNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Verse text
              Text(
                displayText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18 * multiplier,
                  height: 1.9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
