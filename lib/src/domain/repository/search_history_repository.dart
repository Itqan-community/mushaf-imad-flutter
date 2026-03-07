import '../models/result.dart';
import '../models/search_history.dart';

/// Repository for managing search history and suggestions.
/// Public API - exposed to library consumers.
abstract class SearchHistoryRepository {
  /// Observe recent search history.
  Stream<List<SearchHistoryEntry>> getRecentSearchesStream({int limit = 20});

  /// Get recent search history.
  Future<Result<List<SearchHistoryEntry>>> getRecentSearches({int limit = 20});

  /// Record a search query (sets current timestamp).
  Future<Result<void>> recordSearch({
    required String query,
    required int resultCount,
    SearchType searchType = SearchType.general,
  });

  /// Insert a specific search history entry (for import/sync).
  Future<Result<void>> insertSearchHistory(SearchHistoryEntry entry);

  /// Get search suggestions based on history.
  Future<Result<List<SearchSuggestion>>> getSearchSuggestions({
    String? prefix,
    int limit = 10,
  });

  /// Get most popular searches.
  Future<Result<List<SearchSuggestion>>> getPopularSearches({int limit = 10});

  /// Delete a search history entry.
  Future<Result<void>> deleteSearch(String id);

  /// Delete all search history older than a timestamp.
  Future<Result<void>> deleteSearchesOlderThan(int timestamp);

  /// Clear all search history.
  Future<Result<void>> clearSearchHistory();

  /// Get search history for a specific type.
  Future<Result<List<SearchHistoryEntry>>> getSearchesByType(
    SearchType searchType, {
    int limit = 20,
  });
}
