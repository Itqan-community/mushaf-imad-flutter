import '../../domain/models/recitation.dart';
import 'mp3quran/mp3quran_api_client.dart';

/// Provider for all available Quran recitations from mp3quran.net.
///
/// Recitations are fetched dynamically from the mp3quran API (with an
/// on-disk cache handled by [Mp3QuranApiClient]). Prefer the `*Async`
/// methods, which guarantee the list has been loaded before answering.
class RecitationDataProvider {
  RecitationDataProvider._();

  static List<Recitation> _allRecitations = [];
  static bool _isLoaded = false;
  static Future<void>? _loadingFuture;
  static final _apiClient = Mp3QuranApiClient();

  /// Default reciter ID (Abdul Basit Abdul Samad, Mujawwad) when available.
  static const int defaultRecitationId = 51;

  /// Ensures recitations are loaded.
  ///
  /// Concurrent callers share a single in-flight request. If the request
  /// fails, the error is rethrown and the in-flight future is cleared so the
  /// next call can retry.
  static Future<void> ensureLoaded() {
    if (_isLoaded) return Future.value();
    return _loadingFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      _allRecitations = await _apiClient.fetchRecitations();
      _isLoaded = true;
    } finally {
      _loadingFuture = null;
    }
  }

  /// List of all available recitations with timing data.
  static Future<List<Recitation>> getAllRecitationsAsync() async {
    await ensureLoaded();
    return _allRecitations;
  }

  /// Get recitation by ID.
  static Future<Recitation?> getRecitationByIdAsync(int recitationId) async {
    await ensureLoaded();
    return getRecitationById(recitationId);
  }

  /// Search recitations by name (Arabic or English).
  static Future<List<Recitation>> searchRecitationsAsync(
    String query, {
    String languageCode = 'ar',
  }) async {
    await ensureLoaded();
    return searchRecitations(query, languageCode: languageCode);
  }

  /// Get default recitation ([defaultRecitationId], or first available).
  ///
  /// Throws a [StateError] if the API returned no recitations.
  static Future<Recitation> getDefaultRecitationAsync() async {
    await ensureLoaded();
    final recitation = getDefaultRecitation();
    if (recitation == null) {
      throw StateError('No recitations available from MP3Quran');
    }
    return recitation;
  }

  // --- Synchronous accessors.
  // These only read the in-memory cache and do NOT trigger a load. They
  // return empty/null until [ensureLoaded] has completed successfully.

  /// Whether recitations have been loaded into memory.
  static bool get isLoaded => _isLoaded;

  /// Cached recitations (empty until [ensureLoaded] completes).
  static List<Recitation> get allRecitations =>
      List.unmodifiable(_allRecitations);

  /// Cached lookup by ID (null until [ensureLoaded] completes).
  static Recitation? getRecitationById(int recitationId) {
    for (final r in _allRecitations) {
      if (r.id == recitationId) return r;
    }
    return null;
  }

  /// Cached search (empty until [ensureLoaded] completes).
  static List<Recitation> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return _allRecitations.where((recitation) {
      if (languageCode == 'ar') {
        return recitation.reciter.nameArabic.contains(normalizedQuery) ||
            recitation.riwayah.nameArabic.contains(normalizedQuery);
      }
      return recitation.reciter.nameEnglish.toLowerCase().contains(
            normalizedQuery,
          ) ||
          recitation.riwayah.nameEnglish.toLowerCase().contains(
            normalizedQuery,
          );
    }).toList();
  }

  /// Cached default recitation, or null if nothing has been loaded yet.
  static Recitation? getDefaultRecitation() {
    if (_allRecitations.isEmpty) return null;
    return getRecitationById(defaultRecitationId) ?? _allRecitations.first;
  }
}
