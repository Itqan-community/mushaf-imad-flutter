import '../models/search_history.dart';

/// Repository for managing search history and suggestions.
/// Public API - exposed to library consumers.
abstract class SearchHistoryRepository {
  /// Observe recent search history.
  Stream<List<SearchHistoryEntry>> getRecentSearchesStream({int limit = 20});

  /// Get recent search history.
  Future<List<SearchHistoryEntry>> getRecentSearches({int limit = 20});

  /// Record a search query.
  Future<void> recordSearch({
    required String query,
    required int resultCount,
    SearchType searchType = SearchType.general,
  });

  /// Get search suggestions based on history.
  Future<List<SearchSuggestion>> getSearchSuggestions({
    String? prefix,
    int limit = 10,
  });

  /// Get most popular searches.
  Future<List<SearchSuggestion>> getPopularSearches({int limit = 10});

  /// Delete a search history entry.
  Future<void> deleteSearch(String id);

  /// Delete all search history older than a timestamp.
  Future<void> deleteSearchesOlderThan(int timestamp);

  /// Clear all search history.
  Future<void> clearSearchHistory();

  /// Get search history for a specific type.
  Future<List<SearchHistoryEntry>> getSearchesByType(
    SearchType searchType, {
    int limit = 20,
  });
}
