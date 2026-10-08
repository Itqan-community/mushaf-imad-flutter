import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/src/data/audio/itqan/itqan_audio_config.dart';

void main() {
  group('ItqanAudioConfig', () {
    test('default configuration has expected values and null headers', () {
      const config = ItqanAudioConfig();
      expect(config.baseUrl, 'https://api.cms.itqan.dev');
      expect(config.defaultReciterId, 1);
      expect(config.apiKey, isNull);
      expect(config.headers, isNull);
      expect(config.resolvedHeaders, isNull);
    });

    test('resolvedHeaders includes X-API-Key when apiKey is provided', () {
      const config = ItqanAudioConfig(apiKey: 'test-api-key');
      expect(config.apiKey, 'test-api-key');
      expect(config.resolvedHeaders, equals({'X-API-Key': 'test-api-key'}));
    });

    test('resolvedHeaders merges headers and X-API-Key', () {
      const config = ItqanAudioConfig(
        apiKey: 'test-api-key',
        headers: {'Accept-Language': 'ar'},
      );
      expect(
        config.resolvedHeaders,
        equals({
          'Accept-Language': 'ar',
          'X-API-Key': 'test-api-key',
        }),
      );
    });

    test('resolvedHeaders retains original headers when apiKey is null', () {
      const config = ItqanAudioConfig(
        headers: {'Accept-Language': 'ar'},
      );
      expect(
        config.resolvedHeaders,
        equals({'Accept-Language': 'ar'}),
      );
    });
  });
}
