import '../../../domain/models/search_history.dart';

/// Data Access Object interface for search history.
/// Abstraction layer to keep DB implementation swappable.
abstract class SearchHistoryDao {
  Future<List<SearchHistoryEntry>> getRecent(int limit);
  Stream<List<SearchHistoryEntry>> watchRecent(int limit);
  Future<void> insert(SearchHistoryEntry entry);
  Future<List<SearchSuggestion>> getSuggestions({
    String? prefix,
    int limit = 10,
  });
  Future<List<SearchSuggestion>> getPopular(int limit);
  Future<void> delete(String id);
  Future<void> deleteOlderThan(int timestamp);
  Future<void> deleteAll();
  Future<List<SearchHistoryEntry>> getByType(SearchType type, int limit);
}
