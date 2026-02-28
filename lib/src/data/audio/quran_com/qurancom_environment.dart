/// Which Quran.com environment the client should talk to.
enum QuranComEnvironment {
  prelive,
  production,
}

extension QuranComEnvironmentX on QuranComEnvironment {
  String get authBaseUrl {
    switch (this) {
      case QuranComEnvironment.prelive:
        return 'https://prelive-oauth2.quran.foundation';
      case QuranComEnvironment.production:
        return 'https://oauth2.quran.foundation';
    }
  }

  String get apiBaseUrl {
    switch (this) {
      case QuranComEnvironment.prelive:
        return 'https://apis-prelive.quran.foundation/content/api/v4';
      case QuranComEnvironment.production:
        return 'https://apis.quran.foundation/content/api/v4';
    }
  }
}