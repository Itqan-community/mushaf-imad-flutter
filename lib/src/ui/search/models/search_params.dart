/// Defines the scope (range) of a search.
enum SearchScope { all, surah, juz, page }

/// Holds the advanced filter settings for a search.
class SearchParams {
  final SearchScope scope;
  final int? scopeValue;
  final bool excludeNegated;

  const SearchParams({
    this.scope = SearchScope.all,
    this.scopeValue,
    this.excludeNegated = false,
  });

  SearchParams copyWith({
    SearchScope? scope,
    int? scopeValue,
    bool clearScopeValue = false,
    bool? excludeNegated,
  }) {
    return SearchParams(
      scope: scope ?? this.scope,
      scopeValue: clearScopeValue ? null : (scopeValue ?? this.scopeValue),
      excludeNegated: excludeNegated ?? this.excludeNegated,
    );
  }
}
