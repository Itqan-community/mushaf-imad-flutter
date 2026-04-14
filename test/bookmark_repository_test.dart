import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'dart:io';

// Fake audio player so AudioService.init is never called in tests
class _FakeFlutterAudioPlayer implements FlutterAudioPlayer {
  @override
  Stream<AudioPlayerState> get domainStateStream => const Stream.empty();

  @override
  Future<void> loadFromUrl(
    String url, {
    int chapterNumber = 0,
    ReciterInfo? reciter,
    bool autoPlay = false,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BookmarkRepository repository;

  setUpAll(() async {
    // Mock path_provider (used by Hive.initFlutter)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => Directory.systemTemp.path,
        );
      // Initialize the library using the fake audio player (skips AudioService.init)
    await MushafLibrary.initialize(
      audioPlayer: _FakeFlutterAudioPlayer(),
    );
    repository = MushafLibrary.getBookmarkRepository();
  });

  setUp(() async {
    await repository.deleteAllBookmarks();
  });

  test('Add bookmark should store bookmark', () async {
    await repository.addBookmark(
      chapterNumber: 1,
      verseNumber: 1,
      pageNumber: 1,
    );
    final bookmarks = await repository.getAllBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.pageNumber, 1);
  });

  test('Delete bookmark should remove bookmark', () async {
    final bookmark = await repository.addBookmark(
      chapterNumber: 1,
      verseNumber: 2,
      pageNumber: 5,
    );
    await repository.deleteBookmark(bookmark.id);
    final bookmarks = await repository.getAllBookmarks();
    expect(bookmarks.isEmpty, true);
  });

  test('isVerseBookmarked should return true if bookmarked', () async {
    await repository.addBookmark(
      chapterNumber: 2,
      verseNumber: 10,
      pageNumber: 30,
    );
    final result = await repository.isVerseBookmarked(2, 10);
    expect(result, true);
  });
}
