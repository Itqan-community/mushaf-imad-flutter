import 'package:flutter/widgets.dart' show ImageProvider;

import 'mushaf_type.dart';
import '../../data/quran/mushaf_asset_provider.dart';

/// Configuration for a Mushaf variant — centralizes asset resolution,
/// page counts, and marker/highlight field names so the UI never
/// branches on [MushafType].
///
/// Public API — exposed to library consumers.
class MushafConfig {
  /// The Mushaf variant this config describes.
  final MushafType type;

  /// Provider that resolves line-per-image PNGs to Flutter [ImageProvider]s.
  final MushafAssetProvider assetProvider;

  /// Total number of pages in this Mushaf.
  final int totalPages;

  /// JSON key used for verse markers in the verse-data JSON.
  final String markerField;

  /// JSON key used for highlight regions in the verse-data JSON.
  final String highlightsField;

  /// Asset path for the verse-data JSON bundle.
  final String verseDataPath;

  const MushafConfig({
    required this.type,
    required this.assetProvider,
    required this.totalPages,
    required this.markerField,
    required this.highlightsField,
    this.verseDataPath = 'packages/imad_flutter/assets/quran_verse_data.json',
  });

  /// Convenience: resolve the image provider for a single line.
  ImageProvider lineImageProvider(int page, int line) =>
      assetProvider.resolveLineImage(page, line);
}

/// Registry of all supported Mushaf configurations.
///
/// Add new variants here to make them available throughout the library.
/// External asset providers (e.g. for 1405) are registered via
/// [registerAssetProvider] so the consumer controls where images come from.
class MushafConfigRegistry {
  MushafConfigRegistry._();

  /// The default Mushaf configuration — Hafs 1441, always available.
  static const MushafType defaultType = MushafType.hafs1441;

  /// Built-in configurations. These never change.
  static final Map<MushafType, MushafConfig> _configs = {
    MushafType.hafs1441: MushafConfig(
      type: MushafType.hafs1441,
      assetProvider: const FlutterAssetProvider(
        package: 'imad_flutter',
        assetDirectory: 'quran-images',
      ),
      totalPages: 604,
      markerField: 'marker1441',
      highlightsField: 'highlights1441',
    ),
  };

  // ---------------------------------------------------------------------------
  // External variants are built lazily when their asset provider is registered.
  // ---------------------------------------------------------------------------

  static final Map<MushafType, MushafAssetProvider> _externalAssetProviders =
      {};

  static final Map<MushafType, MushafConfig> _externalConfigs = {};

  /// Register an external [MushafAssetProvider] for a non-default Mushaf.
  ///
  /// Must be called before the Mushaf is used for display. The default
  /// 1441 Hafs Mushaf is always available and does not need registration.
  ///
  /// Example:
  /// ```dart
  /// MushafConfigRegistry.registerAssetProvider(
  ///   MushafType.hafs1405,
  ///   FileAssetProvider(rootDirectory: '/storage/quran-images-1405'),
  /// );
  /// ```
  static void registerAssetProvider(
    MushafType type,
    MushafAssetProvider provider,
  ) {
    assert(
      type != MushafType.hafs1441,
      'hafs1441 asset provider cannot be overridden',
    );
    _externalAssetProviders[type] = provider;
    _externalConfigs.remove(type); // invalidate any cached config
  }

  /// Check whether a [MushafType] has an asset provider registered.
  static bool isAvailable(MushafType type) {
    if (type == MushafType.hafs1441) return true;
    return _externalAssetProviders.containsKey(type);
  }

  /// Get the config for a specific [MushafType].
  ///
  /// Throws [StateError] if the Mushaf has no registered asset provider
  /// (i.e., the developer has not called [registerAssetProvider] for it).
  static MushafConfig configFor(MushafType type) {
    // Built-in configs
    if (_configs.containsKey(type)) return _configs[type]!;

    // External configs — build lazily from registered provider
    final provider = _externalAssetProviders[type];
    if (provider == null) {
      throw StateError(
        'No asset provider registered for $type. '
        'Call MushafConfigRegistry.registerAssetProvider($type, ...) '
        'before using this Mushaf variant.',
      );
    }

    // Cache the config after first build
    if (!_externalConfigs.containsKey(type)) {
      _externalConfigs[type] = _buildExternalConfig(type, provider);
    }
    return _externalConfigs[type]!;
  }

  /// Get the default config (hafs1441).
  static MushafConfig get defaultConfig => configFor(defaultType);

  /// Build a config for an external Mushaf variant from its provider.
  static MushafConfig _buildExternalConfig(
    MushafType type,
    MushafAssetProvider provider,
  ) {
    switch (type) {
      case MushafType.hafs1405:
        return MushafConfig(
          type: MushafType.hafs1405,
          assetProvider: provider,
          totalPages: 604,
          markerField: 'marker1405',
          highlightsField: 'highlights1405',
        );
      case MushafType.hafs1441:
        // Should never reach here — built-in config handles this.
        throw StateError('hafs1441 is a built-in config');
    }
  }
}
