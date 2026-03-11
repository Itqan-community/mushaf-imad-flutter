import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_api_config.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_chapter_audio.dart';
import 'package:imad_flutter/src/data/audio/quran_com/qurancom_reciter.dart';
import 'package:imad_flutter/src/logging/mushaf_logger.dart';

/// Quran.com API client for fetching audio and reciters.
///
/// This client is used to fetch audio files and reciter information from the Quran.com API.
/// It uses OAuth2 authentication to access the API.
///
/// Example usage:
/// ```dart
/// final config = QuranComApiConfig(
///   clientId: 'YOUR_CLIENT_ID',
///   clientSecret: 'YOUR_CLIENT_SECRET',
///   environment: QuranComEnvironment.prelive,
/// );
/// final apiClient = QuranComApiClient(config: config);
/// final reciters = await apiClient.fetchReciters();
/// final audioFile = await apiClient.fetchChapterAudio(
///   reciterId: 7,
///   chapterNumber: 1,
///   segments: true,
/// );
/// ```
class QuranComApiClient {
  /// The API configuration.
  final QuranComApiConfig _config;

  /// The HTTP client used for API requests.
  final http.Client _httpClient;

  /// Internal flag to track if the HTTP client was created by this class.
  final bool _internalHttpClient;

  /// Logger instance to trace API activity.
  final MushafLogger _logger;

  /// The access token used for API requests.
  String? _accessToken;

  /// The expiry time of the access token.
  DateTime? _tokenExpiry;

  /// The future used to fetch the access token.
  Future<String>? _tokenFetchFuture;

  /// Creates a new instance of [QuranComApiClient].
  ///
  /// [config] The API configuration.
  /// [httpClient] The HTTP client to use for requests. If null, a new client will be created.
  QuranComApiClient({
    required QuranComApiConfig config,
    http.Client? httpClient,
    MushafLogger? logger,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _internalHttpClient = httpClient == null,
       _logger = logger ?? DefaultMushafLogger();

  /// Disposes the client and releases resources.
  void dispose() {
    if (_internalHttpClient) {
      _httpClient.close();
    }
  }

  /// Fetches a list of available reciters from the Quran.com API.
  ///
  /// Returns a [List<QuranComReciter>] object containing the reciter details.
  Future<List<QuranComReciter>> fetchReciters() async {
    final response = await _getWithAuth(_config.recitersPath);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return QuranComRecitationsResponse.fromJson(data).reciters;
  }

  /// Fetches audio for a specific chapter by reciter ID and chapter number.
  ///
  /// [reciterId] The ID of the reciter.
  /// [chapterNumber] The number of the chapter.
  /// [segments] Whether to include verse segments in the response - Default is true.
  ///
  /// Returns a [QuranComAudioFile] object containing the audio file details and verse timings.
  Future<QuranComAudioFile> fetchChapterAudio({
    required int reciterId,
    required int chapterNumber,
    bool segments = true,
  }) async {
    final path =
        '${_config.chapterAudioPath}/$reciterId/$chapterNumber?segments=$segments';
    final response = await _getWithAuth(path);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return QuranComChapterAudioResponse.fromJson(data).audioFile;
  }

  /// Fetches a new access token from the Quran.com API.
  ///
  /// Returns a [String] object containing the access token.
  Future<String> _fetchNewToken() async {
    _logger.info('Fetching new OAuth2 token...', category: LogCategory.network);
    final response = await _httpClient.post(
      Uri.parse(_config.tokenUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${_config.clientId}:${_config.clientSecret}'))}',
      },
      body: {'grant_type': 'client_credentials', 'scope': 'content'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      _logger.info(
        'Successfully fetched and cached new token (expires in ${expiresIn ~/ 60} minutes & ${expiresIn % 60} seconds).',
        category: LogCategory.network,
      );
      return _accessToken!;
    } else {
      final errorMsg =
          'Failed to fetch OAuth2 token from Quran.com API. Status: ${response.statusCode}, Body: ${response.body}';
      _logger.error(errorMsg, category: LogCategory.network);
      throw Exception(errorMsg);
    }
  }

  /// Gets an access token, refreshing it if expired.
  ///
  /// If a valid token is already cached, it returns that. If a token fetch is in progress, it waits for that to complete.
  ///
  /// Returns a [String] object containing the access token.
  Future<String> _getValidAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // If a token fetch is already in progress, wait for it to complete and return the result
    if (_tokenFetchFuture != null) {
      return await _tokenFetchFuture!;
    }

    // No valid token and no fetch in progress, start a new token fetch
    _tokenFetchFuture = _fetchNewToken();
    try {
      // Await the token fetch and cache the result
      _accessToken = await _tokenFetchFuture;
      return _accessToken!;
    } finally {
      _tokenFetchFuture = null;
    }
  }

  /// Gets data from the Quran.com API with authentication.
  ///
  /// [endpointPath] The path to the endpoint.
  ///
  /// Returns a [http.Response] object containing the response from the API.
  Future<http.Response> _getWithAuth(String endpointPath) async {
    final token = await _getValidAccessToken();
    final url = Uri.parse('${_config.contentApiBaseUrl}/$endpointPath');

    final headers = {'x-auth-token': token, 'x-client-id': _config.clientId};

    _logger.info('Sending GET request to $url', category: LogCategory.network);
    var response = await _httpClient.get(url, headers: headers);

    if (response.statusCode == 401) {
      _logger.warning(
        'Received 401 Unauthorized. Clearing token cache and retrying once...',
        category: LogCategory.network,
      );
      // Token might be expired , clear it and retry once
      _accessToken = null;
      _tokenExpiry = null;
      final newToken = await _getValidAccessToken();
      headers['x-auth-token'] = newToken;
      _logger.info(
        'Retrying GET request to $url with new token',
        category: LogCategory.network,
      );
      response = await _httpClient.get(url, headers: headers);
    }

    if (response.statusCode != 200) {
      final errorMsg =
          'Failed to get data from Quran.com API: status ${response.statusCode} , error ${response.body}';
      _logger.error(errorMsg, category: LogCategory.network);
      throw Exception(errorMsg);
    }

    _logger.info(
      'Successfully received response from $endpointPath',
      category: LogCategory.network,
    );
    return response;
  }
}
