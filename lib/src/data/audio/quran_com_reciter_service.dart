import 'dart:async';

import '../../domain/models/reciter_info.dart';
import 'quran_com_audio_service.dart';
import 'reciter_data_provider.dart';

/// Service for managing reciter selection with Quran.com API integration.
/// Falls back to local data provider when API is unavailable.
class ReciterService {
  final AudioService? _audioService;
  ReciterInfo? _selectedReciter;
  final StreamController<ReciterInfo?> _selectedReciterController =
      StreamController<ReciterInfo?>.broadcast();
  
  // Cache for API reciters
  List<ReciterInfo>? _cachedApiReciters;
  bool _useApi = true;

  ReciterService({AudioService? audioService})
      : _audioService = audioService;

  /// Whether to use Quran.com API (true) or local data (false).
  bool get useApi => _useApi;
  
  /// Set whether to use Quran.com API.
  set useApi(bool value) {
    _useApi = value;
    if (!value) {
      _cachedApiReciters = null;
    }
  }

  /// Get all available reciters.
  /// Tries API first, falls back to local data on failure.
  Future<List<ReciterInfo>> getAllReciters() async {
    if (_useApi && _audioService != null) {
      try {
        if (_cachedApiReciters != null) {
          return _cachedApiReciters!;
        }
        
        final reciters = await _audioService!.fetchAllReciters();
        _cachedApiReciters = reciters;
        return reciters;
      } on QuranComApiException catch (e) {
        // Log error and fall back to local data
        print('[ReciterService] API error, using local data: $e');
        return ReciterDataProvider.allReciters;
      }
    }
    return ReciterDataProvider.allReciters;
  }

  /// Get reciter by ID.
  /// Tries API first, falls back to local data on failure.
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    if (_useApi && _audioService != null) {
      try {
        // Check cache first
        if (_cachedApiReciters != null) {
          return _cachedApiReciters!.firstWhere(
            (r) => r.id == reciterId,
            orElse: () => ReciterDataProvider.getReciterById(reciterId)!,
          );
        }
        
        final reciter = await _audioService!.getReciterById(reciterId);
        if (reciter != null) {
          return reciter;
        }
      } on QuranComApiException catch (e) {
        print('[ReciterService] API error, using local data: $e');
      }
    }
    return ReciterDataProvider.getReciterById(reciterId);
  }

  /// Search reciters by name.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    if (_useApi && _audioService != null) {
      try {
        return await _audioService!.searchReciters(query, languageCode: languageCode);
      } on QuranComApiException catch (e) {
        print('[ReciterService] API error, using local data: $e');
      }
    }
    return ReciterDataProvider.searchReciters(query, languageCode: languageCode);
  }

  /// Get all Hafs reciters.
  Future<List<ReciterInfo>> getHafsReciters() async {
    final allReciters = await getAllReciters();
    return allReciters.where((r) => r.isHafs).toList();
  }

  /// Get default reciter.
  Future<ReciterInfo> getDefaultReciter() async {
    if (_useApi && _audioService != null) {
      try {
        return await _audioService!.getDefaultReciter();
      } on QuranComApiException catch (e) {
        print('[ReciterService] API error, using local data: $e');
      }
    }
    return ReciterDataProvider.getDefaultReciter();
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

  /// Clear the API cache.
  void clearCache() {
    _cachedApiReciters = null;
    _audioService?.clearCache();
  }

  /// Dispose resources.
  void dispose() {
    _selectedReciterController.close();
    _audioService?.dispose();
  }
}
