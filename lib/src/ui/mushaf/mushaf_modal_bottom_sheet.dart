import 'package:flutter/material.dart';

/// generic component for all use cases of bottom sheet in the mushaf.
class MushafModalBottomSheet extends StatelessWidget {
  const MushafModalBottomSheet({
    super.key,
    this.title,
    this.showDragHandle = true,
    this.centerTitle = false,
    this.body = const SizedBox(),
    this.footer,
  });

  final Widget? title;
  final bool showDragHandle;
  final Widget body;
  final Widget? footer;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: colors.outlineVariant,
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (title == null) const Expanded(child: SizedBox()),
              if (centerTitle && title != null) Expanded(child: SizedBox()),
              if (title != null)
                Flexible(
                  child: DefaultTextStyle(
                    style: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    child: title!,
                  ),
                ),
              if (centerTitle && title != null) Expanded(child: SizedBox()),
            ],
          ),
        ),
        if (title != null) Divider(height: 1, color: colors.outlineVariant),
        body,
        if (footer != null)
          Column(
            children: [
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: footer!,
              ),
            ],
          ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
      ],
    );
  }
}

/// A generic option item for use inside [MushafModalBottomSheet] body.
class BottomSheetOption extends StatelessWidget {
  const BottomSheetOption({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
    this.isDestructive = false,
  });

  final String label;
  final IconData? icon;
  final Widget? trailing;
  final void Function() onTap;
  final bool isDestructive;
  final bool autoDismiss = true;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(label, style: TextStyle(color: color)),
      trailing: trailing,
      onTap: () {
        onTap();
        if (autoDismiss) Navigator.of(context).pop();
      },
    );
  }
}
