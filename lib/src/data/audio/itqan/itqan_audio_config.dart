/// Configuration for the CMS audio metadata fetching.
class ItqanAudioConfig {
  final String baseUrl;
  final int defaultReciterId;

  /// The API key for the Itqan CMS.
  /// You can get an API key from https://cms.itqan.dev
  final String? apiKey;

  /// Whether to use headers that might be required by environments
  final Map<String, String>? headers;

  const ItqanAudioConfig({
    this.baseUrl = 'https://api.cms.itqan.dev',
    this.defaultReciterId = 1,
    this.apiKey,
    this.headers,
  });

  /// Returns the configured headers, merged with the API key if provided.
  Map<String, String>? get resolvedHeaders {
    if (apiKey == null && headers == null) return null;
    final Map<String, String> resolved = {};
    if (headers != null) {
      resolved.addAll(headers!);
    }
    if (apiKey != null) {
      resolved['X-API-Key'] = apiKey!;
    }
    return resolved;
  }
}
