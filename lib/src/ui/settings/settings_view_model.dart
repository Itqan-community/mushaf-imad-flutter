import 'package:flutter/material.dart';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for the unified settings page.
///
/// Exposes preference values, data export/import, and theme config.
class SettingsViewModel extends ChangeNotifier {
  final PreferencesRepository _preferencesRepository;
  final DataExportRepository _dataExportRepository;

  SettingsViewModel({
    required PreferencesRepository preferencesRepository,
    required DataExportRepository dataExportRepository,
  }) : _preferencesRepository = preferencesRepository,
       _dataExportRepository = dataExportRepository {
    _loadPreferences();
  }

  // ─── Data export state ───
  bool _isExporting = false;
  bool _isImporting = false;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;

  // ─── Preferences state ───
  MushafType _mushafType = MushafType.hafs1441;
  int _currentPage = 1;
  int _selectedReciterId = 1;
  double _playbackSpeed = 1.0;
  bool _repeatMode = false;
  ThemeConfig _themeConfig = const ThemeConfig();

  MushafType get mushafType => _mushafType;
  int get currentPage => _currentPage;
  int get selectedReciterId => _selectedReciterId;
  double get playbackSpeed => _playbackSpeed;
  bool get repeatMode => _repeatMode;
  ThemeConfig get themeConfig => _themeConfig;

  /// Load current preference values.
  Future<void> _loadPreferences() async {
    _mushafType = await _preferencesRepository.getMushafTypeStream().first;
    _currentPage = await _preferencesRepository.getCurrentPageStream().first;
    _selectedReciterId = await _preferencesRepository.getSelectedReciterId();
    _playbackSpeed = await _preferencesRepository.getPlaybackSpeed();
    _repeatMode = await _preferencesRepository.getRepeatMode();
    _themeConfig = await _preferencesRepository.getThemeConfig();
    notifyListeners();
  }

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
      final result = await _dataExportRepository.importFromJson(
        jsonData,
        mergeWithExisting: mergeWithExisting,
      );
      await _loadPreferences(); // Refresh after import
      return result;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// Clear all user data.
  Future<void> clearAllData() async {
    await _dataExportRepository.clearAllUserData();
    await _loadPreferences(); // Refresh after clear
    notifyListeners();
  }

  /// Set the Mushaf type and reload preferences
  Future<void> setMushafType(MushafType type) async {
    _mushafType = type;
    await _preferencesRepository.setMushafType(type);
    notifyListeners();
  }
}
