import '../../domain/models/verse.dart';
import '../../domain/models/search_history.dart';
import 'models/search_params.dart';

class SearchEngine {
  /// Normalize the query the same way the JSON data was pre-processed.
  static String normalizeQuery(String query) {
    return query
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // strip tashkil
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  static List<Verse> search({
    required List<Verse> allVerses,
    required String query,
    required SearchType searchType,
    required SearchParams params,
  }) {
    final q = normalizeQuery(query);
    if (q.isEmpty) return [];

    Iterable<Verse> results = allVerses;

    // 1. Apply scope filter first (narrows the list)
    if (params.scope != SearchScope.all && params.scopeValue != null) {
      results = results.where((v) => _matchesScope(v, params));
    }

    // 2. Apply text matching based on search type
    results = results.where(
      (v) => _matchesType(v.searchableText, q, searchType),
    );

    // 3. Optionally exclude negated verses (e.g. لا يؤمنون)
    if (params.excludeNegated) {
      results = results.where((v) => !_hasNegationBefore(v.searchableText, q));
    }

    return results.toList();
  }

  static bool _matchesType(String text, String q, SearchType type) {
    switch (type) {
      case SearchType.general:
      case SearchType.verse:
        return text.contains(q);

      case SearchType.exact:
        return text.contains(' $q ') ||
            text.trimLeft().startsWith('$q ') ||
            text.trimRight().endsWith(' $q');

      case SearchType.prefix:
        return text.split(' ').any((w) => w.isNotEmpty && w.startsWith(q));

      case SearchType.root:
        return text
            .split(' ')
            .any(
              (w) =>
                  w.isNotEmpty &&
                  w.contains(q) &&
                  w.length >= q.length &&
                  w.length <= q.length + 5,
            );

      case SearchType.chapter:
        return false;
    }
  }

  static bool _matchesScope(Verse v, SearchParams params) {
    switch (params.scope) {
      case SearchScope.surah:
        return v.chapterNumber == params.scopeValue;
      case SearchScope.juz:
        return v.partNumber == params.scopeValue;
      case SearchScope.page:
        return v.pageNumber == params.scopeValue;
      case SearchScope.all:
        return true;
    }
  }

  static bool _hasNegationBefore(String text, String query) {
    final negators = ['لا ', 'ما ', 'لم ', 'لن ', 'غير ', 'ليس '];
    final idx = text.indexOf(query);
    if (idx <= 0) return false;
    final before = text.substring(0, idx);
    return negators.any((n) => before.endsWith(n));
  }
}
