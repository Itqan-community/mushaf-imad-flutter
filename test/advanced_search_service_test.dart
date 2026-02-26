import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/services/advanced_search_service.dart';

// Mock repositories would be needed for full testing
// This file contains basic tests for query parsing

void main() {
  group('AdvancedSearchService Query Parsing', () {
    // Note: We can't fully instantiate the service without mocks,
    // but we can test the query parsing logic if we extract it
    
    test('surah:ayah pattern should be detected', () {
      final pattern = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$');
      
      expect(pattern.hasMatch('2:255'), isTrue);
      expect(pattern.hasMatch('2:255-260'), isTrue);
      expect(pattern.hasMatch('114:6'), isTrue);
      expect(pattern.hasMatch('2:'), isFalse);
      expect(pattern.hasMatch('text'), isFalse);
      expect(pattern.hasMatch('2'), isFalse);
    });

    test('standalone number pattern should be detected', () {
      final pattern = RegExp(r'^(\d+)$');
      
      expect(pattern.hasMatch('1'), isTrue);
      expect(pattern.hasMatch('114'), isTrue);
      expect(pattern.hasMatch('604'), isTrue);
      expect(pattern.hasMatch('2:255'), isFalse);
      expect(pattern.hasMatch('text'), isFalse);
    });

    test('extracts correct groups from surah:ayah', () {
      final pattern = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$');
      
      var match = pattern.firstMatch('2:255')!;
      expect(match.group(1), equals('2'));
      expect(match.group(2), equals('255'));
      expect(match.group(3), isNull);
      
      match = pattern.firstMatch('2:255-260')!;
      expect(match.group(1), equals('2'));
      expect(match.group(2), equals('255'));
      expect(match.group(3), equals('260'));
    });
  });

  group('ParsedSearchQuery', () {
    test('should hold all required fields', () {
      final query = ParsedSearchQuery(
        rawQuery: '2:255',
        type: SearchQueryType.surahAyah,
        surahNumber: 2,
        ayahNumber: 255,
        searchText: '2:255',
      );

      expect(query.rawQuery, equals('2:255'));
      expect(query.type, equals(SearchQueryType.surahAyah));
      expect(query.surahNumber, equals(2));
      expect(query.ayahNumber, equals(255));
      expect(query.isSpecificQuery, isTrue);
    });

    test('should identify specific queries', () {
      final textQuery = ParsedSearchQuery(
        rawQuery: 'الله',
        type: SearchQueryType.text,
        searchText: 'الله',
      );
      expect(textQuery.isSpecificQuery, isFalse);

      final surahQuery = ParsedSearchQuery(
        rawQuery: '2',
        type: SearchQueryType.surahNumber,
        surahNumber: 2,
        searchText: '2',
      );
      expect(surahQuery.isSpecificQuery, isTrue);
    });
  });

  group('AutocompleteSuggestion', () {
    test('should hold all required fields', () {
      final suggestion = AutocompleteSuggestion(
        text: 'Al-Fatiha',
        secondaryText: 'The Opening · 7 verses',
        type: AutocompleteSuggestionType.chapter,
        data: {'number': 1},
      );

      expect(suggestion.text, equals('Al-Fatiha'));
      expect(suggestion.secondaryText, equals('The Opening · 7 verses'));
      expect(suggestion.type, equals(AutocompleteSuggestionType.chapter));
      expect(suggestion.data, equals({'number': 1}));
    });

    test('should work without optional fields', () {
      final suggestion = AutocompleteSuggestion(
        text: 'search term',
        type: AutocompleteSuggestionType.suggestion,
      );

      expect(suggestion.text, equals('search term'));
      expect(suggestion.secondaryText, isNull);
      expect(suggestion.data, isNull);
    });
  });

  group('UnifiedSearchResults', () {
    test('should calculate total count correctly', () {
      final results = UnifiedSearchResults(
        verses: [],
        chapters: [],
        bookmarks: [],
        parsedQuery: ParsedSearchQuery(
          rawQuery: 'test',
          type: SearchQueryType.text,
          searchText: 'test',
        ),
      );

      expect(results.totalCount, equals(0));
      expect(results.isEmpty, isTrue);
    });
  });
}
