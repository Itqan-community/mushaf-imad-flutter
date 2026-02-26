import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/mushaf_type.dart';

/// Service for managing and loading Mushaf-specific fonts.
/// 
/// Handles font loading for different Mushaf types (1441, 1405, 1421)
/// and provides font family names for text rendering.
class MushafFontService {
  static final MushafFontService _instance = MushafFontService._internal();
  factory MushafFontService() => _instance;
  MushafFontService._internal();

  // Font family names
  static const String _defaultFontFamily = 'QuranNumbers';
  static const String _hafs1405FontFamily = 'QuranNumbers1405';
  static const String _hafs1421FontFamily = 'Hafs1421';

  // Font loading state
  bool _is1405FontLoaded = false;
  bool _is1421FontLoaded = false;
  
  bool get is1405FontLoaded => _is1405FontLoaded;
  bool get is1421FontLoaded => _is1421FontLoaded;

  /// Initialize the font service.
  Future<void> initialize() async {
    // Pre-load fonts if needed
    await loadFontForMushafType(MushafType.hafs_1421);
    await loadFontForMushafType(MushafType.hafs_1405);
  }

  /// Load font for a specific Mushaf type.
  Future<void> loadFontForMushafType(MushafType mushafType) async {
    switch (mushafType) {
      case MushafType.hafs_1421:
        await _loadHafs1421Font();
        break;
      case MushafType.hafs_1405:
        await _loadHafs1405Font();
        break;
      case MushafType.hafs_1441:
        // Default fonts are bundled with the app
        break;
    }
  }

  /// Get the appropriate font family for a Mushaf type.
  String getFontFamily(MushafType mushafType) {
    switch (mushafType) {
      case MushafType.hafs_1421:
        return _hafs1421FontFamily;
      case MushafType.hafs_1405:
        return _hafs1405FontFamily;
      case MushafType.hafs_1441:
        return _defaultFontFamily;
    }
  }

  /// Get font size adjustment for a Mushaf type.
  double getFontSizeMultiplier(MushafType mushafType) {
    switch (mushafType) {
      case MushafType.hafs_1421:
        return 1.0; // 1421 uses standard size
      case MushafType.hafs_1441:
        return 1.0;
      case MushafType.hafs_1405:
        return 1.05; // 1405 fonts are slightly smaller
    }
  }

  /// Get line height adjustment for a Mushaf type.
  double getLineHeightMultiplier(MushafType mushafType) {
    switch (mushafType) {
      case MushafType.hafs_1421:
        return 1.0;
      case MushafType.hafs_1441:
        return 1.0;
      case MushafType.hafs_1405:
        return 1.1;
    }
  }

  /// Load the Hafs 1405 font from assets.
  Future<void> _loadHafs1405Font() async {
    if (_is1405FontLoaded) return;

    try {
      final fontData = await rootBundle.load(
        'packages/imad_flutter/assets/fonts/hafs_1405/QuranNumbers1405.ttf',
      );
      
      final fontLoader = FontLoader(_hafs1405FontFamily);
      fontLoader.addFont(Future.value(fontData));
      await fontLoader.load();
      
      _is1405FontLoaded = true;
    } catch (e) {
      // Font not available yet, use fallback
      debugPrint('Hafs 1405 font not loaded: $e');
      _is1405FontLoaded = false;
    }
  }

  /// Load the Hafs 1421 font from assets.
  Future<void> _loadHafs1421Font() async {
    if (_is1421FontLoaded) return;

    try {
      final fontData = await rootBundle.load(
        'packages/imad_flutter/assets/fonts/1421/Hafs1421.ttf',
      );
      
      final fontLoader = FontLoader(_hafs1421FontFamily);
      fontLoader.addFont(Future.value(fontData));
      await fontLoader.load();
      
      _is1421FontLoaded = true;
    } catch (e) {
      // Font not available yet, use fallback
      debugPrint('Hafs 1421 font not loaded: $e');
      _is1421FontLoaded = false;
    }
  }

  /// Check if a font is available for the Mushaf type.
  bool isFontAvailable(MushafType mushafType) {
    switch (mushafType) {
      case MushafType.hafs_1421:
        return _is1421FontLoaded;
      case MushafType.hafs_1405:
        return _is1405FontLoaded;
      case MushafType.hafs_1441:
        return true; // Always available
    }
  }

  /// Dispose resources.
  void dispose() {
    _is1405FontLoaded = false;
    _is1421FontLoaded = false;
  }
}
