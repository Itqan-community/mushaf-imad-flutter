import 'package:imad_flutter/src/data/quran/verse_data_provider.dart'
    show VerseMarkerData, VerseHighlightData, PageVerseData;
import 'package:imad_flutter/src/domain/models/verse.dart';
import 'package:imad_flutter/src/domain/models/verse_highlight.dart';
import 'package:imad_flutter/src/domain/models/verse_marker.dart';

/// Build a [PageVerseData] with the minimum required fields,
/// overriding only the Mushaf-specific fields as needed.
PageVerseData buildPageVerseData({
  VerseMarkerData? marker1441,
  List<VerseHighlightData> highlights1441 = const [],
  VerseMarkerData? marker1405,
  List<VerseHighlightData> highlights1405 = const [],
}) {
  return PageVerseData(
    verseID: 1,
    number: 1,
    chapter: 1,
    text: 'بسم الله الرحمن الرحيم',
    textWithoutTashkil: 'بسم الله الرحمن الرحيم',
    searchableText: 'بسم الله الرحمن الرحيم',
    marker1441: marker1441,
    highlights1441: highlights1441,
    marker1405: marker1405,
    highlights1405: highlights1405,
  );
}

/// Build a [Verse] domain model with the minimum required fields.
Verse buildVerse({
  VerseMarker? marker1441,
  List<VerseHighlight> highlights1441 = const [],
  VerseMarker? marker1405,
  List<VerseHighlight> highlights1405 = const [],
}) {
  return Verse(
    verseID: 1,
    humanReadableID: '1_1',
    number: 1,
    text: 'بسم الله الرحمن الرحيم',
    textWithoutTashkil: 'بسم الله الرحمن الرحيم',
    uthmanicHafsText: 'بسم الله الرحمن الرحيم',
    hafsSmartText: 'بسم الله الرحمن الرحيم',
    searchableText: 'بسم الله الرحمن الرحيم',
    chapterNumber: 1,
    pageNumber: 1,
    partNumber: 1,
    hizbNumber: 1,
    marker1441: marker1441,
    highlights1441: highlights1441,
    marker1405: marker1405,
    highlights1405: highlights1405,
  );
}
