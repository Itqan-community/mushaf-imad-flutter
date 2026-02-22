import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/theme.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for theme management.
class ThemeViewModel extends ChangeNotifier {
  final PreferencesRepository _preferencesRepository;
  StreamSubscription<ThemeConfig>? _themeSubscription;

  ThemeViewModel({required PreferencesRepository preferencesRepository})
    : _preferencesRepository = preferencesRepository;

  // State
  ThemeConfig _themeConfig = const ThemeConfig();

  // Getters
  ThemeConfig get themeConfig => _themeConfig;
  MushafThemeMode get themeMode => _themeConfig.mode;
  MushafColorScheme get colorScheme => _themeConfig.colorScheme;
  bool get useAmoled => _themeConfig.useAmoled;

  /// Initialize theme ViewModel.
  Future<void> initialize() async {
    _themeConfig = await _preferencesRepository.getThemeConfig();
    notifyListeners();

    _themeSubscription = _preferencesRepository.getThemeConfigStream().listen((
      config,
    ) {
      _themeConfig = config;
      notifyListeners();
    });
  }

  /// Set theme mode.
  Future<void> setThemeMode(MushafThemeMode mode) async {
    await _preferencesRepository.setThemeMode(mode);
  }

  /// Set color scheme.
  Future<void> setColorScheme(MushafColorScheme scheme) async {
    await _preferencesRepository.setColorScheme(scheme);
  }

  /// Set AMOLED mode.
  Future<void> setAmoledMode(bool enabled) async {
    await _preferencesRepository.setAmoledMode(enabled);
  }

  @override
  void dispose() {
    _themeSubscription?.cancel();
    super.dispose();
  }
}
