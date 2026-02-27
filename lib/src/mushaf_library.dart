import 'di/core_module.dart';
import 'data/audio/audio_source_config.dart';
import 'domain/repository/audio_repository.dart';
import 'domain/repository/bookmark_repository.dart';
import 'domain/repository/chapter_repository.dart';
import 'domain/repository/data_export_repository.dart';
import 'domain/repository/page_repository.dart';
import 'domain/repository/preferences_repository.dart';
import 'domain/repository/quran_repository.dart';
import 'domain/repository/reading_history_repository.dart';
import 'domain/repository/search_history_repository.dart';
import 'domain/repository/verse_repository.dart';
import 'logging/mushaf_logger.dart';

/// Main entry point for MushafImad Flutter library.
///
/// The library must be initialized before use:
/// ```dart
/// await MushafLibrary.initialize(
///   databaseService: myDatabaseService,
///   bookmarkDao: myBookmarkDao,
///   readingHistoryDao: myReadingHistoryDao,
///   searchHistoryDao: mySearchHistoryDao,
/// );
/// ```
///
/// After initialization, access repositories:
/// ```dart
/// final chapters = await MushafLibrary.getChapterRepository().getAllChapters();
/// ```
class MushafLibrary {
  MushafLibrary._();

  static bool _isInitialized = false;

  static MushafLogger _logger = DefaultMushafLogger();
  static MushafAnalytics _analytics = NoOpMushafAnalytics();

  /// Initialize the Mushaf library.
  ///
  /// Must be called before accessing any repository.
  static Future<void> initialize({
    required dynamic databaseService,
    required dynamic bookmarkDao,
    required dynamic readingHistoryDao,
    required dynamic searchHistoryDao,
    MushafAudioSource audioSource = MushafAudioSource.bundledAssets,
    CmsAudioSourceConfig cmsAudioSourceConfig = const CmsAudioSourceConfig(),
    MushafAudioDataSource? audioDataSource,
    MushafLogger? logger,
    MushafAnalytics? analytics,
  }) async {
    if (_isInitialized) return;

    if (logger != null) _logger = logger;
    if (analytics != null) _analytics = analytics;

    await setupMushafDependencies(
      databaseService: databaseService,
      bookmarkDao: bookmarkDao,
      readingHistoryDao: readingHistoryDao,
      searchHistoryDao: searchHistoryDao,
      audioSource: audioSource,
      cmsAudioSourceConfig: cmsAudioSourceConfig,
      audioDataSource: audioDataSource,
      logger: _logger,
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
