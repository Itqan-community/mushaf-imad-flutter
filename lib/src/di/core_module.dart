import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/audio/ayah_timing_service.dart';
import '../data/audio/reciter_service.dart';
import '../data/cache/chapters_data_cache.dart';
import '../data/cache/quran_data_cache_service.dart';
import '../data/local/hive_database_service.dart';
import '../data/local/dao/hive/hive_bookmark_dao.dart';
import '../data/local/dao/hive/hive_reading_history_dao.dart';
import '../data/local/dao/hive/hive_search_history_dao.dart';
import '../data/repository/database_service.dart';
import '../data/repository/default_audio_repository.dart';
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
void setupMushafDependencies({
  required DatabaseService databaseService,
  required BookmarkDao bookmarkDao,
  required ReadingHistoryDao readingHistoryDao,
  required SearchHistoryDao searchHistoryDao,
  MushafLogger? logger,
}) {
  // Logger
  mushafGetIt.registerSingleton<MushafLogger>(logger ?? DefaultMushafLogger());

  // Database service
  mushafGetIt.registerSingleton<DatabaseService>(databaseService);

  // Cache services
  mushafGetIt.registerSingleton<ChaptersDataCache>(ChaptersDataCache());
  mushafGetIt.registerSingleton<QuranDataCacheService>(QuranDataCacheService());

  // Audio services
  mushafGetIt.registerSingleton<AyahTimingService>(AyahTimingService());
  mushafGetIt.registerSingleton<ReciterService>(ReciterService());

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

  mushafGetIt.registerSingleton<AudioRepository>(
    DefaultAudioRepository(
      mushafGetIt<ReciterService>(),
      mushafGetIt<AyahTimingService>(),
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
Future<void> setupMushafWithHive({MushafLogger? logger}) async {
  // Initialize Hive
  await Hive.initFlutter();

  // Create and initialize the database
  final db = HiveDatabaseService();
  await db.initialize();

  setupMushafDependencies(
    databaseService: db,
    bookmarkDao: HiveBookmarkDao(),
    readingHistoryDao: HiveReadingHistoryDao(),
    searchHistoryDao: HiveSearchHistoryDao(),
    logger: logger,
  );
}
