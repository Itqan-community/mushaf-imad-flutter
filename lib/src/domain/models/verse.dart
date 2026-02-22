import 'verse_marker.dart';
import 'verse_highlight.dart';

/// Domain model for Quran Verse (Ayah).
/// Public API - exposed to library consumers.
class Verse {
  final int verseID;
  final String humanReadableID; // e.g. "2_255"
  final int number;
  final String text;
  final String textWithoutTashkil;
  final String uthmanicHafsText;
  final String hafsSmartText;
  final String searchableText;
  final int chapterNumber;
  final int pageNumber;
  final int partNumber;
  final int hizbNumber;
  final VerseMarker? marker1441;
  final VerseMarker? marker1405;
  final List<VerseHighlight> highlights1441;
  final List<VerseHighlight> highlights1405;

  const Verse({
    required this.verseID,
    required this.humanReadableID,
    required this.number,
    required this.text,
    required this.textWithoutTashkil,
    required this.uthmanicHafsText,
    required this.hafsSmartText,
    required this.searchableText,
    this.chapterNumber = 0,
    this.pageNumber = 0,
    this.partNumber = 0,
    this.hizbNumber = 0,
    this.marker1441,
    this.marker1405,
    this.highlights1441 = const [],
    this.highlights1405 = const [],
  });
}
