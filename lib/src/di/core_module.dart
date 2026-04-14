import 'package:get_it/get_it.dart';

import '../data/audio/ayah_timing_service.dart';
import '../data/audio/base/audio_playback_source.dart';
import '../data/audio/base/audio_recitation_provider.dart';
import '../data/audio/itqan/itqan_audio_config.dart';
import '../data/audio/itqan/itqan_playback_source.dart';
import '../data/audio/itqan/itqan_recitation_provider.dart';
import '../data/audio/mp3quran/mp3quran_playback_source.dart';
import '../data/audio/mp3quran/mp3quran_recitation_provider.dart';
import '../data/audio/quran_com/qurancom_api_client.dart';
import '../data/audio/quran_com/qurancom_audio_source_config.dart';
import '../data/audio/quran_com/qurancom_data_source.dart';
import '../data/audio/quran_com/qurancom_playback_source.dart';
import '../data/audio/quran_com/qurancom_recitation_provider.dart';
import '../data/audio/recitation_service.dart';
import '../data/cache/chapters_data_cache.dart';
import '../data/cache/quran_data_cache_service.dart';
import '../data/audio/flutter_audio_player.dart';
import '../data/repository/composite_audio_repository.dart';
import '../data/repository/database_service.dart';
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
import '../domain/models/audio_source.dart';
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
/// Pass [audioSources] to select one or more audio backends. Reciters and
/// recitations from every enabled source are merged into a single unified
/// list. Each selected source requires its own config object:
/// - [MushafAudioSource.mp3quran] (default) -- no extra config needed.
/// - [MushafAudioSource.quranCom] -- requires [quranComConfig].
/// - [MushafAudioSource.itqan]    -- requires [itqanAudioConfig].
///
/// Example -- single source (default):
/// ```dart
/// await setupMushafDependencies(
///   databaseService: HiveDatabaseService(),
///   bookmarkDao: HiveBookmarkDao(),
///   readingHistoryDao: HiveReadingHistoryDao(),
///   searchHistoryDao: HiveSearchHistoryDao(),
///   audioSources: {MushafAudioSource.mp3quran},
/// );
/// ```
///
/// Example -- multiple sources:
/// ```dart
/// await setupMushafDependencies(
///   ...
///   audioSources: {MushafAudioSource.mp3quran, MushafAudioSource.quranCom},
///   quranComConfig: QuranComAudioSourceConfig(
///     clientId: const String.fromEnvironment('QF_ID'),
///     clientSecret: const String.fromEnvironment('QF_SECRET'),
///   ),
/// );
/// ```
Future<void> setupMushafDependencies({
  required DatabaseService databaseService,
  required BookmarkDao bookmarkDao,
  required ReadingHistoryDao readingHistoryDao,
  required SearchHistoryDao searchHistoryDao,
  required MushafLogger logger,
  Set<MushafAudioSource> audioSources = const {MushafAudioSource.mp3quran},
  QuranComAudioSourceConfig? quranComConfig,
  ItqanAudioConfig? itqanAudioConfig,

  /// Provide a pre-built [FlutterAudioPlayer] to skip [AudioService.init].
  /// Useful in tests where native platform channels are unavailable.
  FlutterAudioPlayer? audioPlayer,
}) async {
  assert(
    !audioSources.contains(MushafAudioSource.quranCom) ||
        quranComConfig != null,
    'quranComConfig must be provided when MushafAudioSource.quranCom is enabled',
  );
  assert(
    !audioSources.contains(MushafAudioSource.itqan) || itqanAudioConfig != null,
    'itqanAudioConfig must be provided when MushafAudioSource.itqan is enabled',
  );

  // Logger
  mushafGetIt.registerSingleton<MushafLogger>(logger);

  // Database service
  mushafGetIt.registerSingleton<DatabaseService>(databaseService);

  // Cache services
  mushafGetIt.registerSingleton<ChaptersDataCache>(ChaptersDataCache());
  mushafGetIt.registerSingleton<QuranDataCacheService>(QuranDataCacheService());

  // DAOs
  mushafGetIt.registerSingleton<BookmarkDao>(bookmarkDao);
  mushafGetIt.registerSingleton<ReadingHistoryDao>(readingHistoryDao);
  mushafGetIt.registerSingleton<SearchHistoryDao>(searchHistoryDao);

  // Audio services
  mushafGetIt.registerSingleton<AyahTimingService>(AyahTimingService());
  mushafGetIt.registerSingleton<RecitationService>(RecitationService());

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
  final resolvedPlayer =
      audioPlayer ??
      await AudioService.init<FlutterAudioPlayer>(
        builder: () => FlutterAudioPlayer(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.mushafimad.audio',
          androidNotificationChannelName: 'Mushaf Audio Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

  // Build AudioRecitationProvider and AudioPlaybackSource lists based on the
  // enabled sources, then wire a single CompositeAudioRepository.
  final recitationProviders = <AudioRecitationProvider>[];
  final playbackSources = <MushafAudioSource, AudioPlaybackSource>{};

  if (audioSources.contains(MushafAudioSource.mp3quran)) {
    final timingService = mushafGetIt<AyahTimingService>();
    recitationProviders.add(Mp3QuranRecitationProvider());
    playbackSources[MushafAudioSource.mp3quran] = Mp3QuranPlaybackSource(
      timingService: timingService,
      audioPlayer: resolvedPlayer,
    );
  }

  if (audioSources.contains(MushafAudioSource.quranCom)) {
    final apiClient = QuranComApiClient(config: quranComConfig!.toApiConfig());
    final dataSource = QurancomDataSource(apiClient: apiClient);
    final resolvedLogger = mushafGetIt<MushafLogger>();

    // Re-wire AyahTimingService with the Quran.com data source as fallback.
    mushafGetIt.unregister<AyahTimingService>();
    final timingService = AyahTimingService(dataSource: dataSource);
    mushafGetIt.registerSingleton<AyahTimingService>(timingService);

    final recitationProvider = QuranComRecitationProvider(
      dataSource: dataSource,
      logger: resolvedLogger,
    );

    mushafGetIt.registerSingleton<QuranComApiClient>(apiClient);
    mushafGetIt.registerSingleton<QurancomDataSource>(dataSource);
    mushafGetIt.registerSingleton<QuranComRecitationProvider>(
      recitationProvider,
    );

    recitationProviders.add(recitationProvider);
    playbackSources[MushafAudioSource.quranCom] = QuranComPlaybackSource(
      recitationProvider: recitationProvider,
      timingService: timingService,
      dataSource: dataSource,
      audioPlayer: resolvedPlayer,
      logger: resolvedLogger,
    );
  }

  if (audioSources.contains(MushafAudioSource.itqan)) {
    final config = itqanAudioConfig!;
    final recitationProvider = ItqanRecitationProvider(config: config);
    final playbackSource = ItqanPlaybackSource(
      config: config,
      recitationProvider: recitationProvider,
      audioPlayer: resolvedPlayer,
    );
    recitationProviders.add(recitationProvider);
    playbackSources[MushafAudioSource.itqan] = playbackSource;
  }

  mushafGetIt.registerSingleton<AudioRepository>(
    CompositeAudioRepository(
      recitationProviders: recitationProviders,
      playbackSources: playbackSources,
      audioPlayer: resolvedPlayer,
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
