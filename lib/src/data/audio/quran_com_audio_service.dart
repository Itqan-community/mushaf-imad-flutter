import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../domain/models/reciter_info.dart';

/// Exception thrown when Quran.com API calls fail.
class QuranComApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  const QuranComApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() =>
      'QuranComApiException: $message (status: $statusCode, endpoint: $endpoint)';
}

/// Service for interacting with Quran.com API v4.
/// Provides methods to fetch recitations, audio files, and related metadata.
class AudioService {
  static const String _baseUrl = 'api.quran.com';
  static const String _apiVersion = 'v4';
  static const String _basePath = '/api/$_apiVersion';

  final http.Client _httpClient;
  final Duration _timeout;
  final Map<String, dynamic> _cache = {};

  AudioService({
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client(),
       _timeout = timeout;

  /// Dispose resources.
  void dispose() {
    _httpClient.close();
    _cache.clear();
  }

  /// Clear the cache.
  void clearCache() {
    _cache.clear();
  }

  /// Get cached data by key.
  T? _getFromCache<T>(String key) {
    if (_cache.containsKey(key)) {
      final cached = _cache[key];
      if (cached is T) {
        return cached;
      }
    }
    return null;
  }

  /// Store data in cache.
  void _setCache<T>(String key, T value) {
    _cache[key] = value;
  }

  /// Build API URL.
  Uri _buildUri(String path, {Map<String, String>? queryParams}) {
    return Uri.https(_baseUrl, '$_basePath$path', queryParams);
  }

  /// Perform HTTP GET request with error handling.
  Future<dynamic> _get(String path, {Map<String, String>? queryParams, String? cacheKey}) async {
    // Check cache first if cacheKey is provided
    if (cacheKey != null) {
      final cached = _getFromCache<dynamic>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final uri = _buildUri(path, queryParams: queryParams);
      final response = await _httpClient
          .get(uri)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache the response if cacheKey is provided
        if (cacheKey != null) {
          _setCache(cacheKey, data);
        }
        
        return data;
      } else if (response.statusCode >= 500) {
        throw QuranComApiException(
          'Server error occurred. Please try again later.',
          statusCode: response.statusCode,
          endpoint: path,
        );
      } else if (response.statusCode == 404) {
        throw QuranComApiException(
          'Resource not found.',
          statusCode: response.statusCode,
          endpoint: path,
        );
      } else if (response.statusCode == 429) {
        throw QuranComApiException(
          'Rate limit exceeded. Please try again later.',
          statusCode: response.statusCode,
          endpoint: path,
        );
      } else {
        throw QuranComApiException(
          'Failed to fetch data: ${response.body}',
          statusCode: response.statusCode,
          endpoint: path,
        );
      }
    } on TimeoutException {
      throw const QuranComApiException(
        'Request timed out. Please check your internet connection.',
        endpoint: path,
      );
    } on FormatException {
      throw QuranComApiException(
        'Invalid response format from server.',
        endpoint: path,
      );
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Network error: $e',
        endpoint: path,
      );
    }
  }

  /// Fetch all available recitations from Quran.com API.
  /// Results are cached for performance.
  Future<List<Map<String, dynamic>>> fetchAllRecitations() async {
    const cacheKey = 'all_recitations';
    
    try {
      final data = await _get(
        '/resources/recitations',
        cacheKey: cacheKey,
      );
      
      final recitations = data['recitations'] as List<dynamic>?;
      if (recitations == null) {
        throw const QuranComApiException(
          'Invalid response: recitations field is missing',
          endpoint: '/resources/recitations',
        );
      }
      
      return recitations.cast<Map<String, dynamic>>();
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to parse recitations: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Fetch a specific recitation by ID.
  Future<Map<String, dynamic>?> fetchRecitationById(int recitationId) async {
    try {
      final recitations = await fetchAllRecitations();
      return recitations.firstWhere(
        (r) => r['id'] == recitationId,
        orElse: () => <String, dynamic>{},
      );
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to fetch recitation $recitationId: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Fetch chapter audio file URL for a specific recitation.
  /// [recitationId] - The recitation ID from Quran.com
  /// [chapterNumber] - The chapter number (1-114)
  /// Returns audio file info including URL, format, and file size.
  Future<Map<String, dynamic>> fetchChapterAudio(
    int recitationId,
    int chapterNumber,
  ) async {
    if (chapterNumber < 1 || chapterNumber > 114) {
      throw QuranComApiException(
        'Invalid chapter number: $chapterNumber. Must be between 1 and 114.',
        endpoint: '/chapter_recitations/$recitationId/$chapterNumber',
      );
    }

    final cacheKey = 'chapter_audio_$recitationId_$chapterNumber';
    
    try {
      final data = await _get(
        '/chapter_recitations/$recitationId/$chapterNumber',
        cacheKey: cacheKey,
      );
      
      final audioFile = data['audio_file'] as Map<String, dynamic>?;
      if (audioFile == null) {
        throw const QuranComApiException(
          'Invalid response: audio_file field is missing',
          endpoint: '/chapter_recitations',
        );
      }
      
      return audioFile;
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to fetch chapter audio: $e',
        endpoint: '/chapter_recitations/$recitationId/$chapterNumber',
      );
    }
  }

  /// Fetch audio URL for a specific chapter and recitation.
  /// Convenience method that returns just the URL string.
  Future<String> getChapterAudioUrl(int recitationId, int chapterNumber) async {
    final audioFile = await fetchChapterAudio(recitationId, chapterNumber);
    final url = audioFile['audio_url'] as String?;
    
    if (url == null || url.isEmpty) {
      throw QuranComApiException(
        'Audio URL not found for chapter $chapterNumber, recitation $recitationId',
        endpoint: '/chapter_recitations/$recitationId/$chapterNumber',
      );
    }
    
    return url;
  }

  /// Fetch all verse-level audio files for a recitation.
  /// This provides individual verse audio URLs.
  /// Note: This is a large payload, use with caution.
  Future<List<Map<String, dynamic>>> fetchVerseAudios(int recitationId) async {
    final cacheKey = 'verse_audios_$recitationId';
    
    try {
      final data = await _get(
        '/quran/recitations/$recitationId',
        cacheKey: cacheKey,
      );
      
      final audioFiles = data['audio_files'] as List<dynamic>?;
      if (audioFiles == null) {
        throw const QuranComApiException(
          'Invalid response: audio_files field is missing',
          endpoint: '/quran/recitations',
        );
      }
      
      return audioFiles.cast<Map<String, dynamic>>();
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to fetch verse audios: $e',
        endpoint: '/quran/recitations/$recitationId',
      );
    }
  }

  /// Fetch audio URL for a specific verse.
  /// [recitationId] - The recitation ID
  /// [chapterNumber] - The chapter number
  /// [verseNumber] - The verse number
  Future<String?> getVerseAudioUrl(
    int recitationId,
    int chapterNumber,
    int verseNumber,
  ) async {
    final verseKey = '$chapterNumber:$verseNumber';
    
    try {
      final verseAudios = await fetchVerseAudios(recitationId);
      final verseAudio = verseAudios.firstWhere(
        (v) => v['verse_key'] == verseKey,
        orElse: () => <String, dynamic>{},
      );
      
      final url = verseAudio['url'] as String?;
      if (url != null && url.isNotEmpty) {
        // URLs are relative, need to prepend the base CDN URL
        return 'https://verses.quran.com/$url';
      }
      return null;
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to fetch verse audio URL: $e',
        endpoint: '/quran/recitations/$recitationId',
      );
    }
  }

  /// Convert Quran.com recitation data to ReciterInfo.
  /// Maps the API response to the app's ReciterInfo model.
  ReciterInfo recitationToReciterInfo(Map<String, dynamic> recitation) {
    final id = recitation['id'] as int? ?? 0;
    final reciterName = recitation['reciter_name'] as String? ?? 'Unknown';
    final style = recitation['style'] as String?;
    final translatedName = recitation['translated_name'] as Map<String, dynamic>?;
    
    // Build Arabic name (use English name as fallback since API doesn't provide Arabic)
    // In production, you might want to maintain a separate mapping
    final nameArabic = reciterName; // API doesn't provide Arabic names directly
    
    // Build display name with style if available
    final nameEnglish = style != null && style != 'null'
        ? '$reciterName ($style)'
        : reciterName;
    
    // Map to ReciterInfo with Quran.com API base URL
    // Note: The actual audio URLs come from chapter_recitations endpoint
    return ReciterInfo(
      id: id,
      nameArabic: nameArabic,
      nameEnglish: nameEnglish,
      rewaya: style ?? 'Hafs',
      folderUrl: 'https://api.quran.com/api/v4/chapter_recitations/$id/',
    );
  }

  /// Fetch all reciters as ReciterInfo objects.
  Future<List<ReciterInfo>> fetchAllReciters() async {
    try {
      final recitations = await fetchAllRecitations();
      return recitations.map(recitationToReciterInfo).toList();
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to fetch reciters: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Search reciters by name.
  Future<List<ReciterInfo>> searchReciters(
    String query, {
    String languageCode = 'en',
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return fetchAllReciters();
    }

    try {
      final allReciters = await fetchAllReciters();
      return allReciters.where((reciter) {
        final searchName = languageCode == 'ar'
            ? reciter.nameArabic.toLowerCase()
            : reciter.nameEnglish.toLowerCase();
        return searchName.contains(normalizedQuery);
      }).toList();
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to search reciters: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Get reciter by ID.
  Future<ReciterInfo?> getReciterById(int reciterId) async {
    try {
      final recitation = await fetchRecitationById(reciterId);
      if (recitation == null || recitation.isEmpty) {
        return null;
      }
      return recitationToReciterInfo(recitation);
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to get reciter by ID: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Get default reciter (first available).
  Future<ReciterInfo> getDefaultReciter() async {
    try {
      final reciters = await fetchAllReciters();
      if (reciters.isEmpty) {
        throw const QuranComApiException(
          'No reciters available',
          endpoint: '/resources/recitations',
        );
      }
      return reciters.first;
    } on QuranComApiException {
      rethrow;
    } catch (e) {
      throw QuranComApiException(
        'Failed to get default reciter: $e',
        endpoint: '/resources/recitations',
      );
    }
  }

  /// Get cached audio metadata for debugging/monitoring.
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cachedKeys': _cache.keys.toList(),
    };
  }
}
