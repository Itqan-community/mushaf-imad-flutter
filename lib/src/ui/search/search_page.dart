import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../di/core_module.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/search_history.dart';
import '../../domain/models/verse.dart';
import '../../domain/repository/bookmark_repository.dart';
import '../../domain/repository/chapter_repository.dart';
import '../../domain/repository/search_history_repository.dart';
import '../../domain/repository/verse_repository.dart';
import '../../services/advanced_search_service.dart';
import 'search_view_model.dart';

/// Full search page with unified verse/chapter/bookmark search.
///
/// Features:
/// - Autocomplete suggestions with Arabic support
/// - Debounced search (300ms)
/// - Arabic text normalization
/// - Support for surah:ayah syntax (e.g., "2:255" for Ayat Al-Kursi)
/// - Filter chips for type selection
/// - Search history
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
  bool _showAutocomplete = false;

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
    
    _searchFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showAutocomplete = _searchFocus.hasFocus && _searchController.text.length >= 2;
    });
  }

  void _performSearch(String query) {
    _viewModel.search(query, debounce: false);
    setState(() => _showAutocomplete = false);
    _searchFocus.unfocus();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _showAutocomplete = value.length >= 2;
    });
    _viewModel.updateAutocomplete(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.clearResults();
    _viewModel.clearAutocomplete();
    setState(() => _showAutocomplete = false);
    _searchFocus.requestFocus();
  }

  void _onSuggestionSelected(String text) {
    _searchController.text = text;
    _performSearch(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Search bar
                _buildSearchBar(context),

                // Filter chips
                _buildFilterChips(context),

                // Content
                Expanded(child: _buildContent(context)),
              ],
            ),
            
            // Autocomplete overlay
            if (_showAutocomplete)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: _buildAutocompletePanel(context),
              ),
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
          hintText: 'Search verses, chapters, or use "2:255" format...',
          hintTextDirection: TextDirection.ltr,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: _clearSearch,
                )
              : null,
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
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Autocomplete Panel
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAutocompletePanel(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _viewModel.autocompleteSuggestions;

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _buildSuggestionTile(context, suggestion);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, AutocompleteSuggestion suggestion) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color? iconColor;
    
    switch (suggestion.type) {
      case AutocompleteSuggestionType.chapter:
        icon = Icons.menu_book_rounded;
        iconColor = theme.colorScheme.primary;
        break;
      case AutocompleteSuggestionType.verse:
        icon = Icons.format_quote_rounded;
        iconColor = theme.colorScheme.secondary;
        break;
      case AutocompleteSuggestionType.bookmark:
        icon = Icons.bookmark_rounded;
        iconColor = Colors.amber;
        break;
      case AutocompleteSuggestionType.recentSearch:
        icon = Icons.history_rounded;
        iconColor = theme.colorScheme.onSurfaceVariant;
        break;
      case AutocompleteSuggestionType.suggestion:
        icon = Icons.search_rounded;
        iconColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        suggestion.text,
        textDirection: TextDirection.rtl,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: suggestion.secondaryText != null
          ? Text(
              suggestion.secondaryText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: () => _onSuggestionSelected(suggestion.text),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter Chips
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
  // Content Router
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    // Loading state
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

    // Error state
    if (_viewModel.error != null) {
      return _buildErrorView(context);
    }

    // Empty results after search
    if (_viewModel.hasSearched && _viewModel.totalResults == 0) {
      return _buildEmptyResultsView(context);
    }

    // Search results
    if (_viewModel.hasSearched) {
      return _buildSearchResults(context);
    }

    // Initial state — search history
    return _buildPreSearchContent(context);
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
  // Empty Results View
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
            'Try different keywords or use "2:255" format',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.text = '2:255';
              _performSearch('2:255');
            },
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Try: 2:255 (Ayat Al-Kursi)'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pre-Search Content
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPreSearchContent(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Search tips
        _buildSearchTips(context),
        
        const SizedBox(height: 16),
        
        // Recent Searches
        if (_viewModel.recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
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
                  onTap: () => _onSuggestionSelected(entry.query),
                ),
              ),
        ],

        // Popular suggestions
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
                onPressed: () => _onSuggestionSelected(suggestion.query),
              );
            }).toList(),
          ),
        ],

        // Empty initial state
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
  // Search Tips
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchTips(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, 
                  size: 18, 
                  color: theme.colorScheme.primary
                ),
                const SizedBox(width: 8),
                Text(
                  'Search Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTip(context, '2:255', 'Find Ayat Al-Kursi'),
            _buildTip(context, 'Al-Fatiha', 'Find by chapter name'),
            _buildTip(context, 'الفاتحة', 'Search in Arabic'),
            _buildTip(context, 'الرحمن', 'Search verse text'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String example, String description) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _onSuggestionSelected(example),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                example,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search Results
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    final hasVerses = _viewModel.verseResults.isNotEmpty;
    final hasChapters = _viewModel.chapterResults.isNotEmpty;
    final hasBookmarks = _viewModel.bookmarkResults.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Results summary
        if (_viewModel.query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'Found ${_viewModel.totalResults} results for "${_viewModel.query}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // Chapter results section
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

        // Verse results section
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

        // Bookmark results section
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
// Chapter Result Tile
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
// Verse Result Tile
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
              // Verse reference row
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
              // Verse text
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
