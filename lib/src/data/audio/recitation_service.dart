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
  List<Recitation> getAllRecitations() => RecitationDataProvider.allRecitations;

  /// Get recitation by ID.
  Recitation? getRecitationById(int recitationId) =>
      RecitationDataProvider.getRecitationById(recitationId);

  /// Search recitations.
  List<Recitation> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) => RecitationDataProvider.searchRecitations(query, languageCode: languageCode);

  /// Get default recitation.
  Recitation getDefaultRecitation() => RecitationDataProvider.getDefaultRecitation();

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
