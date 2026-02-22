/// Domain model for Verse number marker position.
/// Contains normalized coordinates (0-1) for verse number placement.
class VerseMarker {
  final String numberCodePoint;
  final int line;
  final double centerX; // Normalized 0-1
  final double centerY; // Normalized 0-1

  const VerseMarker({
    required this.numberCodePoint,
    required this.line,
    required this.centerX,
    required this.centerY,
  });
}
