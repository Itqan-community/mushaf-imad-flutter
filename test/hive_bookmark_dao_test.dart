import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => Directory.systemTemp.path,
      );

  late HiveBookmarkDao dao;

  setUpAll(() async {
    await setupMushafWithHive();
    dao = mushafGetIt<BookmarkDao>() as HiveBookmarkDao;
  });

  setUp(() async {
    await dao.deleteAll();
  });

  Bookmark _createBookmark({
    String id = 'bm-1',
    int chapterNumber = 1,
    int verseNumber = 1,
    int pageNumber = 1,
    int createdAt = 1000,
    String note = '',
    List<String> tags = const [],
  }) {
    return Bookmark(
      id: id,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      createdAt: createdAt,
      note: note,
      tags: tags,
    );
  }

  group('insert', () {
    test('should store and retrieve a bookmark', () async {
      final bookmark = _createBookmark();
      await dao.insert(bookmark);

      final result = await dao.getById('bm-1');
      expect(result, isNotNull);
      expect(result!.id, 'bm-1');
      expect(result.chapterNumber, 1);
      expect(result.verseNumber, 1);
      expect(result.pageNumber, 1);
    });

    test('should store bookmark with note and tags', () async {
      final bookmark = _createBookmark(
        note: 'Important verse',
        tags: ['favorite', 'memorize'],
      );
      await dao.insert(bookmark);

      final result = await dao.getById('bm-1');
      expect(result!.note, 'Important verse');
      expect(result.tags, ['favorite', 'memorize']);
    });

    test('should overwrite bookmark with same id', () async {
      await dao.insert(_createBookmark(pageNumber: 1));
      await dao.insert(_createBookmark(pageNumber: 5));

      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all.first.pageNumber, 5);
    });
  });

  group('getAll', () {
    test('should return empty list when no bookmarks', () async {
      final result = await dao.getAll();
      expect(result, isEmpty);
    });

    test('should return bookmarks sorted by createdAt descending', () async {
      await dao.insert(_createBookmark(id: 'a', createdAt: 100));
      await dao.insert(_createBookmark(id: 'b', createdAt: 300));
      await dao.insert(_createBookmark(id: 'c', createdAt: 200));

      final result = await dao.getAll();
      expect(result.length, 3);
      expect(result[0].id, 'b');
      expect(result[1].id, 'c');
      expect(result[2].id, 'a');
    });
  });

  group('getById', () {
    test('should return null for non-existent id', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('should return correct bookmark', () async {
      await dao.insert(_createBookmark(id: 'x', chapterNumber: 5));
      final result = await dao.getById('x');
      expect(result!.chapterNumber, 5);
    });
  });

  group('getByChapter', () {
    test('should return bookmarks for specific chapter', () async {
      await dao.insert(
        _createBookmark(id: '1', chapterNumber: 2, verseNumber: 1),
      );
      await dao.insert(
        _createBookmark(id: '2', chapterNumber: 2, verseNumber: 5),
      );
      await dao.insert(
        _createBookmark(id: '3', chapterNumber: 3, verseNumber: 1),
      );

      final result = await dao.getByChapter(2);
      expect(result.length, 2);
      expect(result.every((b) => b.chapterNumber == 2), true);
    });

    test('should return empty list for chapter with no bookmarks', () async {
      final result = await dao.getByChapter(99);
      expect(result, isEmpty);
    });
  });

  group('getByVerse', () {
    test('should return bookmark for specific verse', () async {
      await dao.insert(
        _createBookmark(id: '1', chapterNumber: 2, verseNumber: 255),
      );

      final result = await dao.getByVerse(2, 255);
      expect(result, isNotNull);
      expect(result!.id, '1');
    });

    test('should return null when verse not bookmarked', () async {
      final result = await dao.getByVerse(1, 1);
      expect(result, isNull);
    });
  });

  group('existsByVerse', () {
    test('should return true when verse is bookmarked', () async {
      await dao.insert(
        _createBookmark(chapterNumber: 36, verseNumber: 1),
      );
      final result = await dao.existsByVerse(36, 1);
      expect(result, true);
    });

    test('should return false when verse is not bookmarked', () async {
      final result = await dao.existsByVerse(36, 1);
      expect(result, false);
    });
  });

  group('updateNote', () {
    test('should update note for existing bookmark', () async {
      await dao.insert(_createBookmark(id: 'n1'));
      await dao.updateNote('n1', 'Updated note');

      final result = await dao.getById('n1');
      expect(result!.note, 'Updated note');
    });

    test('should not throw for non-existent bookmark', () async {
      await dao.updateNote('non-existent', 'note');
      // should not throw
    });
  });

  group('updateTags', () {
    test('should update tags for existing bookmark', () async {
      await dao.insert(_createBookmark(id: 't1'));
      await dao.updateTags('t1', ['quran', 'tafsir']);

      final result = await dao.getById('t1');
      expect(result!.tags, ['quran', 'tafsir']);
    });
  });

  group('delete', () {
    test('should remove bookmark by id', () async {
      await dao.insert(_createBookmark(id: 'd1'));
      await dao.delete('d1');

      final result = await dao.getById('d1');
      expect(result, isNull);
    });
  });

  group('deleteByVerse', () {
    test('should remove bookmark for specific verse', () async {
      await dao.insert(
        _createBookmark(id: 'v1', chapterNumber: 1, verseNumber: 7),
      );
      await dao.deleteByVerse(1, 7);

      final result = await dao.getByVerse(1, 7);
      expect(result, isNull);
    });
  });

  group('deleteAll', () {
    test('should remove all bookmarks', () async {
      await dao.insert(_createBookmark(id: 'a'));
      await dao.insert(_createBookmark(id: 'b'));
      await dao.insert(_createBookmark(id: 'c'));

      await dao.deleteAll();
      final result = await dao.getAll();
      expect(result, isEmpty);
    });
  });

  group('search', () {
    test('should find bookmarks by note content', () async {
      await dao.insert(
        _createBookmark(id: 's1', note: 'Ayat Al-Kursi'),
      );
      await dao.insert(
        _createBookmark(id: 's2', note: 'Last verses of Baqarah'),
      );

      final result = await dao.search('kursi');
      expect(result.length, 1);
      expect(result.first.id, 's1');
    });

    test('should find bookmarks by tag', () async {
      await dao.insert(
        _createBookmark(id: 't1', tags: ['morning-adhkar']),
      );
      await dao.insert(
        _createBookmark(id: 't2', tags: ['memorize']),
      );

      final result = await dao.search('adhkar');
      expect(result.length, 1);
      expect(result.first.id, 't1');
    });

    test('should find bookmarks by verse reference', () async {
      await dao.insert(
        _createBookmark(id: 'r1', chapterNumber: 2, verseNumber: 255),
      );

      final result = await dao.search('2:255');
      expect(result.length, 1);
      expect(result.first.id, 'r1');
    });

    test('should return empty list when no matches', () async {
      await dao.insert(_createBookmark(id: 'x'));
      final result = await dao.search('nonexistent');
      expect(result, isEmpty);
    });
  });

  group('watchAll', () {
    test('should emit initial bookmarks', () async {
      await dao.insert(_createBookmark(id: 'w1'));

      final stream = dao.watchAll();
      final first = await stream.first;
      expect(first.length, 1);
      expect(first.first.id, 'w1');
    });
  });
}
