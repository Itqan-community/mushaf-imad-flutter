import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../di/core_module.dart';
import '../../domain/models/advanced_search.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/search_history.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../domain/repository/verse_repository.dart';
import 'search_view_model.dart';

/// Full search page with unified verse/chapter/bookmark search.
///
/// Matches Android's `SearchView.kt` — FilterChips for type selection,
/// search history, results grouped by type, error and empty states.
/// Extended with advanced search filters (match mode + Arabic options).
class SearchPage extends StatefulWidget {
  /// Called when user taps a verse result.
  final void Function(int pageNumber)? onVerseSelected;

  /// Called when user taps a chapter result.
  final void Function(int pageNumber)? onChapterSelected;

  const SearchPage({super.key, this.onVerseSelected, this.onChapterSelected});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchViewModel _viewModel;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _viewModel = SearchViewModel(
      verseRepository: mushafGetIt<VerseRepository>(),
      chapterRepository: mushafGetIt<ChapterRepository>(),
      bookmarkRepository: mushafGetIt<BookmarkRepository>(),
      searchHistoryRepository: mushafGetIt<SearchHistoryRepository>(),
    );
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _viewModel.search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearResults();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Column(
          children: [
            _buildSearchBar(context),
            _buildFilterChips(context),
            if (_viewModel.hasActiveAdvancedFilters)
              _buildActiveAdvancedChips(context),
            Expanded(child: _buildContent(context)),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'Search verses or chapters...',
          hintTextDirection: TextDirection.ltr,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _viewModel.hasActiveAdvancedFilters
                      ? theme.colorScheme.primary
                      : null,
                ),
                tooltip: 'Advanced filters',
                onPressed: () => _showAdvancedFiltersSheet(context),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearSearch,
                ),
            ],
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() {}),
        onSubmitted: _performSearch,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter Chips (matches Android SearchFilters)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _viewModel.searchType == SearchType.general,
            label: const Text('All'),
            onSelected: (_) => _viewModel.setSearchType(SearchType.general),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _viewModel.searchType == SearchType.verse,
            label: const Text('Verses'),
            onSelected: (_) => _viewModel.setSearchType(SearchType.verse),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _viewModel.searchType == SearchType.chapter,
            label: const Text('Chapters'),
            onSelected: (_) => _viewModel.setSearchType(SearchType.chapter),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Active Advanced Filters Chips
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActiveAdvancedChips(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (_viewModel.matchMode != TextMatchMode.contains) {
      chips.add(
        InputChip(
          label: Text(_matchModeLabel(_viewModel.matchMode)),
          avatar: Icon(
            _matchModeIcon(_viewModel.matchMode),
            size: 16,
          ),
          onDeleted: () => _viewModel.setMatchMode(TextMatchMode.contains),
          backgroundColor: theme.colorScheme.primaryContainer,
          deleteIconColor: theme.colorScheme.onPrimaryContainer,
          labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      );
    }

    final opts = _viewModel.arabicOptions;
    if (!opts.ignoreDiacritics) {
      chips.add(
        InputChip(
          label: const Text('Diacritics on'),
          onDeleted: () => _viewModel.setArabicOptions(
            opts.copyWith(ignoreDiacritics: true),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    }
    if (!opts.normalizeLetters) {
      chips.add(
        InputChip(
          label: const Text('No normalization'),
          onDeleted: () => _viewModel.setArabicOptions(
            opts.copyWith(normalizeLetters: true),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    }
    if (!opts.stripTatweelAndPunct) {
      chips.add(
        InputChip(
          label: const Text('Keep tatweel'),
          onDeleted: () => _viewModel.setArabicOptions(
            opts.copyWith(stripTatweelAndPunct: true),
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Advanced Filters Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showAdvancedFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AdvancedFiltersSheet(viewModel: _viewModel),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Content Router (matches Android SearchView when/else blocks)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_viewModel.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_viewModel.error != null) {
      return _buildErrorView(context);
    }

    if (_viewModel.hasSearched && _viewModel.totalResults == 0) {
      return _buildEmptyResultsView(context);
    }

    if (_viewModel.hasSearched) {
      return _buildSearchResults(context);
    }

    return _buildPreSearchContent(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error View (matching Android ErrorView)
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
              FilledButton(
                onPressed: _viewModel.clearError,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty Results View (matching Android EmptyResultsView)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyResultsView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pre-Search Content (matching Android SearchHistoryView)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPreSearchContent(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_viewModel.recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: _viewModel.clearHistory,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          ..._viewModel.recentSearches
              .take(10)
              .map(
                (entry) => _RecentSearchTile(
                  entry: entry,
                  onTap: () {
                    _searchController.text = entry.query;
                    _performSearch(entry.query);
                  },
                ),
              ),
        ],

        if (_viewModel.suggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              'Popular Searches',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _viewModel.suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion.query),
                onPressed: () {
                  _searchController.text = suggestion.query;
                  _performSearch(suggestion.query);
                },
              );
            }).toList(),
          ),
        ],

        if (_viewModel.recentSearches.isEmpty && _viewModel.suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search the Quran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search by verse text, chapter name, or bookmark',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search Results (matching Android SearchResults)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final hasVerses = _viewModel.verseResults.isNotEmpty;
    final hasChapters = _viewModel.chapterResults.isNotEmpty;
    final hasBookmarks = _viewModel.bookmarkResults.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (hasChapters) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Chapters (${_viewModel.chapterResults.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._viewModel.chapterResults.map(
            (chapter) => _ChapterResultTile(
              chapter: chapter,
              onTap: () {
                final page = QuranDataProvider.instance.getPageForChapter(
                  chapter.number,
                );
                widget.onChapterSelected?.call(page);
              },
            ),
          ),
          if (hasVerses || hasBookmarks) const SizedBox(height: 16),
        ],

        if (hasVerses) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Verses (${_viewModel.verseResults.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._viewModel.verseResults.map(
            (verse) => _VerseResultTile(
              verse: verse,
              onTap: () => widget.onVerseSelected?.call(verse.pageNumber),
            ),
          ),
          if (hasBookmarks) const SizedBox(height: 16),
        ],

        if (hasBookmarks) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Bookmarks (${_viewModel.bookmarkResults.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._viewModel.bookmarkResults.map(
            (bookmark) => _BookmarkResultTile(
              bookmark: bookmark,
              onTap: () => widget.onVerseSelected?.call(bookmark.pageNumber),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced Filters Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancedFiltersSheet extends StatefulWidget {
  final SearchViewModel viewModel;

  const _AdvancedFiltersSheet({required this.viewModel});

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  late TextMatchMode _mode;
  late bool _ignoreDiacritics;
  late bool _normalizeLetters;
  late bool _stripTatweel;

  @override
  void initState() {
    super.initState();
    _mode = widget.viewModel.matchMode;
    _ignoreDiacritics = widget.viewModel.arabicOptions.ignoreDiacritics;
    _normalizeLetters = widget.viewModel.arabicOptions.normalizeLetters;
    _stripTatweel = widget.viewModel.arabicOptions.stripTatweelAndPunct;
  }

  void _apply() {
    widget.viewModel.setMatchMode(_mode);
    widget.viewModel.setArabicOptions(
      ArabicSearchOptions(
        ignoreDiacritics: _ignoreDiacritics,
        normalizeLetters: _normalizeLetters,
        stripTatweelAndPunct: _stripTatweel,
      ),
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _mode = TextMatchMode.contains;
      _ignoreDiacritics = true;
      _normalizeLetters = true;
      _stripTatweel = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advanced Search',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 20),

              // Match Mode
              Text(
                'Match Mode',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TextMatchMode.values.map((mode) {
                  return ChoiceChip(
                    selected: _mode == mode,
                    label: Text(_matchModeLabel(mode)),
                    avatar: _mode == mode
                        ? null
                        : Icon(_matchModeIcon(mode), size: 18),
                    onSelected: (_) => setState(() => _mode = mode),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Arabic Processing
              Text(
                'Arabic Processing',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ignore diacritics (tashkil)'),
                subtitle: const Text(
                  'Match text regardless of harakat',
                ),
                value: _ignoreDiacritics,
                onChanged: (v) => setState(() => _ignoreDiacritics = v),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Normalize letter variants'),
                subtitle: const Text(
                  'Treat أ/إ/آ as ا, ى as ي, ة as ه, etc.',
                ),
                value: _normalizeLetters,
                onChanged: (v) => setState(() => _normalizeLetters = v),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Strip tatweel & punctuation'),
                subtitle: const Text(
                  'Remove kashida and Arabic punctuation marks',
                ),
                value: _stripTatweel,
                onChanged: (v) => setState(() => _stripTatweel = v),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _matchModeLabel(TextMatchMode mode) {
  return switch (mode) {
    TextMatchMode.contains => 'Contains',
    TextMatchMode.exact => 'Exact',
    TextMatchMode.prefix => 'Prefix',
    TextMatchMode.root => 'Root',
    TextMatchMode.lemma => 'Lemma',
  };
}

IconData _matchModeIcon(TextMatchMode mode) {
  return switch (mode) {
    TextMatchMode.contains => Icons.text_fields_rounded,
    TextMatchMode.exact => Icons.format_quote_rounded,
    TextMatchMode.prefix => Icons.start_rounded,
    TextMatchMode.root => Icons.account_tree_rounded,
    TextMatchMode.lemma => Icons.auto_stories_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Search Tile
// ─────────────────────────────────────────────────────────────────────────────

class _RecentSearchTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;

  const _RecentSearchTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history_rounded, size: 20),
      title: Text(entry.query, textDirection: TextDirection.rtl),
      trailing: Text(
        '${entry.resultCount} results',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter Result Tile (matching Android ChapterResultItem)
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterResultTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onTap;

  const _ChapterResultTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          radius: 20,
          child: Text(
            '${chapter.number}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        title: Text(
          chapter.arabicTitle,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${chapter.englishTitle} · ${chapter.versesCount} verses · ${chapter.isMeccan ? "Meccan" : "Medinan"}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verse Result Tile (matching Android VerseResultItem)
// ─────────────────────────────────────────────────────────────────────────────

class _VerseResultTile extends StatelessWidget {
  final Verse verse;
  final VoidCallback onTap;

  const _VerseResultTile({required this.verse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapterData = QuranDataProvider.instance.getChapter(
      verse.chapterNumber,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${chapterData.arabicTitle} ${verse.chapterNumber}:${verse.number}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Page ${verse.pageNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                verse.text.isNotEmpty ? verse.text : verse.textWithoutTashkil,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  height: 1.8,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bookmark Result Tile
// ─────────────────────────────────────────────────────────────────────────────

class _BookmarkResultTile extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;

  const _BookmarkResultTile({required this.bookmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapterData = QuranDataProvider.instance.getChapter(
      bookmark.chapterNumber,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(Icons.bookmark_rounded, color: theme.colorScheme.primary),
        title: Text(
          '${chapterData.arabicTitle} ${bookmark.chapterNumber}:${bookmark.verseNumber}',
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page ${bookmark.pageNumber}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (bookmark.note.isNotEmpty)
              Text(
                bookmark.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
