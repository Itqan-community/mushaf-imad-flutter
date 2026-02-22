/// Complete backup of user data.
/// Public API - exposed to library consumers.
class UserDataBackup {
  final int version;
  final int timestamp;
  final List<BookmarkData> bookmarks;
  final List<LastReadPositionData> lastReadPositions;
  final List<SearchHistoryData> searchHistory;
  final PreferencesData? preferences;

  const UserDataBackup({
    this.version = 1,
    required this.timestamp,
    this.bookmarks = const [],
    this.lastReadPositions = const [],
    this.searchHistory = const [],
    this.preferences,
  });

  factory UserDataBackup.fromJson(Map<String, dynamic> json) {
    return UserDataBackup(
      version: json['version'] as int? ?? 1,
      timestamp: json['timestamp'] as int,
      bookmarks:
          (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => BookmarkData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastReadPositions:
          (json['lastReadPositions'] as List<dynamic>?)
              ?.map(
                (e) => LastReadPositionData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      searchHistory:
          (json['searchHistory'] as List<dynamic>?)
              ?.map(
                (e) => SearchHistoryData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      preferences: json['preferences'] != null
          ? PreferencesData.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp,
    'bookmarks': bookmarks.map((e) => e.toJson()).toList(),
    'lastReadPositions': lastReadPositions.map((e) => e.toJson()).toList(),
    'searchHistory': searchHistory.map((e) => e.toJson()).toList(),
    if (preferences != null) 'preferences': preferences!.toJson(),
  };
}

class BookmarkData {
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final int createdAt;
  final String note;
  final List<String> tags;

  const BookmarkData({
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.createdAt,
    this.note = '',
    this.tags = const [],
  });

  factory BookmarkData.fromJson(Map<String, dynamic> json) {
    return BookmarkData(
      chapterNumber: json['chapterNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      pageNumber: json['pageNumber'] as int,
      createdAt: json['createdAt'] as int,
      note: json['note'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'chapterNumber': chapterNumber,
    'verseNumber': verseNumber,
    'pageNumber': pageNumber,
    'createdAt': createdAt,
    'note': note,
    'tags': tags,
  };
}

class LastReadPositionData {
  final String mushafType;
  final int chapterNumber;
  final int verseNumber;
  final int pageNumber;
  final int lastReadAt;
  final double scrollPosition;

  const LastReadPositionData({
    required this.mushafType,
    required this.chapterNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.lastReadAt,
    this.scrollPosition = 0.0,
  });

  factory LastReadPositionData.fromJson(Map<String, dynamic> json) {
    return LastReadPositionData(
      mushafType: json['mushafType'] as String,
      chapterNumber: json['chapterNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      pageNumber: json['pageNumber'] as int,
      lastReadAt: json['lastReadAt'] as int,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'mushafType': mushafType,
    'chapterNumber': chapterNumber,
    'verseNumber': verseNumber,
    'pageNumber': pageNumber,
    'lastReadAt': lastReadAt,
    'scrollPosition': scrollPosition,
  };
}

class SearchHistoryData {
  final String query;
  final int timestamp;
  final int resultCount;
  final String searchType;

  const SearchHistoryData({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.searchType,
  });

  factory SearchHistoryData.fromJson(Map<String, dynamic> json) {
    return SearchHistoryData(
      query: json['query'] as String,
      timestamp: json['timestamp'] as int,
      resultCount: json['resultCount'] as int,
      searchType: json['searchType'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'query': query,
    'timestamp': timestamp,
    'resultCount': resultCount,
    'searchType': searchType,
  };
}

class PreferencesData {
  final String mushafType;
  final int currentPage;
  final double fontSizeMultiplier;
  final int selectedReciterId;
  final double playbackSpeed;
  final bool repeatMode;
  final String themeMode;
  final String colorScheme;
  final bool useAmoled;

  const PreferencesData({
    required this.mushafType,
    required this.currentPage,
    required this.fontSizeMultiplier,
    required this.selectedReciterId,
    required this.playbackSpeed,
    required this.repeatMode,
    required this.themeMode,
    required this.colorScheme,
    required this.useAmoled,
  });

  factory PreferencesData.fromJson(Map<String, dynamic> json) {
    return PreferencesData(
      mushafType: json['mushafType'] as String,
      currentPage: json['currentPage'] as int,
      fontSizeMultiplier: (json['fontSizeMultiplier'] as num).toDouble(),
      selectedReciterId: json['selectedReciterId'] as int,
      playbackSpeed: (json['playbackSpeed'] as num).toDouble(),
      repeatMode: json['repeatMode'] as bool,
      themeMode: json['themeMode'] as String,
      colorScheme: json['colorScheme'] as String,
      useAmoled: json['useAmoled'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'mushafType': mushafType,
    'currentPage': currentPage,
    'fontSizeMultiplier': fontSizeMultiplier,
    'selectedReciterId': selectedReciterId,
    'playbackSpeed': playbackSpeed,
    'repeatMode': repeatMode,
    'themeMode': themeMode,
    'colorScheme': colorScheme,
    'useAmoled': useAmoled,
  };
}
