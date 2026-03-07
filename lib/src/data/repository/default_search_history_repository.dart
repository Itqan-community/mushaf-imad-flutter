import '../../domain/error/failure.dart';
import '../../domain/models/result.dart';
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
  Future<Result<List<SearchHistoryEntry>>> getRecentSearches({int limit = 20}) =>
      Result.runCatching(
        () => _dao.getRecent(limit),
        failureMapper: (e) => DatabaseFailure('Failed to fetch recent searches', e),
      );

  @override
  Future<Result<void>> recordSearch({
    required String query,
    required int resultCount,
    SearchType searchType = SearchType.general,
  }) =>
      Result.runCatching(
        () async {
          final entry = SearchHistoryEntry(
            id: '${query.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
            query: query,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            resultCount: resultCount,
            searchType: searchType,
          );
          await _dao.insert(entry);
        },
        failureMapper: (e) => DatabaseFailure('Failed to record search', e),
      );

  @override
  Future<Result<void>> insertSearchHistory(SearchHistoryEntry entry) =>
      Result.runCatching(
        () => _dao.insert(entry),
        failureMapper: (e) => DatabaseFailure('Failed to insert search history', e),
      );

  @override
  Future<Result<List<SearchSuggestion>>> getSearchSuggestions({
    String? prefix,
    int limit = 10,
  }) =>
      Result.runCatching(
        () => _dao.getSuggestions(prefix: prefix, limit: limit),
        failureMapper: (e) => DatabaseFailure('Failed to fetch search suggestions', e),
      );

  @override
  Future<Result<List<SearchSuggestion>>> getPopularSearches({int limit = 10}) =>
      Result.runCatching(
        () => _dao.getPopular(limit),
        failureMapper: (e) => DatabaseFailure('Failed to fetch popular searches', e),
      );

  @override
  Future<Result<void>> deleteSearch(String id) => Result.runCatching(
        () => _dao.delete(id),
        failureMapper: (e) => DatabaseFailure('Failed to delete search entry', e),
      );

  @override
  Future<Result<void>> deleteSearchesOlderThan(int timestamp) =>
      Result.runCatching(
        () => _dao.deleteOlderThan(timestamp),
        failureMapper: (e) => DatabaseFailure('Failed to delete old searches', e),
      );

  @override
  Future<Result<void>> clearSearchHistory() => Result.runCatching(
        () => _dao.deleteAll(),
        failureMapper: (e) => DatabaseFailure('Failed to clear search history', e),
      );

  @override
  Future<Result<List<SearchHistoryEntry>>> getSearchesByType(
    SearchType searchType, {
    int limit = 20,
  }) =>
      Result.runCatching(
        () => _dao.getByType(searchType, limit),
        failureMapper: (e) => DatabaseFailure('Failed to fetch searches by type', e),
      );
}
