import 'dart:async';
import 'package:hive/hive.dart';

import '../../../../domain/models/last_read_position.dart';
import '../../../../domain/models/mushaf_type.dart';
import '../../../../domain/models/reading_history.dart';
import '../reading_history_dao.dart';

/// Hive-backed implementation of [ReadingHistoryDao].
class HiveReadingHistoryDao implements ReadingHistoryDao {
  static const String _historyBoxName = 'reading_history';
  static const String _positionBoxName = 'last_read_positions';
  Box<Map>? _historyBox;
  Box<Map>? _positionBox;

  Future<Box<Map>> get _openHistoryBox async {
    _historyBox ??= await Hive.openBox<Map>(_historyBoxName);
    return _historyBox!;
  }

  Future<Box<Map>> get _openPositionBox async {
    _positionBox ??= await Hive.openBox<Map>(_positionBoxName);
    return _positionBox!;
  }

  ReadingHistory _historyFromMap(Map map) {
    return ReadingHistory(
      id: map['id'] as String,
      chapterNumber: map['chapterNumber'] as int,
      verseNumber: map['verseNumber'] as int,
      pageNumber: map['pageNumber'] as int,
      timestamp: map['timestamp'] as int,
      durationSeconds: map['durationSeconds'] as int,
      mushafType: MushafType.values[(map['mushafType'] as int?) ?? 0],
    );
  }

  Map<String, dynamic> _historyToMap(ReadingHistory h) {
    return {
      'id': h.id,
      'chapterNumber': h.chapterNumber,
      'verseNumber': h.verseNumber,
      'pageNumber': h.pageNumber,
      'timestamp': h.timestamp,
      'durationSeconds': h.durationSeconds,
      'mushafType': h.mushafType.index,
    };
  }

  LastReadPosition _positionFromMap(Map map) {
    return LastReadPosition(
      mushafType: MushafType.values[(map['mushafType'] as int?) ?? 0],
      chapterNumber: map['chapterNumber'] as int,
      verseNumber: map['verseNumber'] as int,
      pageNumber: map['pageNumber'] as int,
      lastReadAt: map['lastReadAt'] as int,
      scrollPosition: (map['scrollPosition'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> _positionToMap(LastReadPosition p) {
    return {
      'mushafType': p.mushafType.index,
      'chapterNumber': p.chapterNumber,
      'verseNumber': p.verseNumber,
      'pageNumber': p.pageNumber,
      'lastReadAt': p.lastReadAt,
      'scrollPosition': p.scrollPosition,
    };
  }

  @override
  Future<LastReadPosition?> getLastReadPosition(MushafType mushafType) async {
    final box = await _openPositionBox;
    final map = box.get(mushafType.name);
    return map != null ? _positionFromMap(map) : null;
  }

  @override
  Stream<LastReadPosition?> watchLastReadPosition(
    MushafType mushafType,
  ) async* {
    final box = await _openPositionBox;
    final map = box.get(mushafType.name);
    yield map != null ? _positionFromMap(map) : null;

    yield* box.watch(key: mushafType.name).map((event) {
      final m = event.value as Map?;
      return m != null ? _positionFromMap(m) : null;
    });
  }

  @override
  Future<void> saveLastReadPosition(LastReadPosition position) async {
    final box = await _openPositionBox;
    await box.put(position.mushafType.name, _positionToMap(position));
  }

  @override
  Future<void> insertHistory(ReadingHistory history) async {
    final box = await _openHistoryBox;
    await box.put(history.id, _historyToMap(history));
  }

  @override
  Future<List<ReadingHistory>> getRecentHistory(int limit) async {
    final box = await _openHistoryBox;
    final entries = box.values.map(_historyFromMap).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }

  @override
  Future<List<ReadingHistory>> getHistoryForDateRange(
    int startTimestamp,
    int endTimestamp,
  ) async {
    final box = await _openHistoryBox;
    return box.values
        .map(_historyFromMap)
        .where(
          (h) => h.timestamp >= startTimestamp && h.timestamp <= endTimestamp,
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<ReadingHistory>> getHistoryForChapter(int chapterNumber) async {
    final box = await _openHistoryBox;
    return box.values
        .map(_historyFromMap)
        .where((h) => h.chapterNumber == chapterNumber)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> deleteOlderThan(int timestamp) async {
    final box = await _openHistoryBox;
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
    final box = await _openHistoryBox;
    await box.clear();
  }

  @override
  Future<int> getTotalReadingTime() async {
    final box = await _openHistoryBox;
    int total = 0;
    for (final map in box.values) {
      total += (map['durationSeconds'] as int?) ?? 0;
    }
    return total;
  }

  @override
  Future<List<int>> getReadChapters() async {
    final box = await _openHistoryBox;
    final chapters = <int>{};
    for (final map in box.values) {
      chapters.add(map['chapterNumber'] as int);
    }
    return chapters.toList()..sort();
  }
}
