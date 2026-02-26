# Quran.com API Integration

This document describes the Quran.com API integration for the Mushaf Imad Flutter library.

## Overview

The library now supports fetching Quran recitations from [Quran.com](https://quran.com) API v4, providing access to a wide range of high-quality recitations from renowned reciters worldwide.

## Features

- **Fetch recitations** from Quran.com API
- **Audio playback** from Quran.com CDN URLs
- **Error handling** with automatic fallback to local sources
- **Caching** of API responses for improved performance
- **Search reciters** by name
- **Verse-level audio** support

## Configuration

### Using Quran.com API (Default)

By default, the library uses Quran.com API for audio:

```dart
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  // Initialize with Quran.com API (default)
  await MushafLibrary.initializeWithHive();
  
  // Or with explicit configuration
  await setupMushafWithHive(
    audioConfig: MushafAudioConfig.quranCom,
  );
}
```

### Using Local Audio Sources

To use the original mp3quran.net sources:

```dart
await setupMushafWithLocalAudio();
// or
await setupMushafWithHive(
  audioConfig: MushafAudioConfig.local,
);
```

### Custom Configuration

```dart
await setupMushafDependencies(
  databaseService: myDatabaseService,
  bookmarkDao: myBookmarkDao,
  readingHistoryDao: myReadingHistoryDao,
  searchHistoryDao: mySearchHistoryDao,
  audioConfig: const MushafAudioConfig(
    useQuranComApi: true,
    apiTimeout: Duration(seconds: 30),
    enableApiCache: true,
  ),
);
```

## Usage

### Basic Audio Playback

```dart
final audioRepo = mushafGetIt<AudioRepository>();

// Get all available reciters
final reciters = await audioRepo.getAllReciters();

// Play a chapter
final reciter = reciters.first; // Select a reciter
audioRepo.loadChapter(1, reciter.id, autoPlay: true);

// Control playback
audioRepo.play();
audioRepo.pause();
audioRepo.stop();
audioRepo.seekTo(30000); // Seek to 30 seconds
```

### Using AudioService Directly

For more control, you can use the `AudioService` directly:

```dart
import 'package:imad_flutter/imad_flutter.dart';

final audioService = AudioService();

// Fetch all recitations
try {
  final recitations = await audioService.fetchAllRecitations();
  for (final recitation in recitations) {
    print('${recitation['reciter_name']} - ${recitation['style']}');
  }
} on QuranComApiException catch (e) {
  print('Error: ${e.message}');
}

// Get chapter audio URL
final audioUrl = await audioService.getChapterAudioUrl(1, 1); // reciterId, chapter
print('Audio URL: $audioUrl');

// Get reciters as ReciterInfo objects
final reciters = await audioService.fetchAllReciters();

// Search reciters
final results = await audioService.searchReciters('Mishary');

// Dispose when done
audioService.dispose();
```

### Error Handling

The library provides comprehensive error handling:

```dart
import 'package:imad_flutter/imad_flutter.dart';

try {
  final audioService = AudioService();
  final url = await audioService.getChapterAudioUrl(999, 1); // Invalid reciter
} on QuranComApiException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
  print('Endpoint: ${e.endpoint}');
}
```

### Caching

API responses are automatically cached for better performance:

```dart
final audioService = AudioService();

// First call fetches from API
final reciters1 = await audioService.fetchAllRecitations();

// Second call returns cached data
final reciters2 = await audioService.fetchAllRecitations();

// Clear cache if needed
audioService.clearCache();

// Get cache statistics
final stats = audioService.getCacheStats();
print('Cached items: ${stats['cacheSize']}');
```

## API Endpoints Used

The following Quran.com API v4 endpoints are used:

- `GET /api/v4/resources/recitations` - List all recitations
- `GET /api/v4/chapter_recitations/{recitation_id}/{chapter_id}` - Get chapter audio
- `GET /api/v4/quran/recitations/{recitation_id}` - Get verse-level audio URLs

## Reciters Available

The API provides access to reciters including:

- AbdulBaset AbdulSamad (Murattal & Mujawwad)
- Abdur-Rahman as-Sudais
- Abu Bakr al-Shatri
- Hani ar-Rifai
- Mahmoud Khalil Al-Husary
- Mishari Rashid al-Afasy
- Mohamed Siddiq al-Minshawi
- Sa'ud ash-Shuraym
- And more...

## Fallback Behavior

When using Quran.com API, if the API is unavailable or returns an error, the library automatically falls back to local mp3quran.net sources. This ensures audio playback continues even when:

- Network is unavailable
- API rate limits are exceeded
- API server errors occur

## Architecture

The Quran.com integration consists of:

1. **AudioService** - Core service for Quran.com API communication
2. **QuranComReciterService** - Reciter management with API integration
3. **QuranComAudioRepository** - Repository implementation using API

### Class Diagram

```
AudioService
    |
    +-- fetchAllRecitations()
    +-- fetchChapterAudio()
    +-- getChapterAudioUrl()
    +-- fetchAllReciters()
    +-- searchReciters()

QuranComReciterService
    |
    +-- AudioService (optional)
    +-- Fallback to ReciterDataProvider

QuranComAudioRepository implements AudioRepository
    |
    +-- QuranComReciterService
    +-- FlutterAudioPlayer
    +-- AyahTimingService
```

## Testing

Example test code:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() {
  group('AudioService', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('fetchAllRecitations returns non-empty list', () async {
      final recitations = await audioService.fetchAllRecitations();
      expect(recitations, isNotEmpty);
    });

    test('getChapterAudioUrl returns valid URL', () async {
      final url = await audioService.getChapterAudioUrl(1, 1);
      expect(url, startsWith('https://'));
      expect(url, endsWith('.mp3'));
    });
  });
}
```

## Migration Guide

### From Local Audio to Quran.com API

No code changes required! Simply update your initialization:

```dart
// Before (local audio)
await MushafLibrary.initializeWithHive();

// After (Quran.com API - same code!)
await MushafLibrary.initializeWithHive();
```

The default configuration now uses Quran.com API.

### To Keep Using Local Audio

```dart
// Use this instead
await setupMushafWithLocalAudio();
```

## Troubleshooting

### API Timeout Errors

Increase the timeout duration:

```dart
await setupMushafWithHive(
  audioConfig: const MushafAudioConfig(
    useQuranComApi: true,
    apiTimeout: Duration(seconds: 60),
  ),
);
```

### Cache Issues

Clear the cache:

```dart
final audioRepo = mushafGetIt<AudioRepository>();
if (audioRepo is QuranComAudioRepository) {
  audioRepo.clearCache();
}
```

### Network Errors

Check your internet connection. The library will automatically fall back to local audio sources if the API is unreachable.

## License

This integration uses the Quran.com API which is subject to their terms of service. Please refer to [Quran.com](https://quran.com) for more information.
