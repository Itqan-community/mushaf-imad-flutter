import 'package:flutter/material.dart';

import '../../data/audio/reciter_data_provider.dart';
import '../../di/core_module.dart';
import '../../domain/models/mushaf_type.dart';
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
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: const Text('Mushaf Type'),
                      subtitle: Text(_getMushafTypeDescription(_viewModel.mushafType)),
                      trailing: DropdownButton<MushafType>(
                        value: _viewModel.mushafType,
                        underline: const SizedBox.shrink(),
                        items: MushafType.values.map((type) {
                          return DropdownMenuItem<MushafType>(
                            value: type,
                            child: Text(
                              _getMushafTypeLabel(type),
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (type) {
                          if (type != null) {
                            _viewModel.setMushafType(type);
                          }
                        },
                      ),
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
                      label: 'Selected Reciter',
                      value: _reciterName(_viewModel.selectedReciterId),
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

  String _reciterName(int reciterId) {
    try {
      final reciter = ReciterDataProvider.allReciters.firstWhere(
        (r) => r.id == reciterId,
      );
      return reciter.nameEnglish;
    } catch (_) {
      return 'Reciter #$reciterId';
    }
  }

  String _getMushafTypeLabel(MushafType type) {
    return switch (type) {
      MushafType.hafs1441 => 'Hafs 1441',
      MushafType.hafs1405 => 'Hafs 1405',
      MushafType.hafs1421 => 'Hafs 1421',
    };
  }

  String _getMushafTypeDescription(MushafType type) {
    return switch (type) {
      MushafType.hafs1441 => 'Modern Madani Mushaf (15-line)',
      MushafType.hafs1405 => 'Traditional Madani Mushaf',
      MushafType.hafs1421 => 'Madani Mushaf 1421 Edition',
    };
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final json = await _viewModel.exportData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported (${json.length} characters)'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported: ${importResult.bookmarksImported} bookmarks, '
            '${importResult.searchHistoryImported} search history entries',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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

  const _PreferenceTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
