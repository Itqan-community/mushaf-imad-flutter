import 'package:flutter/material.dart';

import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for settings.
class SettingsViewModel extends ChangeNotifier {
  // ignore: unused_field
  final PreferencesRepository _preferencesRepository;
  final DataExportRepository _dataExportRepository;

  SettingsViewModel({
    required PreferencesRepository preferencesRepository,
    required DataExportRepository dataExportRepository,
  }) : _preferencesRepository = preferencesRepository,
       _dataExportRepository = dataExportRepository;

  // State
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastExportPath;

  // Getters
  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  String? get lastExportPath => _lastExportPath;

  /// Export user data to JSON.
  Future<String> exportData() async {
    _isExporting = true;
    notifyListeners();

    try {
      return await _dataExportRepository.exportToJson();
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Import user data from JSON.
  Future<ImportResult> importData(
    String jsonData, {
    bool mergeWithExisting = true,
  }) async {
    _isImporting = true;
    notifyListeners();

    try {
      return await _dataExportRepository.importFromJson(
        jsonData,
        mergeWithExisting: mergeWithExisting,
      );
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// Clear all user data.
  Future<void> clearAllData() async {
    await _dataExportRepository.clearAllUserData();
    notifyListeners();
  }
}
