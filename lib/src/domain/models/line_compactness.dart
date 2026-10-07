/// Defines the vertical compactness (spacing) between lines on a Mushaf page.
///
/// Controls how tightly packed consecutive Quran lines appear, allowing
/// developers to customize line margins, spacing, and image overlapping
/// to match different display sizes, layouts, and reading preferences.
class LineCompactness {
  /// The spacing factor between adjacent lines.
  ///
  /// - `1.0`: Lines are stacked edge-to-edge with no overlap.
  /// - `< 1.0`: Lines overlap by their transparent padding and margins, producing more compact lines.
  /// - `> 1.0`: Adds extra space between lines.
  /// - `null`: When [isExpanded] is true, lines stretch to fill the available height.
  final double? spacingFactor;

  /// Whether lines should use the legacy behavior of expanding to fill
  /// the full available vertical height equally.
  final bool isExpanded;

  /// Creates a compactness configuration with a specific numerical [spacingFactor].
  ///
  /// For example, `0.65` means each line step is 65% of line height, creating
  /// a 35% picture overlap between adjacent lines.
  const LineCompactness(double factor)
    : spacingFactor = factor,
      isExpanded = false;

  /// Creates a compactness configuration specifying the picture [overlap] fraction.
  ///
  /// For example, `LineCompactness.withOverlap(0.40)` specifies that adjacent
  /// line pictures overlap by 40% of their height.
  const LineCompactness.withOverlap(double overlap)
    : spacingFactor = 1.0 - overlap,
      isExpanded = false;

  /// Creates a compactness setting from a 0.0 to 2.0 normalized compactness scale:
  /// - `0.0`: loose / no overlap (`spacingFactor = 1.0`)
  /// - `0.5`: normal (`spacingFactor = 0.85`, 15% overlap)
  /// - `1.0`: compact (`spacingFactor = 0.70`, 30% overlap)
  /// - `1.5`: tight (`spacingFactor = 0.55`, 45% overlap)
  /// - `2.0`: ultra-compact (`spacingFactor = 0.40`, 60% overlap)
  factory LineCompactness.fromScale(double scale) {
    final factor = (1.0 - (scale * 0.30)).clamp(0.25, 2.0);
    return LineCompactness(factor);
  }

  const LineCompactness._expanded() : spacingFactor = null, isExpanded = true;

  /// Ultra compact lines — 60% picture overlap, minimum margins between calligraphy.
  /// Spacing factor: 0.40.
  static const LineCompactness ultraCompact = LineCompactness(0.40);

  /// Tight compactness — 45% picture overlap between adjacent lines.
  /// Spacing factor: 0.55.
  static const LineCompactness tight = LineCompactness(0.55);

  /// Compact lines — 30% picture overlap, authentic Mushaf feel.
  /// Spacing factor: 0.70.
  static const LineCompactness compact = LineCompactness(0.70);

  /// Normal compactness — 15% picture overlap, well-balanced default spacing.
  /// Spacing factor: 0.85.
  static const LineCompactness normal = LineCompactness(0.85);

  /// Loose lines — generous spacing between lines with zero overlap.
  /// Spacing factor: 1.0.
  static const LineCompactness loose = LineCompactness(1.0);

  /// Stretches lines equally to fill all available vertical height
  /// (legacy layout behavior).
  static const LineCompactness expanded = LineCompactness._expanded();

  /// Create a custom compactness with a specific spacing factor.
  const LineCompactness.custom(double factor)
    : spacingFactor = factor,
      isExpanded = false;

  /// Effective spacing factor as a non-null double (defaults to 1.0 when expanded).
  double get factor => spacingFactor ?? 1.0;

  /// Fraction of line image height that overlaps with the adjacent line.
  ///
  /// - `0.0`: 0% overlap (lines touch edge-to-edge).
  /// - `0.15`: 15% overlap (normal default).
  /// - `0.30`: 30% overlap (compact).
  /// - `0.45`: 45% overlap (tight).
  /// - `0.60`: 60% overlap (ultra-compact).
  double get overlap => isExpanded ? 0.0 : (1.0 - factor).clamp(0.0, 0.80);

  /// All standard preset values.
  static const List<LineCompactness> values = [
    ultraCompact,
    tight,
    compact,
    normal,
    loose,
    expanded,
  ];

  /// Human-readable identifier for this compactness setting.
  String get name {
    if (isExpanded) return 'expanded';
    if (spacingFactor == 0.40) return 'ultraCompact';
    if (spacingFactor == 0.55) return 'tight';
    if (spacingFactor == 0.70) return 'compact';
    if (spacingFactor == 0.85) return 'normal';
    if (spacingFactor == 1.0) return 'loose';
    return 'custom';
  }

  /// User-friendly label with percentage.
  String get displayName {
    if (isExpanded) return 'Expanded';
    if (spacingFactor == 0.40) return 'Ultra Compact (40%)';
    if (spacingFactor == 0.55) return 'Tight (55%)';
    if (spacingFactor == 0.70) return 'Compact (70%)';
    if (spacingFactor == 0.85) return 'Normal (85%)';
    if (spacingFactor == 1.0) return 'Loose (100%)';
    return 'Custom (${(factor * 100).toInt()}%)';
  }

  /// Parses a [LineCompactness] from a name or number string.
  ///
  /// Supports names ('tight', 'compact', 'ultracompact', etc.) as well
  /// as numbers ('0.70', '70', '70%').
  static LineCompactness fromName(String name) {
    final trimmed = name.trim().toLowerCase().replaceAll('%', '');
    final parsed = double.tryParse(trimmed);
    if (parsed != null) {
      final factor = parsed > 2.0 ? parsed / 100.0 : parsed;
      return LineCompactness(factor);
    }
    return switch (trimmed) {
      'ultracompact' || 'ultra_compact' => ultraCompact,
      'tight' => tight,
      'compact' => compact,
      'normal' => normal,
      'loose' => loose,
      'expanded' => expanded,
      _ => normal,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineCompactness &&
          runtimeType == other.runtimeType &&
          spacingFactor == other.spacingFactor &&
          isExpanded == other.isExpanded;

  @override
  int get hashCode => Object.hash(spacingFactor, isExpanded);

  @override
  String toString() {
    if (isExpanded) return 'LineCompactness.expanded';
    return 'LineCompactness($spacingFactor, overlap: ${(overlap * 100).toInt()}%)';
  }
}
