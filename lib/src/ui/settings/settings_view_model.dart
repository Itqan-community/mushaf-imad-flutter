import 'package:flutter/material.dart';

import '../../domain/models/mushaf_type.dart';
import '../../domain/models/theme.dart';
import '../../domain/repository/data_export_repository.dart';
import '../../domain/repository/preferences_repository.dart';
import '../../domain/services/file_service.dart';

/// ViewModel for the unified settings page.
///
/// Exposes preference values, data export/import, and theme config.
class SettingsViewModel extends ChangeNotifier {
  final PreferencesRepository _preferencesRepository;
  final DataExportRepository _dataExportRepository;
  final FileService? _fileService;

  SettingsViewModel({
    required PreferencesRepository preferencesRepository,
    required DataExportRepository dataExportRepository,
    FileService? fileService,
  }) : _preferencesRepository = preferencesRepository,
       _dataExportRepository = dataExportRepository,
       _fileService = fileService {
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
  bool _showAudioPlayer = true;

  MushafType get mushafType => _mushafType;
  int get currentPage => _currentPage;
  int get selectedReciterId => _selectedReciterId;
  double get playbackSpeed => _playbackSpeed;
  bool get repeatMode => _repeatMode;
  ThemeConfig get themeConfig => _themeConfig;
  bool get showAudioPlayer => _showAudioPlayer;

  /// Load current preference values.
  Future<void> _loadPreferences() async {
    _mushafType = await _preferencesRepository.getMushafTypeStream().first;
    _currentPage = await _preferencesRepository.getCurrentPageStream().first;
    _selectedReciterId = await _preferencesRepository.getSelectedReciterId();
    _playbackSpeed = await _preferencesRepository.getPlaybackSpeed();
    _repeatMode = await _preferencesRepository.getRepeatMode();
    _themeConfig = await _preferencesRepository.getThemeConfig();
    _showAudioPlayer = await _preferencesRepository.getShowAudioPlayer();
    notifyListeners();
  }

  /// Toggle audio player visibility.
  Future<void> setShowAudioPlayer(bool show) async {
    _showAudioPlayer = show;
    notifyListeners();
    await _preferencesRepository.setShowAudioPlayer(show);
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

  /// Export user data and trigger a file download/save dialog.
  Future<String?> exportToFile() async {
    if (_fileService == null) return null;

    final jsonData = await exportData();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'mushaf_backup_$timestamp.json';

    return await _fileService!.saveStringAsFile(
      name: fileName,
      content: jsonData,
      mimeType: 'application/json',
    );
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

  /// Trigger a file picker and import the selected JSON data.
  Future<ImportResult?> importFromFile({bool mergeWithExisting = true}) async {
    if (_fileService == null) return null;

    final picked = await _fileService!.pickFile(
      allowedExtensions: ['json'],
    );

    if (picked != null) {
      return await importData(
        picked.content,
        mergeWithExisting: mergeWithExisting,
      );
    }
    return null;
  }

  /// Clear all user data.
  Future<void> clearAllData() async {
    await _dataExportRepository.clearAllUserData();
    await _loadPreferences(); // Refresh after clear
    notifyListeners();
  }
}
