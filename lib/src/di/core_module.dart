import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/audio/ayah_timing_service.dart';
import '../data/audio/audio_source_config.dart';
import '../data/audio/bundled_audio_data_source.dart';
import '../data/audio/cms_itqan_audio_data_source.dart';
import '../data/audio/reciter_service.dart';
import '../data/cache/chapters_data_cache.dart';
import '../data/cache/quran_data_cache_service.dart';
import '../data/local/hive_database_service.dart';
import '../data/local/dao/hive/hive_bookmark_dao.dart';
import '../data/local/dao/hive/hive_reading_history_dao.dart';
import '../data/local/dao/hive/hive_search_history_dao.dart';
import '../data/audio/flutter_audio_player.dart';
import '../data/repository/database_service.dart';
import '../data/repository/default_audio_repository.dart';
import 'package:audio_service/audio_service.dart';
import '../data/repository/default_bookmark_repository.dart';
import '../data/repository/default_chapter_repository.dart';
import '../data/repository/default_data_export_repository.dart';
import '../data/repository/default_page_repository.dart';
import '../data/repository/default_preferences_repository.dart';
import '../data/repository/default_quran_repository.dart';
import '../data/repository/default_reading_history_repository.dart';
import '../data/repository/default_search_history_repository.dart';
import '../data/repository/default_verse_repository.dart';
import '../data/local/dao/bookmark_dao.dart';
import '../data/local/dao/reading_history_dao.dart';
import '../data/local/dao/search_history_dao.dart';
import '../domain/repository/audio_repository.dart';
import '../domain/repository/bookmark_repository.dart';
import '../domain/repository/chapter_repository.dart';
import '../domain/repository/data_export_repository.dart';
import '../domain/repository/page_repository.dart';
import '../domain/repository/preferences_repository.dart';
import '../domain/repository/quran_repository.dart';
import '../domain/repository/reading_history_repository.dart';
import '../domain/repository/search_history_repository.dart';
import '../domain/repository/verse_repository.dart';
import '../logging/mushaf_logger.dart';

/// Service locator instance for the library.
final GetIt mushafGetIt = GetIt.instance;

/// Register all core dependencies for the Mushaf library.
///
/// Call this before using any library features.
/// The [databaseService] must be provided by the consuming app or
/// can be the default Hive-based implementation.
///
/// [bookmarkDao], [readingHistoryDao], [searchHistoryDao] must be
/// provided for the full feature set, or the library will use stubs.
///
/// Example:
/// ```dart
/// await setupMushafDependencies(
///   databaseService: HiveDatabaseService(),
///   bookmarkDao: HiveBookmarkDao(),
///   readingHistoryDao: HiveReadingHistoryDao(),
///   searchHistoryDao: HiveSearchHistoryDao(),
/// );
/// ```
Future<void> setupMushafDependencies({
  required DatabaseService databaseService,
  required BookmarkDao bookmarkDao,
  required ReadingHistoryDao readingHistoryDao,
  required SearchHistoryDao searchHistoryDao,
  MushafAudioSource audioSource = MushafAudioSource.bundledAssets,
  CmsAudioSourceConfig cmsAudioSourceConfig = const CmsAudioSourceConfig(),
  MushafAudioDataSource? audioDataSource,
  MushafLogger? logger,
}) async {
  // Guard: if already registered, skip entirely
  if (mushafGetIt.isRegistered<MushafLogger>()) return;

  // Logger
  mushafGetIt.registerSingleton<MushafLogger>(logger ?? DefaultMushafLogger());

  // Database service
  mushafGetIt.registerSingleton<DatabaseService>(databaseService);

  // Cache services
  mushafGetIt.registerSingleton<ChaptersDataCache>(ChaptersDataCache());
  mushafGetIt.registerSingleton<QuranDataCacheService>(QuranDataCacheService());

  // Audio data source
  final resolvedAudioDataSource =
      audioDataSource ??
      (audioSource == MushafAudioSource.cmsItqanDev
          ? CmsItqanAudioDataSource(config: cmsAudioSourceConfig)
          : const BundledAudioDataSource());
  mushafGetIt.registerSingleton<MushafAudioDataSource>(resolvedAudioDataSource);

  // Audio services
  mushafGetIt.registerSingleton<AyahTimingService>(
    AyahTimingService(mushafGetIt<MushafAudioDataSource>()),
  );
  mushafGetIt.registerSingleton<ReciterService>(
    ReciterService(mushafGetIt<MushafAudioDataSource>()),
  );

  // DAOs
  mushafGetIt.registerSingleton<BookmarkDao>(bookmarkDao);
  mushafGetIt.registerSingleton<ReadingHistoryDao>(readingHistoryDao);
  mushafGetIt.registerSingleton<SearchHistoryDao>(searchHistoryDao);

  // Repositories
  mushafGetIt.registerSingleton<QuranRepository>(
    DefaultQuranRepository(
      mushafGetIt<DatabaseService>(),
      mushafGetIt<ChaptersDataCache>(),
      mushafGetIt<QuranDataCacheService>(),
    ),
  );

  mushafGetIt.registerSingleton<ChapterRepository>(
    DefaultChapterRepository(
      mushafGetIt<DatabaseService>(),
      mushafGetIt<ChaptersDataCache>(),
    ),
  );

  mushafGetIt.registerSingleton<PageRepository>(
    DefaultPageRepository(
      mushafGetIt<DatabaseService>(),
      mushafGetIt<QuranDataCacheService>(),
    ),
  );

  mushafGetIt.registerSingleton<VerseRepository>(
    DefaultVerseRepository(
      mushafGetIt<DatabaseService>(),
      mushafGetIt<QuranDataCacheService>(),
    ),
  );

  mushafGetIt.registerSingleton<BookmarkRepository>(
    DefaultBookmarkRepository(mushafGetIt<BookmarkDao>()),
  );

  mushafGetIt.registerSingleton<ReadingHistoryRepository>(
    DefaultReadingHistoryRepository(mushafGetIt<ReadingHistoryDao>()),
  );

  mushafGetIt.registerSingleton<SearchHistoryRepository>(
    DefaultSearchHistoryRepository(mushafGetIt<SearchHistoryDao>()),
  );

  mushafGetIt.registerSingleton<PreferencesRepository>(
    DefaultPreferencesRepository(),
  );

  // Initialize AudioService for background playback
  final audioPlayer = await AudioService.init<FlutterAudioPlayer>(
    builder: () => FlutterAudioPlayer(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mushafimad.audio',
      androidNotificationChannelName: 'Mushaf Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  mushafGetIt.registerSingleton<AudioRepository>(
    DefaultAudioRepository(
      mushafGetIt<ReciterService>(),
      mushafGetIt<AyahTimingService>(),
      audioPlayer,
    ),
  );

  mushafGetIt.registerSingleton<DataExportRepository>(
    DefaultDataExportRepository(
      mushafGetIt<BookmarkRepository>(),
      mushafGetIt<ReadingHistoryRepository>(),
      mushafGetIt<SearchHistoryRepository>(),
      mushafGetIt<PreferencesRepository>(),
    ),
  );
}

/// Convenience method: set up all dependencies using default Hive backends.
///
/// Call this for the simplest possible setup using the built-in Hive
/// implementations for database, bookmarks, reading history, and search.
///
/// Example:
/// ```dart
/// await setupMushafWithHive();
/// ```
Future<void> setupMushafWithHive({
  MushafAudioSource audioSource = MushafAudioSource.bundledAssets,
  CmsAudioSourceConfig cmsAudioSourceConfig = const CmsAudioSourceConfig(),
  MushafAudioDataSource? audioDataSource,
  MushafLogger? logger,
}) async {
  // Initialize Hive
  await Hive.initFlutter();

  // Create and initialize the database
  final db = HiveDatabaseService();
  await db.initialize();

  await setupMushafDependencies(
    databaseService: db,
    bookmarkDao: HiveBookmarkDao(),
    readingHistoryDao: HiveReadingHistoryDao(),
    searchHistoryDao: HiveSearchHistoryDao(),
    audioSource: audioSource,
    cmsAudioSourceConfig: cmsAudioSourceConfig,
    audioDataSource: audioDataSource,
    logger: logger,
  );
}
