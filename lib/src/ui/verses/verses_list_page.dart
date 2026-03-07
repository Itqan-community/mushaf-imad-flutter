import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import 'verses_list_view_model.dart';

class VersesListPage extends StatefulWidget {
  final ValueChanged<int>? onVerseSelected;

  const VersesListPage({super.key, this.onVerseSelected});

  @override
  State<VersesListPage> createState() => _VersesListPageState();
}

class _VersesListPageState extends State<VersesListPage> {
  late final VersesListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VersesListViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verses'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildModeSelector(theme),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _viewModel.allVerses.length,
                  itemBuilder: (context, index) {
                    final verse = _viewModel.allVerses[index];
                    final verseText = _viewModel.getVerseText(verse);

                    return InkWell(
                      onTap: widget.onVerseSelected != null
                          ? () => widget.onVerseSelected!(verse.verseID)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${verse.chapter}:${verse.number}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  QuranDataProvider.toArabicNumerals(verse.chapter) +
                                      ':' +
                                      QuranDataProvider.toArabicNumerals(verse.number),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              verseText.isEmpty ? '—' : verseText,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                fontFamily: _viewModel.displayMode ==
                                        TextDisplayMode.uthmanic
                                    ? 'serif'
                                    : null,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Divider(
                              height: 1,
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<TextDisplayMode>(
        segments: const [
          ButtonSegment(
            value: TextDisplayMode.uthmanic,
            label: Text('Uthmanic'),
            icon: Icon(Icons.auto_stories, size: 18),
          ),
          ButtonSegment(
            value: TextDisplayMode.plainWithTashkil,
            label: Text('Tashkil'),
            icon: Icon(Icons.text_fields, size: 18),
          ),
          ButtonSegment(
            value: TextDisplayMode.plainWithoutTashkil,
            label: Text('Plain'),
            icon: Icon(Icons.text_snippet, size: 18),
          ),
        ],
        selected: {_viewModel.displayMode},
        onSelectionChanged: (modes) => _viewModel.setDisplayMode(modes.first),
      ),
    );
  }
}
