## 0.0.6

* **Robust Error Handling (Phase 8)**: Implemented `Result<T>` pattern across all repository interfaces and default implementations.
* **Structured Failure Hierarchy**: Introduced `Failure` classes (`DatabaseFailure`, `NetworkFailure`, etc.) for granular error reporting.
* **Architecture Documentation**: Added `docs/error_handling_architecture.md` detailing the new error handling system.
* **Domain Layer Cleanup**: Fixed accidental interface pollution and ensured strict separation of repository concerns.

## 0.0.5

* **Premium Branded UI (Issue #56)**: Added custom logo and animated splash screen.
* **Reading Analytics (Issue #45)**: New `ReadingHistoryPage` with streaks, time read, and pages statistics.
* **AMOLED Theme (Issue #47)**: Pure black theme support for all UI components.
* **Premium Quran Header (Issue #51)**: Redesigned header with Juz, Chapter, and Page info.
* **Adaptive Toolbar (Issue #50)**: Interactive toolbar button with smart opacity management.
* **Premium Index Header (Issue #52)**: Gradient-styled header for the chapter selection drawer.
* **Search Enhancements (Issues #43 & #53)**: Smooth animations, query highlighting, and improved result tiles.
* **Audio Navigation (Issues #41 & #46)**: Chapter skip buttons and show/hide audio bar preference.
* **Verse-Level Highlighting (Phase 9)**: Supports precise selection, audio synchronization, and verse markers via Realm data extraction.

## 0.0.4

* Added `VersesListPage` widget — displays all 6,236 Quran verses with lazy loading.
* Added `VersesListViewModel` with efficient chapter-by-chapter data fetching and progress tracking.
* Three text-display modes: Uthmanic, Plain (with Tashkīl), Plain (without Tashkīl).
* Chapter-header dividers between surahs in the verse list.
* Added `ImportStrategyDialog` for Merge vs Replace data import strategy selection.
* Enhanced `importFromJson` with robust malformed-file error handling.
* Added widget tests for `QuranLineImage` (highlight overlays, markers, tap interactions).

## 0.0.3

* Added app screenshots to README.md.

## 0.0.2

* Initial release fixes and pubspec updates.

## 0.0.1

* TODO: Describe initial release.
