/// Configuration for the CMS audio metadata fetching.
class ItqanAudioConfig {
  final String baseUrl;
  final int defaultReciterId;

  /// Whether to use headers that might be required by environments
  final Map<String, String>? headers;

  const ItqanAudioConfig({
    this.baseUrl = 'https://api.cms.itqan.dev',
    this.defaultReciterId = 1,
    this.headers,
  });
}
