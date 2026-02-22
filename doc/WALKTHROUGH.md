# imad_flutter — Port Walkthrough

## Overview

Flutter port of **mushaf-imad-android** (84 Kotlin files → 50+ Dart files). Mirrors the original modular architecture with clean separation of domain, data, and UI layers.

## Architecture

```
lib/
├── imad_flutter.dart              ← Barrel export (public API)
└── src/
    ├── mushaf_library.dart        ← Entry point (init + repository accessors)
    ├── di/
    │   └── core_module.dart       ← get_it DI registration
    ├── domain/
    │   ├── models/                ← 20 data models (Verse, Chapter, Bookmark, etc.)
    │   └── repository/            ← 10 abstract repository interfaces
    ├── data/
    │   ├── audio/                 ← ReciterDataProvider, AyahTimingService, ReciterService
    │   ├── cache/                 ← ChaptersDataCache, QuranDataCacheService
    │   ├── local/dao/             ← DAO interfaces (BookmarkDao, etc.)
    │   └── repository/            ← DatabaseService + 10 Default implementations
    ├── logging/
    │   └── mushaf_logger.dart     ← Logger + Analytics interfaces
    └── ui/
        ├── mushaf/                ← MushafViewModel
        ├── player/                ← QuranPlayerViewModel
        ├── search/                ← SearchViewModel
        ├── bookmarks/             ← BookmarksViewModel
        ├── history/               ← ReadingHistoryViewModel
        ├── settings/              ← SettingsViewModel
        └── theme/                 ← ThemeViewModel + ReadingTheme colors
```

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Hive** for DB (modular) | `DatabaseService` abstract class makes swapping easy |
| **get_it** for DI | `setupMushafDependencies()` registers all singletons |
| **ChangeNotifier** for VMs | Lightest Flutter state management, compatible with `Provider` |
| **Dart sealed class** for `Result` | Direct port of Kotlin sealed class |
| **Stream\<T\>** for reactivity | Equivalent of Kotlin `Flow<T>` / `StateFlow<T>` |

## Kotlin → Dart Mapping

| Kotlin | Dart |
|--------|------|
| `data class` | `class` with `final` fields |
| `enum class` | `enum` |
| `interface` | `abstract class` |
| `Flow<T>` | `Stream<T>` |
| `suspend fun` | `Future<T>` |
| `internal` | `_` prefix or `@internal` |
| `object` (singleton) | Static class / top-level |
| Koin `module` | `get_it` registration |
| Jetpack `ViewModel` | `ChangeNotifier` |

## Verification

```
$ dart analyze lib/
Analyzing lib... 0.6s
No issues found!
```

## Assets

Copied from Android project:
- `assets/ayah_timing/` — Verse timing JSON files for audio sync
- `assets/quran-images/` — 604 Quran page images

## Sample App

```bash
cd example && flutter run
```

4 demo pages: Reciters list, Domain Models showcase, Theme Preview, Mushaf Type selector.
