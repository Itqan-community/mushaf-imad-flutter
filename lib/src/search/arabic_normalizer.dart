import '../domain/models/advanced_search.dart';

/// Arabic text normalizer for search preprocessing.
///
/// Applies configurable transformations: diacritics removal,
/// letter variant normalization, and tatweel/punctuation stripping.
class ArabicNormalizer {
  ArabicNormalizer._();

  /// Arabic diacritics (tashkil) Unicode ranges.
  static final _diacriticsRegex = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]',
  );

  /// Tatweel / kashida character.
  static final _tatweelRegex = RegExp(r'\u0640');

  /// Arabic punctuation and common non-letter marks.
  static final _arabicPunctRegex = RegExp(
    r'[\u060C\u060D\u061B\u061E\u061F\u066A-\u066D\u06D4\uFD3E\uFD3F]',
  );

  /// Consecutive whitespace.
  static final _whitespaceRegex = RegExp(r'\s+');

  /// Alif variants: أ إ آ ٱ → ا
  static final _alifVariants = RegExp(r'[أإآٱ]');

  /// Normalize text according to the given [options].
  static String normalize(String text, ArabicSearchOptions options) {
    var result = text;

    if (options.ignoreDiacritics) {
      result = result.replaceAll(_diacriticsRegex, '');
    }

    if (options.normalizeLetters) {
      result = result.replaceAll(_alifVariants, 'ا');
      result = result.replaceAll('ى', 'ي');
      result = result.replaceAll('ة', 'ه');
      result = result.replaceAll('ؤ', 'و');
      result = result.replaceAll('ئ', 'ي');
    }

    if (options.stripTatweelAndPunct) {
      result = result.replaceAll(_tatweelRegex, '');
      result = result.replaceAll(_arabicPunctRegex, '');
      result = result.replaceAll(_whitespaceRegex, ' ');
    }

    return result.trim();
  }

  /// Strip only diacritics (convenience for index generation).
  static String stripDiacritics(String text) {
    return text.replaceAll(_diacriticsRegex, '');
  }

  /// Full normalization with all defaults enabled.
  static String normalizeAll(String text) {
    return normalize(text, const ArabicSearchOptions());
  }
}
