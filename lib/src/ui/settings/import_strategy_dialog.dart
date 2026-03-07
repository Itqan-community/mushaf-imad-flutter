import 'package:flutter/material.dart';

enum ImportStrategy { merge, replace }

class ImportStrategyDialog extends StatelessWidget {
  const ImportStrategyDialog({super.key});

  static Future<ImportStrategy?> show(BuildContext context) {
    return showDialog<ImportStrategy>(
      context: context,
      builder: (_) => const ImportStrategyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.import_export_rounded, size: 36),
      title: const Text('Import Strategy'),
      content: const Text(
        'How would you like to handle the imported data?\n\n'
        'Merge: Add imported items alongside your existing data.\n\n'
        'Replace: Clear all existing data and replace with the imported data.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, ImportStrategy.replace),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text('Replace'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ImportStrategy.merge),
          child: const Text('Merge'),
        ),
      ],
    );
  }
}
