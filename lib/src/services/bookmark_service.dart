import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing a bookmark
class Bookmark {
  final String id;
  final int surahNumber;
  final int ayahNumber;
  final int? pageNumber;
  final String? surahName;
  final DateTime createdAt;
  final String? note;

  Bookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    this.pageNumber,
    this.surahName,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
      'surahName': surahName,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      surahNumber: json['surahNumber'],
      ayahNumber: json['ayahNumber'],
      pageNumber: json['pageNumber'],
      surahName: json['surahName'],
      createdAt: DateTime.parse(json['createdAt']),
      note: json['note'],
    );
  }

  Bookmark copyWith({
    String? id,
    int? surahNumber,
    int? ayahNumber,
    int? pageNumber,
    String? surahName,
    DateTime? createdAt,
    String? note,
  }) {
    return Bookmark(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      surahName: surahName ?? this.surahName,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}

/// Service for managing bookmarks
class BookmarkService {
  static const String _storageKey = 'mushaf_bookmarks';
  
  List<Bookmark> _bookmarks = [];
  
  /// Get all bookmarks sorted by creation date (newest first)
  List<Bookmark> get bookmarks => 
    List.unmodifiable(_bookmarks..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// Load bookmarks from storage
  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString(_storageKey);
    
    if (bookmarksJson != null) {
      final List<dynamic> decoded = jsonDecode(bookmarksJson);
      _bookmarks = decoded.map((json) => Bookmark.fromJson(json)).toList();
    }
  }

  /// Save bookmarks to storage
  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String bookmarksJson = jsonEncode(
      _bookmarks.map((b) => b.toJson()).toList(),
    );
    await prefs.setString(_storageKey, bookmarksJson);
  }

  /// Add a new bookmark
  Future<Bookmark> addBookmark({
    required int surahNumber,
    required int ayahNumber,
    int? pageNumber,
    String? surahName,
    String? note,
  }) async {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
      surahName: surahName,
      createdAt: DateTime.now(),
      note: note,
    );
    
    _bookmarks.add(bookmark);
    await _saveBookmarks();
    return bookmark;
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks();
  }

  /// Update bookmark note
  Future<void> updateBookmarkNote(String id, String? note) async {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookmarks[index] = _bookmarks[index].copyWith(note: note);
      await _saveBookmarks();
    }
  }

  /// Check if an ayah is bookmarked
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarks.any(
      (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
    );
  }

  /// Get bookmark for specific ayah
  Bookmark? getBookmark(int surahNumber, int ayahNumber) {
    try {
      return _bookmarks.firstWhere(
        (b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear all bookmarks
  Future<void> clearAll() async {
    _bookmarks.clear();
    await _saveBookmarks();
  }

  /// Get bookmark count
  int get bookmarkCount => _bookmarks.length;
}
