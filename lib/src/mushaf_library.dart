import 'package:hive_flutter/hive_flutter.dart';
import 'package:imad_flutter/imad_flutter.dart';

/// Main entry point for MushafImad Flutter library.
///
/// The library must be initialized before use:
/// ```dart
/// await MushafLibrary.initialize();
/// ```
///
class MushafLibrary {
  MushafLibrary._();

  static bool _isInitialized = false;

  static MushafLogger _logger = DefaultMushafLogger();
  static MushafAnalytics _analytics = NoOpMushafAnalytics();

  /// Initialize the Mushaf library.
  ///
  /// Must be called before accessing any repository.
  /// Defaults to using Hive-based implementations if no DAOs or services are provided.
  static Future<void> initialize({
    DatabaseService? databaseService,
    BookmarkDao? bookmarkDao,
    ReadingHistoryDao? readingHistoryDao,
    SearchHistoryDao? searchHistoryDao,
    MushafLogger? logger,
    MushafAnalytics? analytics,
    CmsAudioConfig? cmsAudioConfig,
    MushafAudioSource audioSource = MushafAudioSource.local,
    QuranComAudioSourceConfig? quranComConfig,
    FlutterAudioPlayer? audioPlayer,
  }) async {
    if (_isInitialized) return;

    _logger = logger?? DefaultMushafLogger();
    if (analytics != null) _analytics = analytics;
    if(databaseService == null || bookmarkDao == null || readingHistoryDao == null || searchHistoryDao == null){
    await Hive.initFlutter();
    }
    final dbService = databaseService ?? HiveDatabaseService();
    await dbService.initialize();

    await setupMushafDependencies(
      databaseService: dbService,
      bookmarkDao: bookmarkDao ?? HiveBookmarkDao(),
      readingHistoryDao: readingHistoryDao ?? HiveReadingHistoryDao(),
      searchHistoryDao: searchHistoryDao ?? HiveSearchHistoryDao(),
      logger: _logger,
      cmsAudioConfig: cmsAudioConfig,
      audioSource: audioSource,
      quranComConfig: quranComConfig,
      audioPlayer: audioPlayer,
    );

    // Initialize database
    await mushafGetIt<QuranRepository>().initialize();

    _isInitialized = true;
    _logger.info('MushafLibrary initialized');
  }

  /// Check if library is initialized.
  static bool isInitialized() => _isInitialized;

  // ========== Logger & Analytics ==========

  /// Get the current logger.
  static MushafLogger get logger => _logger;

  /// Set a custom logger.
  static void setLogger(MushafLogger logger) => _logger = logger;

  /// Get the current analytics instance.
  static MushafAnalytics get analytics => _analytics;

  /// Set a custom analytics implementation.
  static void setAnalytics(MushafAnalytics analytics) => _analytics = analytics;

  // ========== Repository Accessors ==========

  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'MushafLibrary not initialized. Call MushafLibrary.initialize() first.',
      );
    }
  }

  /// Get QuranRepository for accessing Quran data.
  static QuranRepository getQuranRepository() {
    _checkInitialized();
    return mushafGetIt<QuranRepository>();
  }

  /// Get ChapterRepository for accessing chapter (surah) data.
  static ChapterRepository getChapterRepository() {
    _checkInitialized();
    return mushafGetIt<ChapterRepository>();
  }

  /// Get PageRepository for accessing page data.
  static PageRepository getPageRepository() {
    _checkInitialized();
    return mushafGetIt<PageRepository>();
  }

  /// Get VerseRepository for accessing verse (ayah) data.
  static VerseRepository getVerseRepository() {
    _checkInitialized();
    return mushafGetIt<VerseRepository>();
  }

  /// Get BookmarkRepository for managing bookmarks.
  static BookmarkRepository getBookmarkRepository() {
    _checkInitialized();
    return mushafGetIt<BookmarkRepository>();
  }

  /// Get ReadingHistoryRepository for managing reading history.
  static ReadingHistoryRepository getReadingHistoryRepository() {
    _checkInitialized();
    return mushafGetIt<ReadingHistoryRepository>();
  }

  /// Get SearchHistoryRepository for managing search history.
  static SearchHistoryRepository getSearchHistoryRepository() {
    _checkInitialized();
    return mushafGetIt<SearchHistoryRepository>();
  }

  /// Get AudioRepository for audio playback.
  static AudioRepository getAudioRepository() {
    _checkInitialized();
    return mushafGetIt<AudioRepository>();
  }

  /// Get PreferencesRepository for managing preferences.
  static PreferencesRepository getPreferencesRepository() {
    _checkInitialized();
    return mushafGetIt<PreferencesRepository>();
  }

  /// Get DataExportRepository for data export/import.
  static DataExportRepository getDataExportRepository() {
    _checkInitialized();
    return mushafGetIt<DataExportRepository>();
  }
}
