import '../domain/models/advanced_search.dart';
import '../domain/models/verse.dart';
import '../data/quran/quran_data_provider.dart';
import '../data/quran/verse_data_provider.dart';
import 'arabic_normalizer.dart';
import 'morphology_index.dart';

/// Verse ref parsed from the morphology index format "chapter:verse".
class _VerseRef {
  final int chapter;
  final int verse;
  const _VerseRef(this.chapter, this.verse);

  @override
  bool operator ==(Object other) =>
      other is _VerseRef && chapter == other.chapter && verse == other.verse;

  @override
  int get hashCode => Object.hash(chapter, verse);
}

/// Advanced verse search engine supporting multiple match modes
/// and Arabic text normalization.
class AdvancedVerseSearch {
  final VerseDataProvider _verseProvider;
  final MorphologyIndex _morphIndex;

  AdvancedVerseSearch({
    VerseDataProvider? verseProvider,
    MorphologyIndex? morphIndex,
  })  : _verseProvider = verseProvider ?? VerseDataProvider.instance,
        _morphIndex = morphIndex ?? MorphologyIndex.instance;

  Future<List<Verse>> search(VerseAdvancedSearchQuery query) async {
    if (query.query.trim().isEmpty) return [];

    if (!_verseProvider.isLoaded) {
      await _verseProvider.initialize();
    }

    switch (query.mode) {
      case TextMatchMode.root:
        return _searchByRoot(query);
      case TextMatchMode.lemma:
        return _searchByLemma(query);
      case TextMatchMode.exact:
      case TextMatchMode.prefix:
      case TextMatchMode.contains:
        return _searchByText(query);
    }
  }

  Future<List<Verse>> _searchByRoot(VerseAdvancedSearchQuery query) async {
    await _morphIndex.ensureLoaded();
    if (!_morphIndex.isLoaded) {
      return _searchByText(query.copyWith(mode: TextMatchMode.contains));
    }

    final normalizedQuery =
        ArabicNormalizer.normalize(query.query, query.options);

    // The query itself might be a root, or a word from which we derive roots
    var roots = <String>{normalizedQuery};
    final derivedRoots = _morphIndex.getRootsForWord(normalizedQuery);
    roots.addAll(derivedRoots);

    final matchingRefs = <_VerseRef>{};
    for (final root in roots) {
      for (final ref in _morphIndex.getVerseRefsForRoot(root)) {
        final parsed = _parseRef(ref);
        if (parsed != null) matchingRefs.add(parsed);
      }
    }

    return _materializeVerseRefs(matchingRefs);
  }

  Future<List<Verse>> _searchByLemma(VerseAdvancedSearchQuery query) async {
    await _morphIndex.ensureLoaded();
    if (!_morphIndex.isLoaded) {
      return _searchByText(query.copyWith(mode: TextMatchMode.contains));
    }

    final normalizedQuery =
        ArabicNormalizer.normalize(query.query, query.options);

    var lemmas = <String>{normalizedQuery};
    final derivedLemmas = _morphIndex.getLemmasForWord(normalizedQuery);
    lemmas.addAll(derivedLemmas);

    final matchingRefs = <_VerseRef>{};
    for (final lemma in lemmas) {
      for (final ref in _morphIndex.getVerseRefsForLemma(lemma)) {
        final parsed = _parseRef(ref);
        if (parsed != null) matchingRefs.add(parsed);
      }
    }

    return _materializeVerseRefs(matchingRefs);
  }

  List<Verse> _searchByText(VerseAdvancedSearchQuery query) {
    final options = query.options;
    final normalizedQuery = ArabicNormalizer.normalize(query.query, options);
    final results = <Verse>[];

    for (int page = 1; page <= QuranDataProvider.totalPages; page++) {
      final verses = _verseProvider.getVersesForPage(page);
      for (final v in verses) {
        final target = _pickTextForComparison(v.text, v.textWithoutTashkil,
            v.searchableText, options);

        if (_matches(target, normalizedQuery, query.mode)) {
          results.add(_toVerse(v, page));
        }
      }
    }

    return results;
  }

  String _pickTextForComparison(
    String text,
    String textWithoutTashkil,
    String searchableText,
    ArabicSearchOptions options,
  ) {
    if (options.ignoreDiacritics && textWithoutTashkil.isNotEmpty) {
      return ArabicNormalizer.normalize(textWithoutTashkil, options);
    }
    return ArabicNormalizer.normalize(text, options);
  }

  bool _matches(String text, String query, TextMatchMode mode) {
    switch (mode) {
      case TextMatchMode.contains:
        return text.contains(query);
      case TextMatchMode.exact:
        return _exactWordMatch(text, query);
      case TextMatchMode.prefix:
        return _prefixWordMatch(text, query);
      case TextMatchMode.root:
      case TextMatchMode.lemma:
        return text.contains(query);
    }
  }

  /// Check that `query` appears as a whole word in `text`.
  bool _exactWordMatch(String text, String query) {
    final words = text.split(RegExp(r'\s+'));
    return words.contains(query);
  }

  /// Check that any word in `text` starts with `query`.
  bool _prefixWordMatch(String text, String query) {
    final words = text.split(RegExp(r'\s+'));
    return words.any((w) => w.startsWith(query));
  }

  _VerseRef? _parseRef(String ref) {
    final parts = ref.split(':');
    if (parts.length != 2) return null;
    final chapter = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    if (chapter == null || verse == null) return null;
    return _VerseRef(chapter, verse);
  }

  List<Verse> _materializeVerseRefs(Set<_VerseRef> refs) {
    if (refs.isEmpty) return [];

    final results = <Verse>[];

    for (int page = 1; page <= QuranDataProvider.totalPages; page++) {
      final verses = _verseProvider.getVersesForPage(page);
      for (final v in verses) {
        if (refs.contains(_VerseRef(v.chapter, v.number))) {
          results.add(_toVerse(v, page));
        }
      }
    }

    // Sort by canonical order
    results.sort((a, b) {
      final cmp = a.chapterNumber.compareTo(b.chapterNumber);
      if (cmp != 0) return cmp;
      return a.number.compareTo(b.number);
    });

    return results;
  }

  Verse _toVerse(dynamic v, int page) {
    return Verse(
      verseID: v.verseID,
      humanReadableID: '${v.chapter}_${v.number}',
      number: v.number,
      text: v.text,
      textWithoutTashkil: v.textWithoutTashkil,
      uthmanicHafsText: '',
      hafsSmartText: '',
      searchableText: v.searchableText,
      chapterNumber: v.chapter,
      pageNumber: page,
    );
  }
}
