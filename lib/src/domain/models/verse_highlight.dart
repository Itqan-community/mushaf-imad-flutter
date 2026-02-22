/// Domain model for Verse highlight rectangle.
/// Contains normalized coordinates (0-1) for selection highlighting.
class VerseHighlight {
  final int line;
  final double left; // Normalized 0-1
  final double right; // Normalized 0-1

  const VerseHighlight({
    required this.line,
    required this.left,
    required this.right,
  });
}
