# Itqan Audio Integration

The `imad_flutter` library allows you to stream recitation audio and precise word/ayah timestamp data directly from the [Itqan CMS](https://cms.itqan.dev/) API.

Using the Itqan integration removes the need to bundle gigabytes of audio files and JSON timings directly into your application payload, allowing for a much smaller app size and dynamic updates.

For a full overview of all available audio sources and multi-source support see
[audio_sources.md](audio_sources.md).

## Step-by-Step Integration Guide

### Step 1: Define the Itqan Audio Configuration

```dart
import 'package:imad_flutter/imad_flutter.dart';

const itqanConfig = ItqanAudioConfig(
  baseUrl: 'https://api.cms.itqan.dev',
  defaultReciterId: 1,
);
```

### Step 2: Initialize with the Itqan Source

```dart
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.itqan},
  itqanAudioConfig: itqanConfig,
);
```

### Full Example (`main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const itqanConfig = ItqanAudioConfig(
    baseUrl: 'https://api.cms.itqan.dev',
    defaultReciterId: 1,
  );

  await MushafLibrary.initialize(
    audioSources: {MushafAudioSource.itqan},
    itqanAudioConfig: itqanConfig,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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
