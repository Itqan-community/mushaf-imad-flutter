import '../../domain/models/chapter.dart';

/// Cache for chapter data to avoid repeated database queries.
/// Internal implementation.
class ChaptersDataCache {
  List<Chapter>? _cachedChapters;

  /// Get cached chapters.
  List<Chapter>? get chapters => _cachedChapters;

  /// Set cached chapters.
  void setChapters(List<Chapter> chapters) {
    _cachedChapters = List.unmodifiable(chapters);
  }

  /// Check if chapters are cached.
  bool get isCached => _cachedChapters != null;

  /// Clear cache.
  void clear() {
    _cachedChapters = null;
  }
}
