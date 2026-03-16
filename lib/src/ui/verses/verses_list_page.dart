import 'package:flutter/material.dart';

import '../../di/core_module.dart';
import '../../domain/repository/verse_repository.dart';
import 'verse_tile.dart';
import 'verses_list_view_model.dart';

/// A page that displays all verses for a given chapter in a scrollable list.
///
/// Creates [VersesListViewModel] internally using [mushafGetIt] — no manual
/// dependency injection required from the consumer.
///
/// Supports four [DisplayMode]s and sets RTL as the page-level text direction.
class VersesListPage extends StatefulWidget {
  final int chapterNumber;

  /// When true, verse numbers are displayed as Arabic-Indic Unicode (٠١٢٣...).
  /// When false (default), uses the QuranNumbers.ttf font with Western digits.
  final bool useArabicNumerals;

  const VersesListPage({
    super.key,
    required this.chapterNumber,
    this.useArabicNumerals = false,
  });

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
      chapterNumber: widget.chapterNumber,
    );
    _viewModel.loadVerses();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('السورة ${widget.chapterNumber}'),
          actions: [_DisplayModeButton(viewModel: _viewModel)],
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_viewModel.verses.isEmpty) {
      return const Center(child: Text('لا توجد آيات'));
    }

    final sorted = [..._viewModel.verses]
      ..sort((a, b) => a.number.compareTo(b.number));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) => VerseTile(
        verse: sorted[index],
        displayMode: _viewModel.displayMode,
        useArabicNumerals: widget.useArabicNumerals,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _viewModel.loadVerses,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DisplayMode control button
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayModeButton extends StatelessWidget {
  final VersesListViewModel viewModel;

  const _DisplayModeButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DisplayMode>(
      icon: const Icon(Icons.text_fields_rounded),
      tooltip: 'نمط العرض',
      initialValue: viewModel.displayMode,
      onSelected: viewModel.setDisplayMode,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: DisplayMode.plain,
          child: Text('نص عادي'),
        ),
        PopupMenuItem(
          value: DisplayMode.tajweed,
          child: Text('تجويد'),
        ),
        PopupMenuItem(
          value: DisplayMode.translation,
          child: Text('ترجمة'),
        ),
        PopupMenuItem(
          value: DisplayMode.both,
          child: Text('نص + ترجمة'),
        ),
      ],
    );
  }
}
