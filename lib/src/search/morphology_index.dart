import 'dart:convert';

import 'package:flutter/services.dart';

/// Lazily-loaded morphology index for root and lemma lookups.
///
/// Loads from `assets/masaq_morph_index.min.json` on first access.
class MorphologyIndex {
  MorphologyIndex._();

  static final MorphologyIndex instance = MorphologyIndex._();

  bool _loaded = false;
  bool _loading = false;

  /// normalized word → list of roots
  Map<String, List<String>> _wordToRoots = {};

  /// normalized word → list of lemmas
  Map<String, List<String>> _wordToLemmas = {};

  /// root → list of verse refs ("chapter:verse")
  Map<String, List<String>> _rootToVerseRefs = {};

  /// lemma → list of verse refs ("chapter:verse")
  Map<String, List<String>> _lemmaToVerseRefs = {};

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final jsonStr = await rootBundle.loadString(
        'packages/imad_flutter/assets/masaq_morph_index.min.json',
      );
      _parseJson(jsonStr);
    } catch (_) {
      // Fallback: try without package prefix (for example app)
      try {
        final jsonStr = await rootBundle.loadString(
          'assets/masaq_morph_index.min.json',
        );
        _parseJson(jsonStr);
      } catch (_) {
        _loaded = false;
        _loading = false;
        return;
      }
    }
    _loaded = true;
    _loading = false;
  }

  void _parseJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _wordToRoots = _parseStringListMap(data['wordToRoots']);
    _wordToLemmas = _parseStringListMap(data['wordToLemmas']);
    _rootToVerseRefs = _parseStringListMap(data['rootToVerseRefs']);
    _lemmaToVerseRefs = _parseStringListMap(data['lemmaToVerseRefs']);
  }

  Map<String, List<String>> _parseStringListMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) {
      final list =
          (value as List).map((e) => e.toString()).toList(growable: false);
      return MapEntry(key.toString(), list);
    });
  }

  /// Look up roots for a normalized word.
  List<String> getRootsForWord(String normalizedWord) {
    return _wordToRoots[normalizedWord] ?? const [];
  }

  /// Look up lemmas for a normalized word.
  List<String> getLemmasForWord(String normalizedWord) {
    return _wordToLemmas[normalizedWord] ?? const [];
  }

  /// Get all verse refs that contain a given root.
  /// Each ref is "chapter:verse" (e.g. "2:255").
  List<String> getVerseRefsForRoot(String root) {
    return _rootToVerseRefs[root] ?? const [];
  }

  /// Get all verse refs that contain a given lemma.
  List<String> getVerseRefsForLemma(String lemma) {
    return _lemmaToVerseRefs[lemma] ?? const [];
  }

  /// Get all known roots (useful for autocomplete).
  Iterable<String> get allRoots => _rootToVerseRefs.keys;

  /// Get all known lemmas.
  Iterable<String> get allLemmas => _lemmaToVerseRefs.keys;

  /// Load from a raw JSON string (for testing).
  void loadFromJsonString(String jsonStr) {
    _parseJson(jsonStr);
    _loaded = true;
  }

  /// Reset state (for testing).
  void reset() {
    _loaded = false;
    _loading = false;
    _wordToRoots = {};
    _wordToLemmas = {};
    _rootToVerseRefs = {};
    _lemmaToVerseRefs = {};
  }
}
