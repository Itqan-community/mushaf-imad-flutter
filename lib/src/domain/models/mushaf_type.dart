/// Supported Mushaf layouts that alter how verses map to pages.
/// Public API - exposed to library consumers.
enum MushafType {
  /// Modern layout (1441 Hijri)
  hafs_1441,

  /// Traditional layout (1405 Hijri)
  hafs_1405,

  /// Madani Mushaf layout (1421 Hijri)
  hafs_1421,
}

/// Extension methods for MushafType
extension MushafTypeExtension on MushafType {
  /// Get the display name for this Mushaf type
  String get displayName {
    switch (this) {
      case MushafType.hafs_1441:
        return 'Hafs 1441';
      case MushafType.hafs_1405:
        return 'Hafs 1405';
      case MushafType.hafs_1421:
        return 'Hafs 1421';
    }
  }

  /// Get the asset directory name for images
  String get imageDirectory {
    switch (this) {
      case MushafType.hafs_1441:
        return 'quran-images';
      case MushafType.hafs_1405:
        return 'quran-images-1405';
      case MushafType.hafs_1421:
        return 'quran-images-1421';
    }
  }

  /// Get the font family name for this Mushaf type
  String get fontFamily {
    switch (this) {
      case MushafType.hafs_1441:
        return 'QuranNumbers';
      case MushafType.hafs_1405:
        return 'QuranNumbers1405';
      case MushafType.hafs_1421:
        return 'QuranNumbers1421';
    }
  }
}
