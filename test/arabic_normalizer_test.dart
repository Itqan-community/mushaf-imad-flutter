import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/utils/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('should remove tashkeel (diacritics)', () {
      const withTashkeel = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      const withoutTashkeel = 'بسم الله الرحمن الرحيم';
      
      expect(ArabicNormalizer.normalize(withTashkeel), equals(withoutTashkeel));
    });

    test('should normalize alef variations', () {
      const withVariations = 'أإآٱ';
      const normalized = 'اااا';
      
      expect(ArabicNormalizer.normalize(withVariations), equals(normalized));
    });

    test('should normalize ta marbuta', () {
      const withTaMarbuta = 'مدرسة';
      const normalized = 'مدرسه';
      
      expect(ArabicNormalizer.normalize(withTaMarbuta), equals(normalized));
    });

    test('should normalize alef maksura', () {
      const withAlefMaksura = 'على';
      const normalized = 'علي';
      
      expect(ArabicNormalizer.normalize(withAlefMaksura), equals(normalized));
    });

    test('should remove tatweel', () {
      const withTatweel = 'خـــالد';
      const normalized = 'خالد';
      
      expect(ArabicNormalizer.normalize(withTatweel), equals(normalized));
    });

    test('should handle complex text', () {
      const complex = 'ٱلرَّحْمَٰنِ';
      const normalized = 'الرحمن';
      
      expect(ArabicNormalizer.normalize(complex), equals(normalized));
    });

    test('should convert to lowercase', () {
      expect(ArabicNormalizer.normalize('HELLO'), equals('hello'));
    });

    test('matches should return true for equivalent text', () {
      const text1 = 'الرَّحْمَنِ';
      const text2 = 'الرحمن';
      
      expect(ArabicNormalizer.matches(text1, text2), isTrue);
    });

    test('contains should work with normalization', () {
      const text = 'بِسْمِ اللَّهِ';
      const query = 'الله';
      
      expect(ArabicNormalizer.contains(text, query), isTrue);
    });

    test('startsWith should work with normalization', () {
      const text = 'ٱلْحَمْدُ';
      const query = 'الحم';
      
      expect(ArabicNormalizer.startsWith(text, query), isTrue);
    });

    test('containsAllTokens should match all words', () {
      const text = 'الله الرحمن الرحيم';
      const query = 'الله رحيم';
      
      expect(ArabicNormalizer.containsAllTokens(text, query), isTrue);
    });

    test('extension method normalized should work', () {
      expect('الرَّحْمَٰنِ'.normalized, equals('الرحمن'));
    });

    test('extension method containsArabic should work', () {
      expect('بِسْمِ اللَّهِ'.containsArabic('الله'), isTrue);
    });
  });
}
