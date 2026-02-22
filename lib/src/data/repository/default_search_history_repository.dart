import '../../domain/models/search_history.dart';
import '../../domain/repository/search_history_repository.dart';
import '../local/dao/search_history_dao.dart';

/// Default implementation of SearchHistoryRepository.
class DefaultSearchHistoryRepository implements SearchHistoryRepository {
  final SearchHistoryDao _dao;

  DefaultSearchHistoryRepository(this._dao);

  @override
  Stream<List<SearchHistoryEntry>> getRecentSearchesStream({int limit = 20}) =>
      _dao.watchRecent(limit);

  @override
  Future<List<SearchHistoryEntry>> getRecentSearches({int limit = 20}) =>
      _dao.getRecent(limit);

  @override
  Future<void> recordSearch({
    required String query,
    required int resultCount,
    SearchType searchType = SearchType.general,
  }) async {
    final entry = SearchHistoryEntry(
      id: '${query.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
      query: query,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      resultCount: resultCount,
      searchType: searchType,
    );
    await _dao.insert(entry);
  }

  @override
  Future<List<SearchSuggestion>> getSearchSuggestions({
    String? prefix,
    int limit = 10,
  }) => _dao.getSuggestions(prefix: prefix, limit: limit);

  @override
  Future<List<SearchSuggestion>> getPopularSearches({int limit = 10}) =>
      _dao.getPopular(limit);

  @override
  Future<void> deleteSearch(String id) => _dao.delete(id);

  @override
  Future<void> deleteSearchesOlderThan(int timestamp) =>
      _dao.deleteOlderThan(timestamp);

  @override
  Future<void> clearSearchHistory() => _dao.deleteAll();

  @override
  Future<List<SearchHistoryEntry>> getSearchesByType(
    SearchType searchType, {
    int limit = 20,
  }) => _dao.getByType(searchType, limit);
}
