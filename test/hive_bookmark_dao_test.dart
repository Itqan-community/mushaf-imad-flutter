import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:async/async.dart';

/// Entry point for HiveBookmarkDao test suite.
///
/// This suite verifies CRUD operations, search functionality,
/// and reactive stream behavior (`watchAll`) for bookmarks.
void main() {
  late HiveBookmarkDao dao;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
  });

  setUp(() async {
    dao = HiveBookmarkDao();
    await dao.deleteAll();
  });

  tearDown(() async {
    /// Close any open boxes to avoid conflicts between tests.
    await Hive.close();
  });

  tearDownAll(() async {
    /// Delete all temporary files created during the test run.
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Helper factory method to generate test bookmarks
  /// with customizable properties.
  Bookmark createBookmark({
    String id = '1',
    int chapter = 2,
    int verse = 255,
    int page = 42,
    int createdAt = 1000,
    String note = 'note',
    List<String> tags = const ['tag1'],
  }) {
    return Bookmark(
      id: id,
      chapterNumber: chapter,
      verseNumber: verse,
      pageNumber: page,
      createdAt: createdAt,
      note: note,
      tags: tags,
    );
  }

  group('HiveBookmarkDao', () {
    /// Verifies that inserting a bookmark and retrieving it by ID
    /// returns the exact same data.
    test('insert and getById returns the same bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final result = await dao.getById('1');

      expect(result, isNotNull);
      expect(result!.id, '1');
      expect(result.chapterNumber, 2);
      expect(result.verseNumber, 255);

      /// Ensure non-existing ID returns null.
      final missingBookmark = await dao.getById('999');
      expect(missingBookmark, isNull);
    });

    /// Ensures that `getAll` returns bookmarks sorted
    /// by `createdAt` in descending order.
    test('getAll returns bookmarks sorted by createdAt descending', () async {
      final b1 = createBookmark(id: '1', createdAt: 1000);
      final b2 = createBookmark(id: '2', createdAt: 2000);

      await dao.insert(b1);
      await dao.insert(b2);

      final results = await dao.getAll();

      expect(results.length, 2);
      expect(results.first.id, '2');
      expect(results.last.id, '1');
    });

    group('HiveBookmarkDao - watchAll', () {
      test('emits empty list initially', () async {
        final queue = StreamQueue(dao.watchAll());

        final first = await queue.next;
        expect(first, isA<List<Bookmark>>());
        expect(first.length, 0);

        await queue.cancel();
      });

      test('emits existing bookmarks', () async {
        final bookmark = createBookmark();
        await dao.insert(bookmark);

        final queue = StreamQueue(dao.watchAll());

        final first = await queue.next;
        expect(first.length, 1);

        await queue.cancel();
      });

      /// Uses [pumpEventQueue] instead of [Future.delayed] so the test runs
      /// without any wall-clock wait: pumpEventQueue() drains all pending
      /// microtasks and event-loop callbacks, which is exactly what Hive needs
      /// to deliver a box.watch() event to its listeners.
      test('emits updated list when bookmark is inserted', () async {
        final stream = dao.watchAll();

        final expectation = expectLater(
          stream,
          emitsInOrder([
            [],
            predicate<List<Bookmark>>((value) {
              expect(value.length, 1);
              expect(value.first.id, 'id1');
              return true;
            }),
            predicate<List<Bookmark>>((value) {
              expect(value.length, 2);
              expect(value.first.id, 'id2');
              expect(value.first.note, 'new note');
              expect(value.last.id, 'id1');
              return true;
            }),
          ]),
        );

        await pumpEventQueue();
        await dao.insert(createBookmark(id: 'id1', createdAt: 100));

        await pumpEventQueue();
        await dao.insert(
          createBookmark(id: 'id2', note: 'new note', createdAt: 200),
        );

        await pumpEventQueue();
        await expectation;
      });

      test('emits updated list after bookmark deletion', () async {
        final stream = dao.watchAll();
        final expectation = expectLater(
          stream,
          emitsInOrder([
            [],
            predicate<List<Bookmark>>((value) {
              expect(value.length, 1);
              expect(value.first.id, 'id1');
              return true;
            }),
            [],
          ]),
        );

        await pumpEventQueue();
        await dao.insert(createBookmark(id: 'id1', createdAt: 100));

        await pumpEventQueue();
        await dao.delete('id1');

        await pumpEventQueue();
        await expectation;
      });

      test('emits bookmarks sorted by createdAt descending', () async {
        final older = createBookmark(id: '1', createdAt: 100);
        final newer = createBookmark(id: '2', createdAt: 200);

        await dao.insert(older);
        await dao.insert(newer);

        final queue = StreamQueue(dao.watchAll());

        final list = await queue.next;

        expect(list.first.id, '2');
        expect(list.last.id, '1');

        await queue.cancel();
      });
    });

    /// Tests fetching a bookmark by chapter.
    test('getByChapter returns correct bookmark', () async {
      final b1 = createBookmark(id: '1', chapter: 2);
      final b2 = createBookmark(id: '2', chapter: 2);
      final b3 = createBookmark(id: '3', chapter: 3);

      await dao.insert(b1);
      await dao.insert(b2);
      await dao.insert(b3);

      final result = await dao.getByChapter(2);

      expect(result, isNotNull);
      expect(result.length, 2);
    });

    /// Tests fetching a bookmark by verse.
    test('getByVerse returns correct bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final result = await dao.getByVerse(2, 255);

      expect(result, isNotNull);
      expect(result!.id, '1');
    });

    /// Checks existence logic for bookmarks.
    test('existsByVerse returns true when bookmark exists', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final exists = await dao.existsByVerse(2, 255);

      expect(exists, true);
    });

    test('existsByVerse returns false when bookmark does not exist', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      final exists = await dao.existsByVerse(3, 10);

      expect(exists, false);
    });

    /// Verifies note update affects only targeted bookmark.
    test('updateNote updates the bookmark note', () async {
      final bookmark1 = createBookmark();
      final bookmark2 = createBookmark(id: '2');

      await dao.insert(bookmark1);
      await dao.insert(bookmark2);

      await dao.updateNote('1', 'new');

      final updatedBookmark = await dao.getById('1');

      final untouchedBookmark = await dao.getById('2');

      expect(updatedBookmark!.note, 'new');
      expect(untouchedBookmark!.note, isNot('new'));
      expect(untouchedBookmark.note, 'note');
    });

    /// Verifies tag replacement logic.
    test('updateTags updates bookmark tags', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.updateTags('1', ['tafseer', 'memorization']);

      final result = await dao.getById('1');

      expect(result!.tags.length, 2);
      expect(result.tags.contains('tafseer'), true);
      expect(result.tags.contains('memorization'), true);
      expect(result.tags.contains('tag1'), false);
    });

    /// Ensures deletion by verse reference works.
    test('deleteByVerse removes matching bookmark', () async {
      final bookmark = createBookmark();

      await dao.insert(bookmark);

      await dao.deleteByVerse(2, 255);

      final result = await dao.getById('1');

      expect(result, isNull);
    });

    /// Tests search functionality against note content.
    test('search finds bookmark by note', () async {
      final bookmarkWithLongNote = createBookmark(note: 'important verse');
      final bookmarkWithExactWord = createBookmark(id: '2', note: 'important');
      final bookmarkWithPartialWord = createBookmark(id: '3', note: 'import');
      final bookmarkWithoutMatch = createBookmark(id: '4');

      await dao.insert(bookmarkWithLongNote);
      await dao.insert(bookmarkWithExactWord);
      await dao.insert(bookmarkWithPartialWord);
      await dao.insert(bookmarkWithoutMatch);

      final upperCaseResults = await dao.search('IMPortant');
      final lowerCaseResults = await dao.search('important');
      final noMatchResults = await dao.search('important Ne');

      expect(upperCaseResults.length, 2);
      expect(lowerCaseResults.length, 2);
      expect(noMatchResults, isEmpty);
    });

    /// Tests search functionality against tags.
    test('search finds bookmark by tag', () async {
      final bookmarkWithTag = createBookmark(tags: ['tafseer']);
      final bookmarkWithUpperTag = createBookmark(id: '2', tags: ['TAFSEER']);
      final bookmarkWithoutMatch = createBookmark(id: '3', tags: ['fiqh']);

      await dao.insert(bookmarkWithTag);
      await dao.insert(bookmarkWithUpperTag);
      await dao.insert(bookmarkWithoutMatch);

      final lowerCaseResults = await dao.search('tafseer');
      final upperCaseResults = await dao.search('TAFSEER');
      final noMatchResults = await dao.search('hadith');

      expect(lowerCaseResults.length, 2);
      expect(lowerCaseResults.first.tags.contains('tafseer'), true);
      expect(upperCaseResults.length, 2);
      expect(upperCaseResults.first.tags.contains('tafseer'), true);

      expect(noMatchResults, isEmpty);
    });

    /// Tests search using verse reference format (e.g., "2:255").
    test('search finds bookmark by verse reference', () async {
      final bookmark1 = createBookmark(); // 2:255
      final bookmark2 = createBookmark(id: '2', chapter: 3, verse: 7);
      final bookmark3 = createBookmark(id: '3', chapter: 2, verse: 1);

      await dao.insert(bookmark1);
      await dao.insert(bookmark2);
      await dao.insert(bookmark3);

      final exactMatchResults = await dao.search('2:255');
      final partialMatchResults = await dao.search('2:');
      final noMatchResults = await dao.search('5:10');

      expect(exactMatchResults.length, 1);
      expect(exactMatchResults.first.verseReference, '2:255');

      expect(partialMatchResults.length, 2);
      expect(noMatchResults, isEmpty);
    });
  });
}
