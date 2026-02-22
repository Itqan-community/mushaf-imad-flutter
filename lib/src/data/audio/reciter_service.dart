import 'dart:async';

import '../../domain/models/reciter_info.dart';
import 'reciter_data_provider.dart';

/// Service for managing reciter selection and persistence.
/// Internal implementation.
class ReciterService {
  ReciterInfo? _selectedReciter;
  final StreamController<ReciterInfo?> _selectedReciterController =
      StreamController<ReciterInfo?>.broadcast();

  ReciterService();

  /// Get all available reciters.
  List<ReciterInfo> getAllReciters() => ReciterDataProvider.allReciters;

  /// Get reciter by ID.
  ReciterInfo? getReciterById(int reciterId) =>
      ReciterDataProvider.getReciterById(reciterId);

  /// Search reciters by name.
  List<ReciterInfo> searchReciters(
    String query, {
    String languageCode = 'en',
  }) => ReciterDataProvider.searchReciters(query, languageCode: languageCode);

  /// Get all Hafs reciters.
  List<ReciterInfo> getHafsReciters() => ReciterDataProvider.getHafsReciters();

  /// Get default reciter.
  ReciterInfo getDefaultReciter() => ReciterDataProvider.getDefaultReciter();

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
