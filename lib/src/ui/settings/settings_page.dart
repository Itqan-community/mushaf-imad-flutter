import 'package:flutter/material.dart';

import '../../di/core_module.dart';
import '../../domain/models/line_compactness.dart';
import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/preferences_repository.dart';
import '../theme/theme_picker_widget.dart';
import 'settings_view_model.dart';

/// Unified settings page combining theme, preferences, and data management.
///
/// Uses [SettingsViewModel] and embeds [ThemePickerWidget].
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(
      preferencesRepository: mushafGetIt<PreferencesRepository>(),
      dataExportRepository: mushafGetIt<DataExportRepository>(),
    );
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
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Appearance Section ───
              _SectionTitle(title: 'Appearance', icon: Icons.palette_rounded),
              const SizedBox(height: 8),
              const ThemePickerWidget(),
              const SizedBox(height: 24),

              // ─── Preferences Section ───
              _SectionTitle(title: 'Preferences', icon: Icons.tune_rounded),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    _PreferenceTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Mushaf Type',
                      value: _viewModel.mushafType.name.toUpperCase(),
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Current Page',
                      value: '${_viewModel.currentPage}',
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.mic_rounded,
                      label: 'Selected Recitation',
                      value: 'Recitation #${_viewModel.selectedRecitationId}',
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.speed_rounded,
                      label: 'Playback Speed',
                      value: '${_viewModel.playbackSpeed}x',
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.repeat_rounded,
                      label: 'Repeat Mode',
                      value: _viewModel.repeatMode ? 'On' : 'Off',
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.brightness_6_rounded,
                      label: 'Theme Mode',
                      value: _viewModel.themeConfig.mode.name,
                    ),
                    const Divider(height: 1, indent: 56),
                    _PreferenceTile(
                      icon: Icons.format_line_spacing_rounded,
                      label: 'Line Compactness',
                      value: _viewModel.lineCompactness.displayName,
                      onTap: () => _selectCompactness(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Data Management Section ───
              _SectionTitle(
                title: 'Data Management',
                icon: Icons.storage_rounded,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_rounded),
                      title: const Text('Export Data'),
                      subtitle: const Text(
                        'Export bookmarks, history & preferences',
                      ),
                      trailing: _viewModel.isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                      onTap: _viewModel.isExporting
                          ? null
                          : () => _handleExport(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: const Text('Import Data'),
                      subtitle: const Text(
                        'Import from a previously exported file',
                      ),
                      trailing: _viewModel.isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                      onTap: _viewModel.isImporting
                          ? null
                          : () => _handleImport(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Clear All Data',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text(
                        'Remove all bookmarks, history & settings',
                      ),
                      onTap: () => _confirmClearData(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── About Section ───
              _SectionTitle(title: 'About', icon: Icons.info_outline_rounded),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.menu_book_rounded),
                      title: Text('MushafImad Library'),
                      subtitle: Text('Quran reader library for Flutter'),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.code_rounded),
                      title: const Text('Version'),
                      trailing: Text(
                        '0.0.1',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final outputPath = await _viewModel.exportData();
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: $outputPath'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste exported JSON data here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty || !mounted) return;

    try {
      final importResult = await _viewModel.importData(result);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported: ${importResult.bookmarksImported} bookmarks, '
            '${importResult.searchHistoryImported} search history entries',
          ),
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _confirmClearData(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 36,
        ),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your bookmarks, reading history, '
          'and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              _viewModel.clearAllData();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data cleared')));
            },
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  void _selectCompactness(BuildContext context) {
    var selectedFactor = _viewModel.lineCompactness.factor;
    var isExpanded = _viewModel.lineCompactness.isExpanded;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final overlapPct = isExpanded
                ? 0
                : ((1.0 - selectedFactor) * 100).round().clamp(0, 80);
            final spacingPct = (selectedFactor * 100).round();

            return AlertDialog(
              title: const Text('Line Compactness'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isExpanded
                                ? 'Expanded (full page stretch)'
                                : 'Spacing: $spacingPct%  |  Overlap: $overlapPct%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isExpanded
                                ? 'Lines stretch equally to fill viewport height.'
                                : overlapPct > 0
                                    ? 'Adjacent line pictures overlap by $overlapPct% to reduce margins.'
                                    : 'Lines touch edge-to-edge without overlapping pictures.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Compactness Scale',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: selectedFactor.clamp(0.30, 1.10),
                      min: 0.30,
                      max: 1.10,
                      divisions: 16,
                      label: '$spacingPct%',
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFactor = double.parse(val.toStringAsFixed(2));
                          isExpanded = false;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'More Compact\n(30% / 70% overlap)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Loose\n(110% / 0% overlap)',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Presets',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in LineCompactness.values)
                          ChoiceChip(
                            label: Text(
                              preset.isExpanded
                                  ? 'Expanded'
                                  : '${preset.name} (${(preset.factor * 100).toInt()}%)',
                            ),
                            selected: preset.isExpanded
                                ? isExpanded
                                : (!isExpanded &&
                                    (selectedFactor - preset.factor).abs() <
                                        0.01),
                            onSelected: (_) {
                              setDialogState(() {
                                if (preset.isExpanded) {
                                  isExpanded = true;
                                } else {
                                  isExpanded = false;
                                  selectedFactor = preset.factor;
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final chosen = isExpanded
                        ? LineCompactness.expanded
                        : LineCompactness(selectedFactor);
                    _viewModel.setLineCompactness(chosen);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preference Tile
// ─────────────────────────────────────────────────────────────────────────────

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}
