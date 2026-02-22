import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/repository/bookmark_repository.dart';

/// ViewModel for bookmarks management.
class BookmarksViewModel extends ChangeNotifier {
  final BookmarkRepository _bookmarkRepository;
  StreamSubscription<List<Bookmark>>? _bookmarksSub;

  BookmarksViewModel({required BookmarkRepository bookmarkRepository})
    : _bookmarkRepository = bookmarkRepository;

  // State
  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;

  // Getters
  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  int get bookmarkCount => _bookmarks.length;

  /// Initialize and observe bookmarks.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _bookmarks = await _bookmarkRepository.getAllBookmarks();

    _bookmarksSub = _bookmarkRepository.getAllBookmarksStream().listen((
      bookmarks,
    ) {
      _bookmarks = bookmarks;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Add a bookmark.
  Future<Bookmark> addBookmark({
    required int chapterNumber,
    required int verseNumber,
    required int pageNumber,
    String note = '',
    List<String> tags = const [],
  }) => _bookmarkRepository.addBookmark(
    chapterNumber: chapterNumber,
    verseNumber: verseNumber,
    pageNumber: pageNumber,
    note: note,
    tags: tags,
  );

  /// Delete a bookmark.
  Future<void> deleteBookmark(String id) =>
      _bookmarkRepository.deleteBookmark(id);

  /// Update bookmark note.
  Future<void> updateNote(String id, String note) =>
      _bookmarkRepository.updateBookmarkNote(id, note);

  /// Delete all bookmarks.
  Future<void> deleteAllBookmarks() => _bookmarkRepository.deleteAllBookmarks();

  @override
  void dispose() {
    _bookmarksSub?.cancel();
    super.dispose();
  }
}
