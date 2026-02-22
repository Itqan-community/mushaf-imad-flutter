import 'dart:async';
import 'package:hive/hive.dart';

import '../../../../domain/models/search_history.dart';
import '../search_history_dao.dart';

/// Hive-backed implementation of [SearchHistoryDao].
class HiveSearchHistoryDao implements SearchHistoryDao {
  static const String _boxName = 'search_history';
  Box<Map>? _box;

  Future<Box<Map>> get _openBox async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  SearchHistoryEntry _fromMap(Map map) {
    return SearchHistoryEntry(
      id: map['id'] as String,
      query: map['query'] as String,
      timestamp: map['timestamp'] as int,
      resultCount: map['resultCount'] as int,
      searchType: SearchType.values[(map['searchType'] as int?) ?? 0],
    );
  }

  Map<String, dynamic> _toMap(SearchHistoryEntry e) {
    return {
      'id': e.id,
      'query': e.query,
      'timestamp': e.timestamp,
      'resultCount': e.resultCount,
      'searchType': e.searchType.index,
    };
  }

  @override
  Future<List<SearchHistoryEntry>> getRecent(int limit) async {
    final box = await _openBox;
    final entries = box.values.map(_fromMap).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  @override
  Stream<List<SearchHistoryEntry>> watchRecent(int limit) async* {
    final box = await _openBox;
    yield (box.values.map(_fromMap).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
        .take(limit)
        .toList();

    yield* box.watch().map((_) {
      return (box.values.map(_fromMap).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
          .take(limit)
          .toList();
    });
  }

  @override
  Future<void> insert(SearchHistoryEntry entry) async {
    final box = await _openBox;
    await box.put(entry.id, _toMap(entry));
  }

  @override
  Future<List<SearchSuggestion>> getSuggestions({
    String? prefix,
    int limit = 10,
  }) async {
    final box = await _openBox;
    // Group by query, count frequency, sort by frequency
    final queryMap = <String, _QueryAgg>{};
    for (final map in box.values) {
      final query = map['query'] as String;
      if (prefix != null &&
          !query.toLowerCase().startsWith(prefix.toLowerCase())) {
        continue;
      }
      final existing = queryMap[query];
      final timestamp = map['timestamp'] as int;
      if (existing != null) {
        existing.count++;
        if (timestamp > existing.lastSearched) {
          existing.lastSearched = timestamp;
        }
      } else {
        queryMap[query] = _QueryAgg(count: 1, lastSearched: timestamp);
      }
    }

    final suggestions =
        queryMap.entries
            .map(
              (e) => SearchSuggestion(
                query: e.key,
                frequency: e.value.count,
                lastSearched: e.value.lastSearched,
              ),
            )
            .toList()
          ..sort((a, b) => b.frequency.compareTo(a.frequency));

    return suggestions.take(limit).toList();
  }

  @override
  Future<List<SearchSuggestion>> getPopular(int limit) async {
    return getSuggestions(limit: limit);
  }

  @override
  Future<void> delete(String id) async {
    final box = await _openBox;
    await box.delete(id);
  }

  @override
  Future<void> deleteOlderThan(int timestamp) async {
    final box = await _openBox;
    final keysToDelete = <dynamic>[];
    for (final entry in box.toMap().entries) {
      if ((entry.value['timestamp'] as int) < timestamp) {
        keysToDelete.add(entry.key);
      }
    }
    await box.deleteAll(keysToDelete);
  }

  @override
  Future<void> deleteAll() async {
    final box = await _openBox;
    await box.clear();
  }

  @override
  Future<List<SearchHistoryEntry>> getByType(SearchType type, int limit) async {
    final box = await _openBox;
    final entries =
        box.values.map(_fromMap).where((e) => e.searchType == type).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }
}

class _QueryAgg {
  int count;
  int lastSearched;
  _QueryAgg({required this.count, required this.lastSearched});
}
