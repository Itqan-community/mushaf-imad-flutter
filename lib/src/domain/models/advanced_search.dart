/// Match mode for advanced verse search.
/// Public API - exposed to library consumers.
enum TextMatchMode {
  /// Substring match anywhere in the verse text.
  contains,

  /// Whole-word exact match (word boundaries respected).
  exact,

  /// Word starts with the query string.
  prefix,

  /// Search by Arabic trilateral root via morphology index.
  root,

  /// Search by lemma (dictionary form) via morphology index.
  lemma,
}

/// Options controlling Arabic text preprocessing before comparison.
/// Public API - exposed to library consumers.
class ArabicSearchOptions {
  /// Strip all Arabic diacritics (tashkil) from both query and target text.
  final bool ignoreDiacritics;

  /// Normalize letter variants:
  /// أ/إ/آ → ا, ى → ي, ة → ه, ؤ → و, ئ → ي.
  final bool normalizeLetters;

  /// Remove tatweel (kashida), Arabic punctuation, and collapse whitespace.
  final bool stripTatweelAndPunct;

  const ArabicSearchOptions({
    this.ignoreDiacritics = true,
    this.normalizeLetters = true,
    this.stripTatweelAndPunct = true,
  });

  static const ArabicSearchOptions defaults = ArabicSearchOptions();

  bool get isDefault => this == defaults;

  ArabicSearchOptions copyWith({
    bool? ignoreDiacritics,
    bool? normalizeLetters,
    bool? stripTatweelAndPunct,
  }) {
    return ArabicSearchOptions(
      ignoreDiacritics: ignoreDiacritics ?? this.ignoreDiacritics,
      normalizeLetters: normalizeLetters ?? this.normalizeLetters,
      stripTatweelAndPunct: stripTatweelAndPunct ?? this.stripTatweelAndPunct,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArabicSearchOptions &&
          ignoreDiacritics == other.ignoreDiacritics &&
          normalizeLetters == other.normalizeLetters &&
          stripTatweelAndPunct == other.stripTatweelAndPunct;

  @override
  int get hashCode => Object.hash(
        ignoreDiacritics,
        normalizeLetters,
        stripTatweelAndPunct,
      );
}

/// Full advanced search query for verse search.
/// Public API - exposed to library consumers.
class VerseAdvancedSearchQuery {
  final String query;
  final TextMatchMode mode;
  final ArabicSearchOptions options;

  const VerseAdvancedSearchQuery({
    required this.query,
    this.mode = TextMatchMode.contains,
    this.options = const ArabicSearchOptions(),
  });

  VerseAdvancedSearchQuery copyWith({
    String? query,
    TextMatchMode? mode,
    ArabicSearchOptions? options,
  }) {
    return VerseAdvancedSearchQuery(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      options: options ?? this.options,
    );
  }

  /// Whether this query uses the morphology index.
  bool get requiresMorphologyIndex =>
      mode == TextMatchMode.root || mode == TextMatchMode.lemma;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseAdvancedSearchQuery &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          mode == other.mode &&
          options == other.options;

  @override
  int get hashCode => Object.hash(query, mode, options);
}
