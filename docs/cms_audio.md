# CMS Audio Integration

The `imad_flutter` library allows you to stream recitation audio and precise word/ayah timestamp data directly from the [Itqan CMS](https://cms.itqan.dev/) API.

Using the CMS integration removes the need to bundle gigabytes of audio files and JSON timings directly into your application payload, allowing for a much smaller app size and dynamic updates.

## Step-by-Step Integration Guide

Follow these steps to integrate the Itqan CMS audio backend into your Flutter application.

### Step 1: Define the CMS Audio Configuration

You need to create a `CmsAudioConfig` object that points to the ITQAN CMS API. You can specify a default reciter (e.g., `1` for Mishari Al-afasi).

```dart
import 'package:imad_flutter/imad_flutter.dart';

// Create configuration pointing to the CMS API endpoint.
const cmsConfig = CmsAudioConfig(
  baseUrl: 'https://api.cms.itqan.dev',
  defaultReciterId: 1, 
);
```

### Step 2: Initialize Hive with the CMS Config

The library uses Hive for local caching (bookmarks, search history). When setting up Hive, pass in your `cmsConfig`.

```dart
// Passing this config ensures Hive and Core dependencies use the CMS Audio Repository
await setupMushafWithHive(cmsAudioConfig: cmsConfig);
```

### Step 3: Initialize the Mushaf Library

Provide the Data Access Objects (DAOs) returned by the dependency injector (`mushafGetIt`), and pass your `cmsConfig` again to finalize the initialization.

```dart
await MushafLibrary.initialize(
  databaseService: mushafGetIt<DatabaseService>(),
  bookmarkDao: mushafGetIt<BookmarkDao>(),
  readingHistoryDao: mushafGetIt<ReadingHistoryDao>(),
  searchHistoryDao: mushafGetIt<SearchHistoryDao>(),
  cmsAudioConfig: cmsConfig, // Enables the CmsAudioRepository natively
);
```

### Full Example (`main.dart`)

Here is a complete, working example of how a new user should set up `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Define CMS configuration
  const cmsConfig = CmsAudioConfig(
    baseUrl: 'https://api.cms.itqan.dev',
    defaultReciterId: 1, // Optional: The default reciter ID
  );
  
  // 2. Setup Hive databases
  await setupMushafWithHive(cmsAudioConfig: cmsConfig);

  // 3. Initialize the core Mushaf Library
  await MushafLibrary.initialize(
    databaseService: mushafGetIt<DatabaseService>(),
    bookmarkDao: mushafGetIt<BookmarkDao>(),
    readingHistoryDao: mushafGetIt<ReadingHistoryDao>(),
    searchHistoryDao: mushafGetIt<SearchHistoryDao>(),
    cmsAudioConfig: cmsConfig, 
  );
  
  // 4. Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // The default Mushaf implementation will automatically hook into 
      // the CMS audio stream when the user hits 'Play'.
      home: Scaffold(
        body: MushafPageView(),
      ),
    );
  }
}
```

## How It Works Under The Hood

1. **Reciter Search:** When looking for a reciter, the repository calls `GET /reciters/` and parses the paginated JSON structure.
2. **Audio Playback:** When a user requests to play a chapter, the CMS Repository fetches `GET /recitations/?reciter_id={id}` to find the matching recitation asset.
3. **Surah Tracks & Timings:** It then hits `GET /recitations/{asset_id}/?page_size=114` to download the specific `audio_url` and verse bounds (`ayahs_timings`).
4. The `.mp3` URL is streamed directly via `just_audio`, and the parsed timestamp bounds are used to highlight standard verses on the UI in real-time.
