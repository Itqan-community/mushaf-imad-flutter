# Quran.com Audio Feature – Development Log

This log documents the journey of implementing **Quran.com API as an audio source** for the `mushaf-imad-flutter` package (issue `#8`).  
It is meant for both **reviewers** and **future contributors** to understand the reasoning and steps taken.

## Table of Contents

- [Quran.com Audio Feature – Development Log](#qurancom-audio-feature--development-log)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Phase 0 – Setup \& Baseline](#phase-0--setup--baseline)
    - [0.1 – Repository setup and remotes](#01--repository-setup-and-remotes)
    - [0.2 – Syncing main and creating the feature branch](#02--syncing-main-and-creating-the-feature-branch)
    - [0.3 – Dependency resolution and static analysis](#03--dependency-resolution-and-static-analysis)
    - [0.4 – Checklists and logging setup](#04--checklists-and-logging-setup)
  - [Next Phase – Phase 1: API Research \& Credential Strategy](#next-phase--phase-1-api-research--credential-strategy)
  - [Phase 1 – API research \& decisions](#phase-1--api-research--decisions)
    - [Steps performed](#steps-performed)
    - [Observations \& answers](#observations--answers)
    - [Next](#next)
  - [Phase 2 – Data Models \& API Client](#phase-2--data-models--api-client)
    - [2.1 – Folder and dependencies](#21--folder-and-dependencies)
    - [2.2 – Reciter Model \& Unit Tests](#22--reciter-model--unit-tests)
    - [2.3 – Chapter Audio \& Verse Timing Models](#23--chapter-audio--verse-timing-models)
    - [Next](#next-1)
    - [2.4 – API Client \& Unit Tests](#24--api-client--unit-tests)
    - [2.5 - Integration Testing and Debugging](#25---integration-testing-and-debugging)
    - [API Client Integration test results:](#api-client-integration-test-results)
    - [Phase 3 – Adapting to `MushafAudioDataSource` Architecture](#phase-3--adapting-to-mushafaudiodatasource-architecture)


---

## Overview

- **Repository (fork)**: `Mamdouh-Attia/mushaf-imad-flutter`
- **Upstream (original)**: `Itqan-community/mushaf-imad-flutter`
- **Feature branch**: `feature/qurancom-audio`
- **Goal**: Add Quran.com (Quran Foundation) API as an optional audio source alongside the existing local audio implementation, with clean architecture, tests, and documentation.
- **Companion docs**:
  - Task checklist: `doc/quran_com_doc/QURAN_COM_CHECKLIST.md`

---

## Phase 0 – Setup & Baseline

### 0.1 – Repository setup and remotes

**Date:** 25th Feb 2026
**Context:** Prepare the local environment and git remotes for a clean feature branch workflow.

- Forked the original repository on GitHub into the personal account (`Mamdouh-Attia`).
- Cloned the fork locally at:
  - `D:\dev\OpenSrcContreibutions\mushaf-imad-flutter`
- Configured git remotes:
  - `origin` → personal fork (`https://github.com/Mamdouh-Attia/mushaf-imad-flutter.git`)
  - `upstream` → original repo (`https://github.com/Itqan-community/mushaf-imad-flutter.git`)
- Verified remotes with:

  ```bash
  git remote -v
  ```

  Output confirmed both `origin` and `upstream` are set correctly.

### 0.2 – Syncing main and creating the feature branch

**Objective:** Ensure the work starts from the latest upstream `main` and isolate all changes on a dedicated branch.

- Checked out local `main`:

  ```bash
  git checkout main
  ```

- Fetched latest changes from upstream:

  ```bash
  git fetch upstream
  git merge upstream/main
  ```

  - Result: `Already up to date.` – local `main` was already aligned with `upstream/main`.
- Created and switched to the feature branch for issue `#8`:

  ```bash
  git checkout -b feature/qurancom-audio
  ```

- Verified the working tree:

  ```bash
  git status
  ```

  - Result: `On branch feature/qurancom-audio` with a clean working tree.

### 0.3 – Dependency resolution and static analysis

**Objective:** Confirm that the existing codebase is in a healthy state before starting feature work.

- Restored dependencies for the main package and the example:

  ```bash
  flutter pub get
  ```

  - Dependencies resolved successfully.
  - Flutter reported that a couple of packages (`get_it`, `meta`) have newer versions, but they are **incompatible with the current constraints**, so no upgrades were performed at this stage (to avoid unrelated changes in this feature branch).

- Ran static analysis:

  ```bash
  flutter analyze
  ```

  **Summary of findings:**

  - **Example app warnings:**
    - Deprecated `groupValue` / `onChanged` usage in `example/lib/main.dart` (related to Flutter’s new `RadioGroup` pattern).
    - Minor style issues like a local variable starting with underscore.
    - Unused imports in `example/test/widget_test.dart`.
  - **Core library infos/warnings:**
    - Multiple `avoid_print` lints in `lib/src/data/audio/flutter_audio_player.dart` and one in `quran_page_widget.dart` – existing debug logging using `print`.
    - A few nullability / style lints in `lib/src/ui/mushaf/quran_page_widget.dart` (e.g. unnecessary `?.`/`!` where the receiver is non-null).
    - `use_build_context_synchronously` infos in `lib/src/ui/settings/settings_page.dart`, warning about `BuildContext` usage across async gaps.
    - Unused imports in `test/imad_flutter_test.dart`.

  **Decision:**

  - These lints are **pre-existing** and not directly related to the Quran.com audio feature.
  - For this feature branch:
    - Only warnings/errors **introduced by the new Quran.com code** will be treated as mandatory to fix.
    - Pre-existing lints in unrelated files will be left as-is, unless a file is being modified anyway for the feature (in which case small, local cleanups may be done in-context).

> **Note:** If maintainers later request specific lint cleanups, they can be done In a dedicated “lint cleanup” PR separate from the Quran.com feature.

### 0.4 – Checklists and logging setup

**Objective:** Make the work transparent and easy to review by maintaining explicit checklists and a development journal.

- Created a detailed incremental checklist in:
  - `doc/quran_com_doc/QURAN_COM_CHECKLIST.md`
  - The checklist mirrors the main phases from `QURAN_COM_ROADMAP.md`, but breaks them into small, commit-sized tasks with Markdown checkboxes.
- Established this development log (`doc/quran_com_doc/QURAN_COM_DEVELOPMENT_LOG.md`) to:
  - Record high-level decisions and context per phase.
  - Provide reviewers with a narrative of the implementation, not just raw diffs.
- Agreed on a workflow:
  - Use the checklist as the **task tracker**.
  - Use this log as the **story of what happened and why**, updated after each phase or meaningful step.

---

## Next Phase – Phase 1: API Research & Credential Strategy

**Planned focus:**

- Re-read Quran Foundation API docs for `recitations` and `chapter_recitations`.
- Capture real JSON samples and reconcile them with the roadmap assumptions.
- Decide and document how Quran.com credentials (`client_id`, `auth_token`) will be:
  - Provided locally during development (but kept out of git).
  - Represented as placeholders in the example app and documentation.

Once Phase 1 is complete, a new section will be added here summarizing:

- The exact endpoints and fields used.
- Any differences found between docs and actual responses.
- The final credential-handling approach agreed upon. 

## Phase 1 – API research & decisions

**Date:** 26th Feb 2026

Spent the day exploring the Quran Foundation documentation and exercising
the two endpoints that will power the audio feature.

### Steps performed

- Created a Postman environment `QuranPrelive` containing:
  - `QF_CLIENT_ID` / `QF_CLIENT_SECRET` (current values only).
  - `QF_TOKEN_URL` = `https://prelive-oauth2.quran.foundation/oauth2/token`
  - `QF_API_BASE` = `https://apis-prelive.quran.foundation/content/api/v4`
- Sent a token request using Basic Auth (client id/secret) and form body
  `grant_type=client_credentials&scope=content`.
- Copied `access_token` into `QF_ACCESS_TOKEN` and calculated
  `QF_TOKEN_EXPIRES_AT` (now + `expires_in` ms).
- Called `GET {{QF_API_BASE}}/recitations?language=en` with headers
  `x-auth-token` and `x-client-id`.
- Saved one sample JSON response locally (see separate scratch note).
- Called `GET {{QF_API_BASE}}/chapter_recitations/7/1?segments=true`
  (Mishari al‑`Afasy, chapter 1) and saved sample.

### Observations & answers

- **Response shapes**

  - `/recitations` returns an object with `recitations` array. Each
    element has: `id` (int), `reciter_name` (string), `style` (nullable
    string), `translated_name` object, e.g.

  ```json
  {
    "id": 6,
    "reciter_name": "Mahmoud Khalil Al-Husary",
    "style": null,
    "translated_name": { "name":"Mahmoud…","language_name":"english" }
  }
  ```

  - `language` query‑parameter selects the language for the names; if a
    translation is unavailable the server falls back to English. We will
    surface both the base name and the `translated_name` map in our model and
    let callers pick the appropriate string based on their current locale.

  - `/chapter_recitations/{reciterId}/{chapter}` returns an `audio_file`
    object. Older documentation referred to this key as `timings`, but the
    real response uses a `timestamps` array. Each entry contains verse-level
    information; a truncated example follows:

  ```json
  {
    "verse_key": "1:2",
    "timestamp_from": 4072,
    "timestamp_to": 9705,
    "duration": -5633,
    "segments": [
      [1, 4072.0, 5312.0],
      [2, 5312.0, 6322.0],
      [3, 6322.0, 6882.0],
      [4, 6882.0, 9307.0]
    ]
  }
  ```

  All time values (from/to and segment boundaries) are in **milliseconds**.
  The `duration` field is present but seems to be a negative difference (not
  needed). When the `segments` array is present it uses `[wordIndex, startMs,
  endMs]` triplets.

- **URL format** for audio files is supplied as `audio_url` (e.g.
  `https://download.quranicaudio.com/qdc/khalil_al_husary/murattal/2.mp3`).
  There is also an unrelated `/chapter_recitations/:id` endpoint that lists
  all files; we won't need it for this feature.

- **Rate limits & pagination**

  - No pagination is used for the two endpoints we care about; the API returns
    the complete list in one shot.
  - The docs do not specify exact quotas. We observed normal HTTP codes and
    assume a standard rate limit (429 with `Retry-After` if abused). Our
    client will cache results aggressively so this isn't a concern.

- **Authentication**

  - Access token *is required* for all content endpoints. Public browsing of
    the docs might suggest unauthenticated access, but every call we made
    returned `401` without the `x-auth-token` header. The client‑credentials
    flow is mandatory.

- **Timing structure**

  - As shown above: an array of objects with `verse_number`,
    `start_time_ms`, `end_time_ms`, and optional `segments`. There is no
    nested paging. A typical chapter returns 50–200 timing entries depending
    on length.

- **Environment URLs**
  - Chose to represent the two sets of URLs with a small enum.
  All development and tests will default to prelive; production will be
  selectable via the config object when the host app supplies real credentials.

- **Credential handling**
  - Policy: 
    - >“we need a placeholder of the credentials of course, i believe it is against quran.com's terms to leak their api key and secret. we do not want to break any rules”
  - All example code and docs will therefore show "YOUR_CLIENT_ID" etc.
  The host app is responsible for providing real values via QuranComApiConfig (from env, secrets file, backend, …).


### Next

With the above understanding and saved JSON samples, Phase 1 is effectively
complete. The decisions regarding environment use (prelive only for development),
credential handling (local secrets + placeholders), and token lifecycle are
documented in the checklist. Phase 2 can now begin by writing the Dart models
matching these shapes.

## Phase 2 – Data Models & API Client

**Date:** 28th Feb 2026

**Focus:** Implementing the core Data Models matching the Quran Foundation API shapes and verifying them with Unit Tests.

### 2.1 – Folder and dependencies
- Created `lib/src/data/audio/quran_com/` directory.
- Confirmed `http` dependency in `pubspec.yaml`.

### 2.2 – Reciter Model & Unit Tests
- Implemented `QuranComReciter` and `QuranComTranslatedName` in `qurancom_reciter.dart`.
- Added `QuranComRecitationsResponse` wrapper to handle the top-level API structure where reciters are returned in a `recitations` array.
- Adhered to manual serialization for simplicity and to match existing project patterns.
- Created comprehensive unit tests in `test/src/data/audio/quran_com/qurancom_reciter_test.dart`.
- **Test Results:** 7 tests passed (JSON deserialization, serialization, and top-level response wrapper).

### 2.3 – Chapter Audio & Verse Timing Models
**Date:** 2nd Mar 2026

- Implemented `QuranComVerseTiming`, `QuranComAudioFile`, and `QuranComChapterAudioResponse` in `lib/src/data/audio/quran_com/qurancom_chapter_audio.dart` and `qurancom_verse_timing.dart`.
- **Optimization (Memory):** Used **Dart Named Records** `({int wordIndex, int startMs, int endMs})` for storing word-level segments. This reduces the memory footprint significantly compared to creating separate class objects for every word in the Quran.
- **Optimization (Performance):** Used manual `for` loops in `fromJson` methods to maximize parsing speed, as recommended for high-frequency data structures like timings.
- **Robustness:** Handled `num` to `int`/`double` casting to safely parse JSON values that might come as doubles from the API.
- **Test Results:** Created comprehensive unit tests in `test/src/data/audio/quran_com/qurancom_chapter_audio_test.dart`. Verified:
  - Successful parsing of complex verse timings with segment arrays.
  - Correct handling of nullable fields (e.g., missing segments or timestamps).
  - Accurate serialization back to JSON format.

### Next
With the data layer structure complete and verified, the next phase is to implement the `QuranComApiClient` (Phase 2.4). This handles OAuth2 token management (client credentials flow) and the actual fetch logic.

### 2.4 – API Client & Unit Tests
**Date:** 4th Mar 2026

- **Configuration:** Implemented `QuranComApiConfig` and `QuranComEnvironment` enum to handle prelive/production URL switching and credentials.
- **OAuth2 Flow:** Implemented the client credentials flow with:
  - Memory-based token caching.
  - Automatic re-requesting ~30s before expiry.
  - 401 Unauthorized interceptor that clears the token cache and retries the request once.
- **Fetch Logic:** 
  - `fetchReciters`: Returns a list of `QuranComReciter`.
  - `fetchChapterAudio`: Returns `QuranComAudioFile` including timings and URL.
- **Security:** Confirmed that credentials remain placeholders in the codebase, ensuring no sensitive data is committed.

### 2.5 - Integration Testing and Debugging
**Date:** 6th-8th Mar 2026

- **Issue:** Encountered 404 (Not Found) and 522 (Service Error) during integration tests on real API.
- **Root Cause & Resolution:**
  1. **URL Concatenation Bug:** `QuranComApiConfig` was appending `/content/api/v4` to a base URL that *already* included it. Removed the redundant suffix.
  2. **Token Fetch Stampede Prevention:** Implemented a `Future<String>? _tokenFetchFuture` lock in Dart to prevent multiple concurrent requests from triggering duplicate OAuth token fetches when the token is expired. This aligns with the `threading.Lock()` strategy used in the official Python examples.
  3. **Timing Parsing:** Updated `QuranComVerseTiming` to safely handle variable-length segment arrays (e.g. `[wordIndex]` without start/end times) avoiding out-of-bounds `RangeError`.
  4. **Logging:** Integrated the `MushafLogger` (`LogCategory.network`) directly into `QuranComApiClient`. This improved the visibility of network requests in the terminal compared to `dart:developer` and aligned the client with the app's established telemetry system.
- **Test Coverage & Validation:**
  - Validated deeply nested parsing (e.g., verifying exactly 7 timings for Fatiha).
  - Fetched chapter audio both *with* and *without* the `segments` dimension to prove the parsing model dynamically adapts.
  - Profiled the in-memory Token Caching mechanism using a `Stopwatch`, confirming that secondary requests bypass the ~1000ms+ OAuth roundtrip.
  - Successfully intercepted deliberate 404 boundary errors (requesting Chapter 115).

  #### API Client Integration test results:
  ``` powershell
  --- TEST: Fetch Reciters ---
  Fetching real reciters list...
  Mushaf[network] INFO: Fetching new OAuth2 token...
  Mushaf[network] INFO: Successfully fetched and cached new token (expires in 59 minutes | 59 seconds).
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/resources/recitations
  Mushaf[network] INFO: Successfully received response from resources/recitations
  ✅ Successfully fetched 2 reciters.
  ✅ First reciter: id=6, name="Mahmoud Khalil Al-Husary", style="null"
  ✅ Translated name: "Mahmoud Khalil Al-Husary" (english)
  ✅ Found Mishari al-Afasy: id=7, Name="Mishari Rashid al-`Afasy"
  00:02 +1: QuranComApiClient Integration Test should successfully fetch chapter audio and timings (Fatiha) and deeply assert structure

  --- TEST: Fetch Chapter Audio (Fatiha) ---
  Fetching real audio and timings for Fatiha (reciter 7, chapter 1)...
  Mushaf[network] INFO: Fetching new OAuth2 token...
  Mushaf[network] INFO: Successfully fetched and cached new token (expires in 59 minutes | 59 seconds).
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/chapter_recitations/7/1?segments=true
  Mushaf[network] INFO: Successfully received response from chapter_recitations/7/1?segments=true
  ✅ Audio URL: https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/1.mp3
  ✅ Format: mp3, Size: 839808.0 KB
  ✅ Timestamps count: 7 (Verified exactly 7 for Fatiha)
  ✅ First verse [1:1]: From 0ms to 6090ms
  ✅ First verse has 4 word segments.
    -> Word 1: 0ms - 580ms
  00:03 +2: QuranComApiClient Integration Test should successfully fetch chapter audio without segments

  --- TEST: Fetch Chapter Audio Without Segments ---
  Fetching Husary (reciter 6) for Fatiha (chapter 1) with segments=false...
  Mushaf[network] INFO: Fetching new OAuth2 token...
  Mushaf[network] INFO: Successfully fetched and cached new token (expires in 59 minutes | 59 seconds).
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/chapter_recitations/6/1?segments=false
  Mushaf[network] INFO: Successfully received response from chapter_recitations/6/1?segments=false
  00:03 +3: QuranComApiClient Integration Test should fail gracefully when requesting an invalid chapter (e.g., 115)

  --- TEST: Edge Case - Invalid Chapter ---
  Fetching audio for non-existent chapter 115...
  Mushaf[network] INFO: Fetching new OAuth2 token...
  Mushaf[network] INFO: Successfully fetched and cached new token (expires in 59 minutes | 59 seconds).
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/chapter_recitations/7/115?segments=true
  Mushaf[network] ERROR: Failed to get data from Quran.com API: status 404 , error {"details":{"status":404,"error":"Surah number or slug is invalid. Please select valid s✅ Successfully caught expected error for invalid chapter:
  ccess":false}
  00:04 +4: QuranComApiClient Integration Test should handle token caching and 401 recovery on real API

  --- TEST: Sequential Calls (Caching) ---
  Executing Call 1...
  Mushaf[network] INFO: Fetching new OAuth2 token...
  Mushaf[network] INFO: Successfully fetched and cached new token (expires in 59 minutes | 59 seconds).
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/resources/recitations
  Mushaf[network] INFO: Successfully received response from resources/recitations
  ✅ Call 1 completed in 687 ms
  Executing Call 2 (Should be faster, using cached token)...
  Mushaf[network] INFO: Sending GET request to https://apis-prelive.quran.foundation/content/api/v4/resources/recitations
  Mushaf[network] INFO: Successfully received response from resources/recitations
  ✅ Call 2 completed in 90 ms
  Call 1 time: 687 ms, Call 2 time: 90 ms
  Faster by 597 ms (Expected due to token caching and no re-authentication)
  ✅ Sequential calls successful.
  00:05 +5: All tests passed!
  ```

### 2.6 - Security Refinement: API Headers
**Date:** 9th Mar 2026

- **Issue:** `x-client-secret` was being incorrectly sent in authenticated GET requests in `QuranComApiClient._getWithAuth`.
- **Finding:** Authenticated resource requests should only carry the `x-auth-token` and `x-client-id`. The `x-client-secret` is strictly for the OAuth2 token exchange flow.
- **Action:** Removed `x-client-secret` from the `headers` map in `_getWithAuth`.
- **Verification:** Verified that `_fetchNewToken` still correctly includes the secret for the initial handshake/refresh, while resource requests are now properly scoped.

---

### Phase 3 – Adapting to `MushafAudioDataSource` Architecture
**Date:** 9th Mar 2026

**Maintainer Feedback & Architecture Update:**
The maintainer confirmed the use of **Dart Named Records** for `QuranComVerseTiming` segments and approved the extension of `MushafAudioDataSource` with `fetchChapterTiming`.

**Current Status:**
The design for the API client and the interface extension strategy is ready. The next steps involve the manual implementation of these components as per the project requirements.

**Next Steps:**
- Formulate the `QuranComDataSource` implementation.
- Refactor `AyahTimingService` to handle lazy timing loads.

**The `MushafAudioDataSource` Protocol:**
```dart
abstract class MushafAudioDataSource {
  Future<List<ReciterInfo>> fetchAllReciters();
  Future<ReciterTiming?> fetchReciterTiming(int reciterId);
  Future<String?> fetchChapterAudioUrl(int reciterId, int chapterNumber);
  Future<List<QuranComVerseTiming>?> fetchChapterTiming(int reciterId, int chapterNumber);
}
```

**Architectural Resolution:**
There is a fundamental difference in how Quran.com provides audio timings compared to the built-in/CMS sources:
- **CMS/Built-in:** All timings for all 114 chapters for a reciter are bundled in a single JSON file.
- **Quran.com:** Timings are fetched *per chapter*, dynamically, alongside the audio URL (`/chapter_recitations/{reciter_id}/{chapter_number}`).

If we strictly implement `fetchReciterTiming(int reciterId)` by fetching all 114 chapters from Quran.com, it will trigger 114 separate API requests, causing extreme latency and likely hitting rate limits.

**Maintainer Decision & Solution:**
1. Keep the `QuranComApiClient` untouched; it successfully maps to the API endpoints.
2. Build `QuranComDataSource implements MushafAudioDataSource`.
3. In `fetchChapterAudioUrl(reciterId, chapterNumber)`: Call the API. We get *both* the URL and the timings for that chapter. We will cache the timings in-memory if needed.
4. **Interface Extension**: The maintainers approved extending `MushafAudioDataSource` with a `fetchChapterTiming(reciterId, chapterNumber)` method. This elegantly prevents the 114-request issue while preserving the plug-and-play architecture.
5. In Phase 3, we will refactor `AyahTimingService` to gracefully support lazy timing loads using this new method.



---

### 2.7 - Robustness & Reliability Refinements
**Date:** 12th Mar 2026

Following a secondary audit of the API client and data models, several refinements were made to ensure production-grade robustness:

- **Retry Logic Validation:**
  - **Issue:** The retry branch in `_getWithAuth` bypassed follow-up non-200 status code guards.
  - **Action:** Refactored to assign the retried response to the local `response` variable, ensuring it undergoes the same validation checks.
  - **Regression Test:** Added a test case for "401 followed by 500" to verify exceptions are correctly thrown.

- **Numeric Type Safety (Safe Casting):**
  - **Issue:** API responses might return integers as doubles (e.g., `100.0`), which causes `as int` casts to fail in Dart.
  - **Action:** Implemented `(json['field'] as num).toInt()` pattern across all models (`QuranComVerseTiming`, `QuranComAudioFile`, `QuranComReciter`).
  - **Scope:** Applied to timestamps, durations, word indices, and entity IDs.

- **Defensive JSON Parsing:**
  - **Action:** Updated response wrappers (`QuranComChapterAudioResponse`, `QuranComRecitationsResponse`) to explicitly check for null/missing root keys and throw a descriptive `FormatException`.

- **Test Infrastructure Polish:**
  - **Clean Skip:** Used the `skip` facility for integration tests when credentials are missing, preventing "silent failures" or "fake passes".
  - **Resource Leak Prevention:** Added `tearDown` blocks to ensure `apiClient.dispose()` is called after each test, closing the underlying HTTP client sockets.

---
