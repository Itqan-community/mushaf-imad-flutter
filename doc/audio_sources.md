# Audio Sources

The `imad_flutter` library supports three audio source backends. You can enable one or
more simultaneously. When multiple sources are active the library merges their reciter
lists into a single unified list and routes each playback request to the correct backend
automatically.

## Available Sources

| Source | Enum Value | Credentials Required |
|--------|-----------|---------------------|
| mp3quran.net (static MP3 + JSON timing) | `MushafAudioSource.mp3quran` | None (default) |
| Quran.Foundation (Quran.com) streaming API | `MushafAudioSource.quranCom` | OAuth2 client ID + secret |
| Itqan CMS API | `MushafAudioSource.itqan` | CMS base URL |

## Single Source (default)

No extra config is needed for the default Mp3Quran source:

```dart
await MushafLibrary.initialize();
// Equivalent to:
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.mp3quran},
);
```

## Single Source -- Quran.com

```dart
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.quranCom},
  quranComConfig: QuranComAudioSourceConfig(
    clientId: const String.fromEnvironment('QF_ID'),
    clientSecret: const String.fromEnvironment('QF_SECRET'),
  ),
);
```

## Single Source -- Itqan CMS

```dart
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.itqan},
  itqanAudioConfig: ItqanAudioConfig(
    baseUrl: 'https://api.cms.itqan.dev',
    defaultReciterId: 1,
  ),
);
```

## Multiple Sources

Pass a `Set` with all the sources you want to enable. Each source that needs
credentials must also receive its config object:

```dart
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.mp3quran, MushafAudioSource.quranCom},
  quranComConfig: QuranComAudioSourceConfig(
    clientId: const String.fromEnvironment('QF_ID'),
    clientSecret: const String.fromEnvironment('QF_SECRET'),
  ),
);
```

All three at once:

```dart
await MushafLibrary.initialize(
  audioSources: {
    MushafAudioSource.mp3quran,
    MushafAudioSource.quranCom,
    MushafAudioSource.itqan,
  },
  quranComConfig: QuranComAudioSourceConfig(
    clientId: const String.fromEnvironment('QF_ID'),
    clientSecret: const String.fromEnvironment('QF_SECRET'),
  ),
  itqanAudioConfig: ItqanAudioConfig(baseUrl: 'https://api.cms.itqan.dev'),
);
```

## Reciter List Behaviour

- All reciters from all enabled sources appear in the list returned by
  `AudioRepository.getAllReciters()`.
- The list is sorted alphabetically by English name.
- If the same reciter exists in multiple sources (e.g., Mishari Al-Afasy in
  both Mp3Quran and Quran.com) **both** entries are shown, each tagged with its
  source via `ReciterInfo.audioSource`. The UI layer can display a source badge.
- The default reciter is the first one alphabetically across all sources.

## Playback Routing

Each `ReciterInfo` carries an `audioSource` field. When the user selects a
reciter and calls `loadChapter`, the `CompositeAudioRepository` reads the
`audioSource` tag and delegates to the matching backend automatically. No manual
routing is needed.

```dart
final repo = MushafLibrary.getAudioRepository();
final reciters = await repo.getAllReciters(); // merged list from all sources

final selected = reciters.first;
// selected.audioSource tells you which backend it came from

await repo.loadChapter(1, selected.id); // automatically routed
```

## Architecture

```
MushafLibrary.initialize(audioSources: {...})
    |
    v
setupMushafDependencies
    |
    +-- Mp3QuranReciterProvider   --+
    +-- QuranComReciterProvider   --+--> CompositeAudioRepository
    +-- ItqanReciterProvider      --+        (AudioRepository)
    |
    +-- Mp3QuranPlaybackSource    --+
    +-- QuranComPlaybackSource    --+--> routed via ReciterInfo.audioSource
    +-- ItqanPlaybackSource       --+
```

## Migration from the Old API

The previous API used a single `audioSource` parameter:

```dart
// Old (will not compile)
await MushafLibrary.initialize(
  audioSource: MushafAudioSource.local,  // `local` has been renamed
);

// New
await MushafLibrary.initialize(
  audioSources: {MushafAudioSource.mp3quran},
);
```

Key changes:
- `audioSource:` (single value) is replaced by `audioSources:` (a `Set`).
- `MushafAudioSource.local` is renamed to `MushafAudioSource.mp3quran`.
- `MushafAudioSource.itqan` is now a proper enum value (was previously selected
  by passing a non-null `itqanAudioConfig`).
