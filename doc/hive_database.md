# Hive Database Integration

## Overview
The library uses [Hive](https://pub.dev/packages/hive) as its local database for persisting user data (bookmarks, reading history, search history) and a static-metadata `DatabaseService` for Quran metadata (chapters, pages, parts, quarters).

## Architecture

```
DatabaseService (abstract)
  └── HiveDatabaseService (static Quran metadata)

BookmarkDao (abstract)
  └── HiveBookmarkDao (Hive box: "bookmarks")

ReadingHistoryDao (abstract)
  └── HiveReadingHistoryDao (Hive boxes: "reading_history", "last_read_positions")

SearchHistoryDao (abstract)
  └── HiveSearchHistoryDao (Hive box: "search_history")
```

## Quick Start

```dart
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupMushafWithHive();  // One-line setup!
  runApp(MyApp());
}
```

## Manual Setup

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final db = HiveDatabaseService();
  await db.initialize();

  setupMushafDependencies(
    databaseService: db,
    bookmarkDao: HiveBookmarkDao(),
    readingHistoryDao: HiveReadingHistoryDao(),
    searchHistoryDao: HiveSearchHistoryDao(),
  );

  runApp(MyApp());
}
```

## Hive Box Names

| Box Name | Contents |
|----------|----------|
| `bookmarks` | Verse bookmarks with notes and tags |
| `reading_history` | Reading session entries (page, chapter, duration) |
| `last_read_positions` | Per-MushafType last-read position |
| `search_history` | Search queries with result counts |

## Limitations

- **Verse operations** in `HiveDatabaseService` are currently stubbed (return empty lists) pending the Realm data extraction in Phase 8.
- Data is stored as `Map` values (no code generation required), making the library lightweight.
