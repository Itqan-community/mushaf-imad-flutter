/// Statistics about the current cache state.
/// Public API - exposed to library consumers.
class CacheStats {
  final int cachedPagesCount;
  final int cachedChaptersCount;
  final int totalVersesCached;

  const CacheStats({
    required this.cachedPagesCount,
    required this.cachedChaptersCount,
    required this.totalVersesCached,
  });
}
