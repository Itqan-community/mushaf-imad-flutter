import 'dart:async';

import '../../domain/models/reciter_info.dart';
import 'audio_source_config.dart';

/// Service for managing reciter selection and persistence.
/// Internal implementation.
class ReciterService {
  final MushafAudioDataSource _audioDataSource;
  ReciterInfo? _selectedReciter;
  List<ReciterInfo>? _recitersCache;
  final StreamController<ReciterInfo?> _selectedReciterController =
      StreamController<ReciterInfo?>.broadcast();

  ReciterService(this._audioDataSource);

  /// Get all available reciters.
  Future<List<ReciterInfo>> getAllReciters() async {
    _recitersCache ??= await _audioDataSource.fetchAllReciters();
    return _recitersCache!;
  }

  /// Get reciter by ID.
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    final all = await getAllReciters();
    try {
      return all.firstWhere((r) => r.id == reciterId);
    } catch (_) {
      return null;
    }
  }

  /// Search reciters by name.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    final all = await getAllReciters();
    final normalizedQuery = query.trim().toLowerCase();

    return all.where((reciter) {
      if (languageCode == 'ar') {
        return reciter.nameArabic.contains(normalizedQuery);
      }
      return reciter.nameEnglish.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Get all Hafs reciters.
  Future<List<ReciterInfo>> getHafsReciters() async {
    final all = await getAllReciters();
    return all.where((r) => r.isHafs).toList();
  }

  /// Get default reciter.
  Future<ReciterInfo> getDefaultReciter() async {
    final all = await getAllReciters();
    if (all.isEmpty) {
      throw StateError('No reciters available');
    }
    return all.first;
  }

  /// Get chapter audio URL (if provided by source).
  Future<String?> getChapterAudioUrl(int reciterId, int chapterNumber) {
    return _audioDataSource.fetchChapterAudioUrl(reciterId, chapterNumber);
  }

  /// Get selected reciter.
  ReciterInfo? get selectedReciter => _selectedReciter;

  /// Select a reciter and persist.
  void selectReciter(ReciterInfo reciter) {
    _selectedReciter = reciter;
    _selectedReciterController.add(reciter);
  }

  /// Stream of selected reciter changes.
  Stream<ReciterInfo?> get selectedReciterStream =>
      _selectedReciterController.stream;

  /// Dispose resources.
  void dispose() {
    _selectedReciterController.close();
  }
}
