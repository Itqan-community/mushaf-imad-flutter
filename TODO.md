# imad_flutter — TODO

## Phase 1: Hive Database Implementation
- [ ] Add `hive` and `hive_flutter` to `pubspec.yaml`
- [ ] Create `HiveDatabaseService` implementing `DatabaseService`
  - [ ] Load bundled Quran metadata (chapters, verses, pages, parts, quarters) from assets into Hive
  - [ ] Implement all query methods (search, filtering, page-based lookups)
- [ ] Create `HiveBookmarkDao` implementing `BookmarkDao`
- [ ] Create `HiveReadingHistoryDao` implementing `ReadingHistoryDao`
- [ ] Create `HiveSearchHistoryDao` implementing `SearchHistoryDao`
- [ ] Wire Hive implementations into `core_module.dart`

## Phase 2: Audio Playback
- [ ] Add `just_audio` and `audio_service` to `pubspec.yaml`
- [ ] Create `FlutterAudioPlayer` service wrapping `just_audio`
- [ ] Integrate `audio_service` for background playback & media notifications
- [ ] Update `DefaultAudioRepository` to use real audio player
- [ ] Implement chapter streaming from reciter URLs
- [ ] Implement verse-level highlighting sync via `AyahTimingService`

## Phase 3: Flutter UI Widgets
- [ ] Create `MushafPageView` widget (PageView with Quran page images)
- [ ] Create `VerseTextWidget` (Arabic text with tashkil)
- [ ] Create `ChapterListWidget` (surah index)
- [ ] Create `AudioPlayerBar` widget (bottom player controls)
- [ ] Create `BookmarkListWidget`
- [ ] Create `SearchPage` widget
- [ ] Create `SettingsPage` widget
- [ ] Create `ThemePickerWidget`
- [ ] Apply `ReadingTheme` colors to Mushaf pages

## Phase 4: Preferences Persistence
- [ ] Replace in-memory `DefaultPreferencesRepository` with Hive/SharedPreferences-backed version
- [ ] Persist mushaf type, current page, font size, reciter selection, theme config
- [ ] Restore last-read position on app launch

## Phase 5: Data Import/Export
- [ ] Complete `DefaultDataExportRepository` implementation
  - [ ] Export all bookmarks, reading history, search history, preferences
  - [ ] Import with merge or replace strategies
- [ ] Add file picker integration for import/export

## Phase 6: Testing
- [ ] Unit tests for domain models
- [ ] Unit tests for repository implementations
- [ ] Unit tests for cache services
- [ ] Unit tests for audio timing service
- [ ] Widget tests for UI components
- [ ] Integration tests for the example app

## Phase 7: Polish
- [ ] Add chapter grouping logic (`getChaptersByPart`, `getChaptersByHizb`, `getChaptersByType`)
- [ ] Implement reading streak calculation in `DefaultReadingHistoryRepository`
- [ ] Add proper error handling throughout repositories
- [ ] Performance optimization for page pre-caching
- [ ] RTL layout support for Arabic text
- [ ] Accessibility labels
