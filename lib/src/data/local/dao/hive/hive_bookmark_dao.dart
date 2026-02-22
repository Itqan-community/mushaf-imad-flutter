import 'dart:async';
import 'package:hive/hive.dart';

import '../../../../domain/models/bookmark.dart';
import '../bookmark_dao.dart';

/// Hive-backed implementation of [BookmarkDao].
class HiveBookmarkDao implements BookmarkDao {
  static const String _boxName = 'bookmarks';
  Box<Map>? _box;

  Future<Box<Map>> get _openBox async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Bookmark _fromMap(Map map) {
    return Bookmark(
      id: map['id'] as String,
      chapterNumber: map['chapterNumber'] as int,
      verseNumber: map['verseNumber'] as int,
      pageNumber: map['pageNumber'] as int,
      createdAt: map['createdAt'] as int,
      note: (map['note'] as String?) ?? '',
      tags: List<String>.from((map['tags'] as List?) ?? []),
    );
  }

  Map<String, dynamic> _toMap(Bookmark b) {
    return {
      'id': b.id,
      'chapterNumber': b.chapterNumber,
      'verseNumber': b.verseNumber,
      'pageNumber': b.pageNumber,
      'createdAt': b.createdAt,
      'note': b.note,
      'tags': b.tags,
    };
  }

  @override
  Future<List<Bookmark>> getAll() async {
    final box = await _openBox;
    return box.values.map(_fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<Bookmark>> watchAll() async* {
    final box = await _openBox;
    yield box.values.map(_fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    yield* box.watch().map((_) {
      return box.values.map(_fromMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Future<Bookmark?> getById(String id) async {
    final box = await _openBox;
    final map = box.get(id);
    return map != null ? _fromMap(map) : null;
  }

  @override
  Future<List<Bookmark>> getByChapter(int chapterNumber) async {
    final all = await getAll();
    return all.where((b) => b.chapterNumber == chapterNumber).toList();
  }

  @override
  Future<Bookmark?> getByVerse(int chapterNumber, int verseNumber) async {
    final all = await getAll();
    for (final b in all) {
      if (b.chapterNumber == chapterNumber && b.verseNumber == verseNumber) {
        return b;
      }
    }
    return null;
  }

  @override
  Future<Bookmark> insert(Bookmark bookmark) async {
    final box = await _openBox;
    await box.put(bookmark.id, _toMap(bookmark));
    return bookmark;
  }

  @override
  Future<void> updateNote(String id, String note) async {
    final box = await _openBox;
    final map = box.get(id);
    if (map != null) {
      map['note'] = note;
      await box.put(id, map);
    }
  }

  @override
  Future<void> updateTags(String id, List<String> tags) async {
    final box = await _openBox;
    final map = box.get(id);
    if (map != null) {
      map['tags'] = tags;
      await box.put(id, map);
    }
  }

  @override
  Future<void> delete(String id) async {
    final box = await _openBox;
    await box.delete(id);
  }

  @override
  Future<void> deleteByVerse(int chapterNumber, int verseNumber) async {
    final box = await _openBox;
    final keysToDelete = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final m = entry.value;
      if (m['chapterNumber'] == chapterNumber &&
          m['verseNumber'] == verseNumber) {
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
  Future<bool> existsByVerse(int chapterNumber, int verseNumber) async {
    final result = await getByVerse(chapterNumber, verseNumber);
    return result != null;
  }

  @override
  Future<List<Bookmark>> search(String query) async {
    final all = await getAll();
    final lowerQuery = query.toLowerCase();
    return all.where((b) {
      return b.note.toLowerCase().contains(lowerQuery) ||
          b.tags.any((t) => t.toLowerCase().contains(lowerQuery)) ||
          b.verseReference.contains(lowerQuery);
    }).toList();
  }
}
