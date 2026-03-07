import 'package:flutter/material.dart';

/// The strategy chosen by the user for importing data.
enum ImportStrategy {
  /// Merge imported data with existing user data.
  merge,

  /// Replace all existing user data with the imported data.
  replace,
}

/// A standalone AlertDialog that asks the user whether they want to
/// **Merge** or **Replace** their data during a JSON import.
///
/// Returns an [ImportStrategy] or `null` if the user cancels.
///
/// ## Usage
/// ```dart
/// final strategy = await ImportStrategyDialog.show(context);
/// if (strategy == null) return; // user cancelled
///
/// await viewModel.importData(jsonData,
///     mergeWithExisting: strategy == ImportStrategy.merge);
/// ```
class ImportStrategyDialog extends StatelessWidget {
  const ImportStrategyDialog({super.key});

  /// Show the dialog and return the chosen [ImportStrategy], or `null`
  /// if the dialog is dismissed.
  static Future<ImportStrategy?> show(BuildContext context) {
    return showDialog<ImportStrategy>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ImportStrategyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.file_download_outlined,
        size: 40,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Import Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How would you like to handle the imported data?',
          ),
          const SizedBox(height: 16),
          // Merge option
          _StrategyOption(
            icon: Icons.merge_rounded,
            title: 'Merge',
            description:
                'Add imported bookmarks and history alongside your '
                'existing data. No data will be lost.',
            color: theme.colorScheme.primary,
            onTap: () => Navigator.of(context).pop(ImportStrategy.merge),
          ),
          const SizedBox(height: 12),
          // Replace option
          _StrategyOption(
            icon: Icons.swap_horiz_rounded,
            title: 'Replace',
            description:
                'Delete all your current data and replace it with '
                'the imported file. This cannot be undone.',
            color: theme.colorScheme.error,
            onTap: () => Navigator.of(context).pop(ImportStrategy.replace),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// A selectable option card inside the [ImportStrategyDialog].
class _StrategyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _StrategyOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
