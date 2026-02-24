/// MushafImad Flutter Library
///
/// A Quran reader library for Flutter providing Mushaf page display
/// with audio recitation support, bookmarks, search, and more.
///
/// ## Getting Started
///
/// Initialize the library before use:
/// ```dart
/// await MushafLibrary.initialize(
///   databaseService: myDatabaseService,
///   bookmarkDao: myBookmarkDao,
///   readingHistoryDao: myReadingHistoryDao,
///   searchHistoryDao: mySearchHistoryDao,
/// );
/// ```
///
/// Then access repositories:
/// ```dart
/// final chapters = await MushafLibrary.getChapterRepository().getAllChapters();
/// ```
library;

// Entry point
export 'src/mushaf_library.dart';

// DI
export 'src/di/core_module.dart'
    show setupMushafDependencies, setupMushafWithHive, mushafGetIt;

// Domain Models
export 'src/domain/models/advanced_search.dart';
export 'src/domain/models/audio_player_state.dart';
export 'src/domain/models/bookmark.dart';
export 'src/domain/models/cache_stats.dart';
export 'src/domain/models/chapter.dart';
export 'src/domain/models/chapter_group.dart';
export 'src/domain/models/last_read_position.dart';
export 'src/domain/models/mushaf_type.dart';
export 'src/domain/models/page.dart';
export 'src/domain/models/page_header_info.dart';
export 'src/domain/models/part.dart';
export 'src/domain/models/quarter.dart';
export 'src/domain/models/reading_history.dart';
export 'src/domain/models/reciter_info.dart';
export 'src/domain/models/reciter_timing.dart';
export 'src/domain/models/result.dart';
export 'src/domain/models/search_history.dart';
export 'src/domain/models/theme.dart';
export 'src/domain/models/user_data_backup.dart';
export 'src/domain/models/verse.dart';
export 'src/domain/models/verse_highlight.dart';
export 'src/domain/models/verse_marker.dart';

// Domain Repository Interfaces
export 'src/domain/repository/audio_repository.dart';
export 'src/domain/repository/bookmark_repository.dart';
export 'src/domain/repository/chapter_repository.dart';
export 'src/domain/repository/data_export_repository.dart';
export 'src/domain/repository/page_repository.dart';
export 'src/domain/repository/preferences_repository.dart';
export 'src/domain/repository/quran_repository.dart';
export 'src/domain/repository/reading_history_repository.dart';
export 'src/domain/repository/search_history_repository.dart';
export 'src/domain/repository/verse_repository.dart';

// Data Layer - Public interfaces for implementors
export 'src/data/repository/database_service.dart';
export 'src/data/local/dao/bookmark_dao.dart';
export 'src/data/local/dao/reading_history_dao.dart';
export 'src/data/local/dao/search_history_dao.dart';

// Data Layer - Audio (public utilities)
export 'src/data/audio/reciter_data_provider.dart';

// Logging
export 'src/logging/mushaf_logger.dart';

// UI ViewModels
export 'src/ui/mushaf/mushaf_view_model.dart';
export 'src/ui/player/quran_player_view_model.dart';
export 'src/ui/search/search_view_model.dart';
export 'src/ui/bookmarks/bookmarks_view_model.dart';
export 'src/ui/history/reading_history_view_model.dart';
export 'src/ui/settings/settings_view_model.dart';
export 'src/ui/theme/theme_view_model.dart';
export 'src/ui/theme/reading_theme.dart';

// Mushaf UI Widgets
export 'src/ui/mushaf/mushaf_page_view.dart';
export 'src/ui/mushaf/quran_page_widget.dart';
export 'src/ui/mushaf/quran_line_image.dart';
export 'src/ui/mushaf/verse_fasel.dart';
export 'src/ui/mushaf/chapter_index_drawer.dart';

// Feature UI Widgets
export 'src/ui/bookmarks/bookmark_list_widget.dart';
export 'src/ui/search/search_page.dart';
export 'src/ui/settings/settings_page.dart';
export 'src/ui/theme/theme_picker_widget.dart';
export 'src/ui/theme/mushaf_theme_scope.dart';

// Quran Data
export 'src/data/quran/quran_data_provider.dart';
export 'src/data/quran/quran_metadata.dart';
export 'src/data/quran/verse_data_provider.dart';

// Hive Database Implementations
export 'src/data/local/hive_database_service.dart';
export 'src/data/local/dao/hive/hive_bookmark_dao.dart';
export 'src/data/local/dao/hive/hive_reading_history_dao.dart';
export 'src/data/local/dao/hive/hive_search_history_dao.dart';
