import 'package:flutter/material.dart';

import '../../domain/models/verse.dart';
import '../mushaf/verse_fasel.dart';
import 'verses_list_view_model.dart';

/// A lightweight StatelessWidget that renders a single verse inside a list.
///
/// Displays [VerseFasel] with the verse number in all modes, and renders
/// the appropriate text content based on [displayMode].
class VerseTile extends StatelessWidget {
  final Verse verse;
  final DisplayMode displayMode;

  /// When true, verse numbers are displayed as Arabic-Indic Unicode (٠١٢٣...).
  /// When false (default), uses the QuranNumbers.ttf font with Western digits.
  final bool useArabicNumerals;

  const VerseTile({
    super.key,
    required this.verse,
    required this.displayMode,
    this.useArabicNumerals = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerseFasel(number: verse.number, useArabicNumerals: useArabicNumerals),
          const SizedBox(width: 8),
          Expanded(child: _buildTextContent()),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    switch (displayMode) {
      case DisplayMode.plain:
        return Text(
          verse.text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        );
      case DisplayMode.tajweed:
        return Text(
          verse.uthmanicHafsText,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        );
      case DisplayMode.translation:
        return _buildTranslationText();
      case DisplayMode.both:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              verse.uthmanicHafsText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            _buildTranslationText(),
          ],
        );
    }
  }

  Widget _buildTranslationText() {
    // Translation is not yet available in the Verse model.
    // Display a placeholder until the field is added.
    return const Text(
      '[Translation not available]',
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
  }
}
