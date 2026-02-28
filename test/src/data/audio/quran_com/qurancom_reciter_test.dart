import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter.dart';

void main() {
  group('QuranComReciter', () {
    test('fromJson should correctly parse full reciter data', () {
      final json = {
        'id': 7,
        'reciter_name': 'Mishari Rashid al-`Afasy',
        'style': 'Murattal',
        'translated_name': {
          'name': 'Mishari Rashid al-`Afasy',
          'language_name': 'english',
        },
      };

      final reciter = QuranComReciter.fromJson(json);

      expect(reciter.id, 7);
      expect(reciter.reciterName, 'Mishari Rashid al-`Afasy');
      expect(reciter.style, 'Murattal');
      expect(reciter.translatedName, isNotNull);
      expect(reciter.translatedName!.name, 'Mishari Rashid al-`Afasy');
      expect(reciter.translatedName!.languageName, 'english');
    });

    test('fromJson should handle null style and translated_name', () {
      final json = {
        'id': 6,
        'reciter_name': 'Mahmoud Khalil Al-Husary',
        'style': null,
        'translated_name': null,
      };

      final reciter = QuranComReciter.fromJson(json);

      expect(reciter.id, 6);
      expect(reciter.reciterName, 'Mahmoud Khalil Al-Husary');
      expect(reciter.style, isNull);
      expect(reciter.translatedName, isNull);
    });

    test('toJson should produce valid map', () {
      const translatedName = QuranComTranslatedName(
        name: 'AbdulBaset AbdulSamad',
        languageName: 'english',
      );
      const reciter = QuranComReciter(
        id: 1,
        reciterName: 'AbdulBaset AbdulSamad',
        style: 'Mujawwad',
        translatedName: translatedName,
      );

      final json = reciter.toJson();

      expect(json['id'], 1);
      expect(json['reciter_name'], 'AbdulBaset AbdulSamad');
      expect(json['style'], 'Mujawwad');
      expect(json['translated_name']['name'], 'AbdulBaset AbdulSamad');
      expect(json['translated_name']['language_name'], 'english');
    });
  });

  group('QuranComTranslatedName', () {
    test('fromJson should parse correctly', () {
      final json = {'name': 'محمد أيوب', 'language_name': 'arabic'};

      final translatedName = QuranComTranslatedName.fromJson(json);

      expect(translatedName.name, 'محمد أيوب');
      expect(translatedName.languageName, 'arabic');
    });

    test('toJson should produce valid map', () {
      const translatedName = QuranComTranslatedName(
        name: 'Mishary Rashid al-`Afasy',
        languageName: 'english',
      );

      final json = translatedName.toJson();

      expect(json['name'], 'Mishary Rashid al-`Afasy');
      expect(json['language_name'], 'english');
    });
  });

  group('QuranComRecitationsResponse', () {
    test('fromJson should parse list of reciters correctly', () {
      final json = {
        'recitations': [
          {
            'id': 1,
            'reciter_name': 'AbdulBaset AbdulSamad',
            'style': 'Mujawwad',
            'translated_name': {
              'name': 'AbdulBaset AbdulSamad',
              'language_name': 'english',
            },
          },
          {
            'id': 2,
            'reciter_name': 'Abdul Rahman Al-Sudais',
            'style': 'Murattal',
            'translated_name': {
              'name': 'Abdul Rahman Al-Sudais',
              'language_name': 'english',
            },
          },
        ],
      };

      final response = QuranComRecitationsResponse.fromJson(json);

      expect(response.recitations.length, 2);
      expect(response.recitations[0].id, 1);
      expect(response.recitations[0].reciterName, 'AbdulBaset AbdulSamad');
      expect(response.recitations[1].id, 2);
      expect(response.recitations[1].reciterName, 'Abdul Rahman Al-Sudais');
    });

    test('toJson should produce valid map with list of reciters', () {
      const response = QuranComRecitationsResponse(
        recitations: [
          QuranComReciter(
            id: 1,
            reciterName: 'AbdulBaset AbdulSamad',
            style: 'Mujawwad',
          ),
        ],
      );

      final json = response.toJson();

      expect(json['recitations'], isList);
      expect(json['recitations'][0]['id'], 1);
      expect(json['recitations'][0]['reciter_name'], 'AbdulBaset AbdulSamad');
    });
  });
}
