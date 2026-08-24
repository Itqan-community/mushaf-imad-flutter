import 'dart:io';

import 'package:flutter/widgets.dart';

/// Provides an [ImageProvider] for a single Quran line image.
///
/// Separates asset sourcing from rendering so the UI never cares whether
/// a line-per-image PNG comes from the bundled package, an external
/// filesystem directory, a network download, or any future source.
///
/// Public API — exposed to library consumers.
abstract class MushafAssetProvider {
  /// Resolve the [ImageProvider] for a page/line image.
  ///
  /// [page] is 1-indexed (1-604 for Hafs variants).
  /// [line] is 1-indexed (1-15 per page).
  ImageProvider resolveLineImage(int page, int line);

  /// Human-readable description for debugging.
  String get description;
}

// ---------------------------------------------------------------------------
// Bundled Flutter asset provider (default for hafs1441)
// ---------------------------------------------------------------------------

/// Loads line images from the package's bundled Flutter assets.
///
/// This is the default provider for [MushafType.hafs1441] and works
/// with zero developer configuration. Images are resolved from
/// `assets/{assetDirectory}/{page}/{line}.png` within the package.
class FlutterAssetProvider implements MushafAssetProvider {
  /// The package name used with [AssetImage] (typically 'imad_flutter').
  final String package;

  /// Subdirectory under `assets/` where line images live (e.g. 'quran-images').
  final String assetDirectory;

  const FlutterAssetProvider({
    required this.package,
    required this.assetDirectory,
  });

  @override
  ImageProvider resolveLineImage(int page, int line) =>
      AssetImage('assets/$assetDirectory/$page/$line.png', package: package);

  @override
  String get description => 'FlutterAssetProvider($package, $assetDirectory)';
}

// ---------------------------------------------------------------------------
// External filesystem provider (for developer-downloaded Mushaf variants)
// ---------------------------------------------------------------------------

/// Loads line images from an external filesystem directory.
///
/// Use this provider for Mushaf variants whose images are distributed
/// outside the pub.dev package (e.g. via GitHub Releases). The consumer
/// downloads and extracts the image bundle to a local directory, then
/// registers this provider pointing at that directory.
///
/// The directory is expected to contain subdirectories `1/` through
/// `{totalPages}/`, each with 15 line PNGs named `1.png` through `15.png`.
///
/// Example for a GitHub-downloaded 1405 Mushaf:
/// ```dart
/// MushafLibrary.registerMushafAssetProvider(
///   MushafType.hafs1405,
///   FileAssetProvider(
///     rootDirectory: '/storage/quran-images-1405',
///   ),
/// );
/// ```
class FileAssetProvider implements MushafAssetProvider {
  /// Absolute or relative path to the root directory containing
  /// page-numbered subdirectories.
  final String rootDirectory;

  const FileAssetProvider({required this.rootDirectory});

  @override
  ImageProvider resolveLineImage(int page, int line) =>
      FileImage(File('$rootDirectory/$page/$line.png'));

  @override
  String get description => 'FileAssetProvider($rootDirectory)';
}
