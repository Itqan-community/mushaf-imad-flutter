import 'dart:async';

import '../../domain/models/recitation.dart';
import 'recitation_data_provider.dart';

/// Service for managing recitation selection and persistence.
/// Internal implementation.
class RecitationService {
  Recitation? _selectedRecitation;
  final StreamController<Recitation?> _selectedRecitationController =
      StreamController<Recitation?>.broadcast();

  RecitationService();

  /// Get all available recitations.
  Future<List<Recitation>> getAllRecitations() =>
      RecitationDataProvider.getAllRecitationsAsync();

  /// Get recitation by ID.
  Future<Recitation?> getRecitationById(int recitationId) =>
      RecitationDataProvider.getRecitationByIdAsync(recitationId);

  /// Search recitations.
  Future<List<Recitation>> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) => RecitationDataProvider.searchRecitationsAsync(
    query,
    languageCode: languageCode,
  );

  /// Get default recitation.
  Future<Recitation> getDefaultRecitation() =>
      RecitationDataProvider.getDefaultRecitationAsync();

  /// Get selected recitation.
  Recitation? get selectedRecitation => _selectedRecitation;

  /// Select a recitation and persist.
  void selectRecitation(Recitation recitation) {
    _selectedRecitation = recitation;
    _selectedRecitationController.add(recitation);
  }

  /// Stream of selected recitation changes.
  Stream<Recitation?> get selectedRecitationStream =>
      _selectedRecitationController.stream;

  /// Dispose resources.
  void dispose() {
    _selectedRecitationController.close();
  }
}
