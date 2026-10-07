import '../../domain/models/recitation.dart';
import '../../domain/models/reciter.dart';
import '../../domain/models/riwayah.dart';
import 'mp3quran/mp3quran_api_client.dart';

/// Provider for all available Quran recitations from mp3quran.net.
class RecitationDataProvider {
  RecitationDataProvider._();

  static List<Recitation> _allRecitations = [];
  static bool _isLoaded = false;
  static final _apiClient = Mp3QuranApiClient();

  /// Ensure recitations are loaded
  static Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    try {
      _allRecitations = await _apiClient.fetchRecitations();
      _isLoaded = true;
    } catch (e) {
      // Fallback to empty or simple list if network fails and cache is empty
      _allRecitations = [];
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
    try {
      return _allRecitations.firstWhere((r) => r.id == recitationId);
    } catch (_) {
      return null;
    }
  }

  /// Search recitations by name (Arabic or English).
  static Future<List<Recitation>> searchRecitationsAsync(
    String query, {
    String languageCode = 'ar',
  }) async {
    await ensureLoaded();
    final normalizedQuery = query.trim().toLowerCase();
    return _allRecitations.where((recitation) {
      if (languageCode == 'ar') {
        return recitation.reciter.nameArabic.contains(normalizedQuery) ||
            recitation.riwayah.nameArabic.contains(normalizedQuery);
      }
      return recitation.reciter.nameEnglish.toLowerCase().contains(
            normalizedQuery,
          ) ||
          (recitation.riwayah.nameEnglish.toLowerCase().contains(
            normalizedQuery,
          ));
    }).toList();
  }

  /// Get default recitation (e.g. Abdul Basit Mujawwad ID 51, or first available).
  static Future<Recitation> getDefaultRecitationAsync() async {
    await ensureLoaded();
    if (_allRecitations.isEmpty) {
      throw Exception('No recitations loaded from MP3Quran');
    }
    // Try to find Abdul Basit Mujawwad (51) as default, otherwise pick first
    try {
      return _allRecitations.firstWhere((r) => r.id == 51);
    } catch (_) {
      return _allRecitations.first;
    }
  }

  // --- Synchronous versions for backward compatibility in places that need them immediately.
  // Note: These will return empty/null if ensureLoaded() hasn't completed yet.

  static List<Recitation> get allRecitations => _allRecitations;

  static Recitation? getRecitationById(int recitationId) {
    try {
      return _allRecitations.firstWhere((r) => r.id == recitationId);
    } catch (_) {
      return null;
    }
  }

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
          (recitation.riwayah.nameEnglish.toLowerCase().contains(
            normalizedQuery,
          ));
    }).toList();
  }

  static Recitation getDefaultRecitation() {
    if (_allRecitations.isEmpty) {
      // Return a dummy to prevent crashes before load
      return const Recitation(
        id: 51,
        reciter: Reciter(
          id: 51,
          nameArabic: 'جاري التحميل...',
          nameEnglish: 'Loading...',
        ),
        riwayah: Riwayah(id: 1, nameArabic: '', nameEnglish: ''),
      );
    }
    try {
      return _allRecitations.firstWhere((r) => r.id == 51);
    } catch (_) {
      return _allRecitations.first;
    }
  }
}
