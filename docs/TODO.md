# imad_flutter — TODO

## Phase 1: Hive Database Implementation
- [x] Add `hive` and `hive_flutter` to `pubspec.yaml`
- [x] Create `HiveDatabaseService` implementing `DatabaseService`
  - [x] Load bundled Quran metadata (chapters, verses, pages, parts, quarters) from assets into Hive
  - [ ] Implement all query methods (search, filtering, page-based lookups) — verse ops stubbed pending Realm export
- [x] Create `HiveBookmarkDao` implementing `BookmarkDao`
- [x] Create `HiveReadingHistoryDao` implementing `ReadingHistoryDao`
- [x] Create `HiveSearchHistoryDao` implementing `SearchHistoryDao`
- [x] Wire Hive implementations into `core_module.dart`
- [x] Add `setupMushafWithHive()` convenience function

## Phase 2: Audio Playback
- [ ] Add `just_audio` and `audio_service` to `pubspec.yaml`
- [ ] Create `FlutterAudioPlayer` service wrapping `just_audio`
- [ ] Integrate `audio_service` for background playback & media notifications
- [ ] Update `DefaultAudioRepository` to use real audio player
- [ ] Implement chapter streaming from reciter URLs
- [ ] Implement verse-level highlighting sync via `AyahTimingService`

## Phase 3: Flutter UI Widgets
- [x] Create `MushafPageView` widget (PageView with 604 Quran pages)
- [x] Create `QuranLineImage` widget (line PNG renderer with highlight)
- [x] Create `QuranPageWidget` (15 lines + page header)
- [x] Create `VerseFasel` widget (verse number marker circle)
- [x] Create `ChapterIndexDrawer` (surah index with quick jump)
- [x] Create `QuranDataProvider` (page→chapter/juz lookups)
- [x] Create `quran_metadata.dart` (114 chapters + 30 juz boundaries)
- [x] Create `AudioPlayerBar` widget (bottom player controls)
- [ ] Create `BookmarkListWidget`
- [ ] Create `SearchPage` widget
- [ ] Create `SettingsPage` widget
- [ ] Create `ThemePickerWidget`
- [ ] Apply `ReadingTheme` colors to Mushaf pages

## Phase 4: Preferences Persistence & UI
- [ ] Replace in-memory `DefaultPreferencesRepository` with Hive/SharedPreferences-backed version
- [ ] Persist mushaf type, current page, font size, reciter selection, theme config
- [ ] Restore last-read position on app launch
- [ ] Create `SettingsPage` widget with working controls that reflect on actual UI
- [ ] Theme switching (light/dark/sepia/AMOLED) should update Mushaf page background + text color
- [ ] Font size changes should apply immediately

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

## Phase 8: Realm Data Extraction (Verse-Level Highlighting)
- [ ] Write a script to export `quran.realm` to JSON (verse markers + highlight coordinates)
- [ ] Create `quran_data.json` bundled asset with per-verse marker/highlight data
- [ ] Update `QuranDataProvider` to load verse-level highlight/marker data
- [ ] Update `QuranLineImage` to render per-verse highlight overlays
- [ ] Update `QuranLineImage` to show `VerseFasel` markers at correct positions
