
## 1.0.0

* **Major Re-architecture**: Standardized the audio data models by migrating from a `ReciterInfo`-centric hierarchy to a strict, universal `Recitation` entity. This ensures a uniform data contract across all underlying providers (Quran.com, Mp3Quran, and Itqan).
* **Feature**: Finalized support to query multiple audio recitation sources dynamically, displaying the correct `Riwayah` and `Reciter` information globally across the application.
* **Refactor**: Cleaned up test mock configurations, removed stale DTO testing variables, and unified repository methods to exclusively use the `Recitation` identifier.

## 0.2.0

* **Feature**: Implemented customizable context menu for verses with bottom sheet.
* **Feature**: Added Alketab search integration (#71).
* **Feature**: Added bookmark creation, retrieval, and unit tests (#15).
* **Feature**: Remember last open page.
* **Feature**: Implemented native "save us" dialog (#76).
* **Feature**: Implemented Itqan CMS audio streaming with verse timing and reciter support (#75).
* **Refactor**: Separated audio highlight state from user highlight state (#25).
* **Fix**: Resolved audio player start and timing issues in Quran.com integration.
* **Chore**: Added GitHub Actions workflow for running tests.

## 0.1.0
- **Feature**: Integrated **Quran.com** API for cloud audio streaming.
- **Feature**: Added **Hybrid Timing Engine** (syncing local and remote audio with verse data).
- **Core**: Implemented OAuth2 client with in-memory token caching and concurrency locking.
- **Docs**: Comprehensive technical guide and setup documentation added.

## 0.0.4

* Added CMS Audio Data Source Integration `ItqanAudioRepository`.
* Added `ItqanAudioConfig` parameter to `MushafLibrary.initialize()`.

## 0.0.3

* Added app screenshots to README.md.

## 0.0.2

* Initial release fixes and pubspec updates.

## 0.0.1

* TODO: Describe initial release.
