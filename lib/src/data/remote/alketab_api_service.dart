import 'dart:convert';
import 'package:http/http.dart' as http;

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

class AlKetabResult {
  final int verseID;
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final String text;
  final String? explanation;

  const AlKetabResult({
    required this.verseID,
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.text,
    this.explanation,
  });

  factory AlKetabResult.fromJson(Map<String, dynamic> json) {
    final aya = json['aya'] as Map<String, dynamic>? ?? {};
    final identifier = json['identifier'] as Map<String, dynamic>? ?? {};
    final position = json['position'] as Map<String, dynamic>? ?? {};

    return AlKetabResult(
      verseID: identifier['aya_id'] as int? ?? 0,
      chapterNumber: identifier['sura_id'] as int? ?? 0,
      verseNumber: identifier['aya_id'] as int? ?? 0,
      pageNumber: position['page'] as int? ?? 0,
      text: _stripHtml(aya['text'] as String? ?? ''),
      explanation: null,
    );
  }
}

class AlKetabApiService {
  static const String _baseUrl = 'https://alketab-api.web.app/api/search';

  static String _apiKey = '';

  static void configure(String apiKey) {
    _apiKey = apiKey;
  }

  static Future<AlKetabSearchResponse> search(String message) async {
    final uri = Uri.parse('$_baseUrl?message=${Uri.encodeComponent(message)}');
    final response = await http.get(uri, headers: {'X-API-Key': _apiKey});

    if (response.statusCode == 200) {
      return AlKetabSearchResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else if (response.statusCode == 402) {
      throw Exception('Insufficient credits');
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }

  static Future<AlKetabSearchResponse> fetchPage(
    String generatedQuery,
    int page, {
    String? sortBy,
  }) async {
    var url =
        '$_baseUrl?generated_query=${Uri.encodeComponent(generatedQuery)}&page=$page';
    if (sortBy != null) url += '&sort_by=$sortBy';

    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: {'X-API-Key': _apiKey});

    if (response.statusCode == 200) {
      return AlKetabSearchResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Fetch page failed: ${response.statusCode}');
    }
  }
}

class AlKetabSearchResponse {
  final List<AlKetabResult> results;
  final int totalPages;
  final String? generatedQuery;
  final String? sortBy;

  const AlKetabSearchResponse({
    required this.results,
    required this.totalPages,
    this.generatedQuery,
    this.sortBy,
  });

  factory AlKetabSearchResponse.fromJson(Map<String, dynamic> json) {
    final search = json['search'] as Map<String, dynamic>? ?? {};
    final ayas = search['ayas'] as Map<String, dynamic>? ?? {};
    final interval = search['interval'] as Map<String, dynamic>? ?? {};

    final results = ayas.values
        .map((e) => AlKetabResult.fromJson(e as Map<String, dynamic>))
        .toList();

    return AlKetabSearchResponse(
      results: results,
      totalPages: interval['nb_pages'] as int? ?? 1,
      generatedQuery:
          (json['ai'] as Map<String, dynamic>?)?['generated_query'] as String?,
      sortBy: (json['ai'] as Map<String, dynamic>?)?['sort_by'] as String?,
    );
  }
}
