/// Search query types.
/// Public API - exposed to library consumers.
enum SearchType {
  /// Search in verse text
  verse,

  /// Search in chapter names
  chapter,

  /// General search across all fields
  general,
}

/// Search history entry.
/// Public API - exposed to library consumers.
class SearchHistoryEntry {
  final String id;
  final String query;
  final int timestamp;
  final int resultCount;
  final SearchType searchType;

  const SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.searchType,
  });

  /// Check if this search is recent (within last 24 hours).
  bool isRecent() {
    final oneDayAgo =
        DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
    return timestamp > oneDayAgo;
  }
}

/// Search suggestion based on history.
/// Public API - exposed to library consumers.
class SearchSuggestion {
  final String query;
  final int frequency; // How many times this query was searched
  final int lastSearched; // Timestamp of last search

  const SearchSuggestion({
    required this.query,
    required this.frequency,
    required this.lastSearched,
  });
}
