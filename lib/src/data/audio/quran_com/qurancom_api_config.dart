import 'package:imad_flutter/src/data/audio/quran_com/qurancom_environment.dart';

class QuranComApiConfig {
  final String clientId;
  final String clientSecret;
  final QuranComEnvironment environment;

  QuranComApiConfig({
    required this.clientId,
    required this.clientSecret,
    required this.environment,
  });

  String get tokenUrl => '${environment.authBaseUrl}/oauth2/token';
  String get contentApiBaseUrl => environment.apiBaseUrl;

  String get recitersPath => 'resources/recitations';

  /// Append {id}/{chapter_number} to the contentApiBaseUrl to get the chapter audio url
  /// The complete url will be like: https://apis-prelive.quran.foundation/content/api/v4/chapter_recitations/{id}/{chapter_number}
  String get chapterAudioPath => 'chapter_recitations';
}
