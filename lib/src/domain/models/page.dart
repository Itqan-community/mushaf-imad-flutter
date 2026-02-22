/// Domain model for Quran Page.
/// Public API - exposed to library consumers.
class Page {
  final int identifier;
  final int number;
  final bool isRight;

  const Page({
    required this.identifier,
    required this.number,
    required this.isRight,
  });
}
