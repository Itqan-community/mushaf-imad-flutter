/// Utility class for Arabic text normalization and search operations.
/// Helps with searching Arabic text by normalizing different forms of Arabic characters.
class ArabicNormalizer {
  // Private constructor to prevent instantiation
  ArabicNormalizer._();

  /// Normalizes Arabic text by:
  /// - Removing tashkeel (diacritics)
  /// - Standardizing alef variations (أ, إ, آ, ٱ → ا)
  /// - Standardizing ta marbuta (ة → ه)
  /// - Standardizing alef maksura (ى → ي)
  /// - Removing tatweel (ـ)
  /// - Converting to lowercase for English letters
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var normalized = text;

    // Remove tashkeel (diacritical marks)
    normalized = _removeTashkeel(normalized);

    // Normalize alef variations
    normalized = _normalizeAlefs(normalized);

    // Normalize ta marbuta
    normalized = _normalizeTaMarbuta(normalized);

    // Normalize alef maksura
    normalized = _normalizeAlefMaksura(normalized);

    // Remove tatweel (elongation character)
    normalized = normalized.replaceAll('ـ', '');

    // Convert to lowercase
    normalized = normalized.toLowerCase();

    // Trim whitespace
    normalized = normalized.trim();

    return normalized;
  }

  /// Removes all Arabic tashkeel (diacritical marks)
  static String _removeTashkeel(String text) {
    const tashkeel = [
      '\u064B', // Fathatan
      '\u064C', // Dammatan
      '\u064D', // Kasratan
      '\u064E', // Fatha
      '\u064F', // Damma
      '\u0650', // Kasra
      '\u0651', // Shadda
      '\u0652', // Sukun
      '\u0653', // Maddah
      '\u0654', // Hamza above
      '\u0655', // Hamza below
      '\u0670', // Superscript alef
      '\u0640', // Tatweel (also handled separately)
    ];

    var result = text;
    for (final mark in tashkeel) {
      result = result.replaceAll(mark, '');
    }
    return result;
  }

  /// Normalizes all alef variations to plain alef (ا)
  static String _normalizeAlefs(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ٲ', 'ا')
        .replaceAll('ٳ', 'ا')
        .replaceAll('ﭐ', 'ا')
        .replaceAll('ﭑ', 'ا');
  }

  /// Normalizes ta marbuta (ة) to ha (ه)
  static String _normalizeTaMarbuta(String text) {
    return text.replaceAll('ة', 'ه');
  }

  /// Normalizes alef maksura (ى) to ya (ي)
  static String _normalizeAlefMaksura(String text) {
    return text.replaceAll('ى', 'ي');
  }

  /// Checks if two strings match after normalization
  static bool matches(String text1, String text2) {
    return normalize(text1) == normalize(text2);
  }

  /// Checks if normalized query is contained in normalized text
  static bool contains(String text, String query) {
    return normalize(text).contains(normalize(query));
  }

  /// Checks if text starts with query after normalization
  static bool startsWith(String text, String query) {
    return normalize(text).startsWith(normalize(query));
  }

  /// Splits search query into tokens and checks if all are contained in text
  static bool containsAllTokens(String text, String query) {
    final normalizedText = normalize(text);
    final tokens = normalize(query).split(RegExp(r'\s+'));
    return tokens.every((token) => normalizedText.contains(token));
  }
}

/// Extension methods for String to work with Arabic normalization
extension ArabicStringExtensions on String {
  /// Returns normalized Arabic text
  String get normalized => ArabicNormalizer.normalize(this);

  /// Checks if this string matches another after normalization
  bool matchesArabic(String other) => ArabicNormalizer.matches(this, other);

  /// Checks if this string contains a query after normalization
  bool containsArabic(String query) => ArabicNormalizer.contains(this, query);

  /// Checks if this string starts with a query after normalization
  bool startsWithArabic(String query) => ArabicNormalizer.startsWith(this, query);

  /// Checks if all tokens from query are contained in this string
  bool containsAllArabicTokens(String query) => ArabicNormalizer.containsAllTokens(this, query);
}
