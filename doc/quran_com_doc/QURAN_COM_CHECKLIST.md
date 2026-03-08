# Quran.com Audio Feature – Incremental Checklist

This checklist is meant to be **ticked as you go**.  
Each checkbox is a small, focused step that can usually be its own commit.

---

## Phase 0 – Repo, Remotes, Branch, Dev Log

### 0.1 – Local repos & remotes

- [x] **Verify local fork repo**
  - [x] Confirm `d:\dev\OpenSrcContreibutions\mushaf-imad-flutter` exists and opens in your IDE.
- [x] **Verify original repo URL**
  - [x] Open the original GitHub repo in the browser and copy its HTTPS URL (for `upstream`).
- [x] **Configure remotes in fork**
  - [x] From inside `mushaf-imad-flutter`, run `git remote -v` and check `origin` points to your fork.
  - [x] If missing, add `upstream` → original repo URL.
  - [x] Re-run `git remote -v` and confirm both `origin` and `upstream` are present.
- [x] **Sync local main with upstream**
  - [x] `git checkout main`
  - [x] `git fetch upstream`
  - [x] `git merge upstream/main` **or** `git rebase upstream/main` (pick one workflow).
  - [x] Resolve any conflicts and `git push origin main`.

### 0.2 – Feature branch

- [x] **Create and switch to feature branch**
  - [x] From `main`, run `git checkout -b feature/qurancom-audio`.
  - [x] Run `git status` and confirm `On branch feature/qurancom-audio`.

### 0.3 – Baseline health check

- [x] **Project health**
  - [x] Run `flutter pub get`.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test`.
- [x] **Example sanity check**
  - [x] Run the example app on a device/emulator and confirm it builds and plays audio.

### 0.4 – Development log skeleton

- [x] **Create dev log file**
  - [x] Create `doc/QURAN_COM_DEVELOPMENT_LOG.md` (or `DEVELOPMENT_LOG.md`).
  - [x] Add an **Overview** section (issue #8, branch name, goal).
  - [x] Add `## Phase 0 – Setup` section ready to fill.
- [x] **Fill Phase 0 entry**
  - [x] Describe the commands you ran and any issues you solved.
- [x] **Commit**
  - [x] Commit message: `docs(qurancom): add development log and initial setup`.

---

## Phase 1 – API Research, Environments & Credential Strategy

### 1.1 – Understand the API shape (content endpoints)

- [x] **Re-read Quran Foundation docs**
  - [x] Re-read docs for `GET /recitations` (reciter list).
  - [x] Re-read docs for `GET /chapter_recitations/{id}/{chapter_number}` (audio + timings).
- [x] **Capture sample responses (local only, not committed)**
  - [x] Using Postman/cURL **against the pre-production environment only**, call `/recitations` and save one JSON sample for reference.
  - [x] Call `/chapter_recitations/{id}/{chapter_number}` with a valid reciter id + a simple chapter (e.g. 1) and save one JSON sample.
- [x] **Compare docs vs real JSON**
  - [x] List key fields for reciters (e.g. id, English/Arabic names, style, any base path/url fields).
  - [x] List key fields for chapter audio/timings (chapter number, url, duration, verse timings).
  - [x] Note any differences or surprises to guide the Dart models in Phase 2.

### 1.2 – Environment selection (prelive vs production)

- [x] **Decide environment usage for development**
  - [x] Confirm that all development and testing will target **Pre-Production (prelive)** only.
  - [x] Record the official base URLs from the docs:
    - [x] Prelive auth: `https://prelive-oauth2.quran.foundation`
    - [x] Prelive API:  `https://apis-prelive.quran.foundation`
    - [x] Production auth: `https://oauth2.quran.foundation`
    - [x] Production API:  `https://apis.quran.foundation`
- [x] **Define an environment enum/config concept**
  - [x] Plan for a small Dart enum or config flag (e.g. `QuranComEnvironment.prelive` / `production`) that will later map to these URLs in `QuranComApiConfig`.

### 1.3 – Credential handling (client id/secret) and placeholders

- [x] **Decide how to store real keys locally (never committed)**
  - [x] Choose a pattern such as (I decided to provide placeholders in tracked code) possibly combined with either:
    -  A local, gitignored Dart file (e.g. `example/lib/qurancom_secrets.dart`) exporting constants, **or**
    - `--dart-define` values passed at run time.
- [x] **Confirm what should be passed into the library**
  - [x] Decide that real `clientId`, `clientSecret` and environment will be supplied via a `QuranComApiConfig` object created by the host app (or its backend), not hard-coded inside the package.
- [x] **Decide placeholder format for repo and docs**
  - [x] Choose clear placeholders for tracked code, e.g.:
    - [x] `"YOUR_QURAN_CLIENT_ID_HERE"`
    - [x] `"YOUR_QURAN_CLIENT_SECRET_HERE"`
    - [x] `"YOUR_QURAN_ENVIRONMENT_HERE (prelive/production)"`

### 1.4 – Token lifecycle understanding (for later implementation)

- [x] **Review token flow in official docs**
  - [x] Confirm the flow is **OAuth2 Client Credentials** (no refresh token).
  - [x] Note that tokens are valid for ~1 hour (`expires_in`), then must be **re-requested** using the same `/oauth2/token` endpoint.
  - [x] Note that the content scope to request is `scope=content`.
- [x] **Plan caching behaviour for Phase 2**
  - [x] Decide to cache `{ accessToken, expiresAtMs }` in memory and re-request 30 seconds before expiry.
  - [x] Decide to clear cache and re-request once on a `401` from the API.

### 1.5 – Document Phase 1

- [x] **Update development log**
  - [x] In `QURAN_COM_DEVELOPMENT_LOG.md`, add `## Phase 1 – API research & decisions` summarizing:
    - [x] The specific endpoints and example responses you inspected.
    - [x] The environment strategy (prelive only for dev; production reserved for real deployments).
    - [x] The credential storage strategy (local-only secrets + placeholders in tracked code).
    - [x] The planned token lifecycle and caching behaviour for the Dart client.
- [x] **Commit (if you changed tracked files, e.g. docs or .gitignore)**
  - [x] Commit message: `docs(qurancom): document api research, envs, and credential strategy`.

---

## Phase 2 – Data Models & API Client

### 2.1 – Folder and dependencies

- [x] **Create Quran.com folder**
  - [x] Under `lib/src/data/audio/`, create `qurancom/`.
- [x] **Dependencies**
  - [x] In `pubspec.yaml`, ensure `http` is in `dependencies`.
  - (Optional) Add `json_annotation` to `dependencies`.
  - (Optional) Add `build_runner` and `json_serializable` to `dev_dependencies`.
  - [x] Run `flutter pub get`.
- [x] **Commit**
  - [x] Commit message: `chore(qurancom): add http dependency and qurancom folder`.

### 2.2 – Reciter models

- [x] **Add `QuranComReciter`**
  - [x] Create `lib/src/data/audio/qurancom/qurancom_reciter.dart`.
  - [x] Add fields matching real reciter JSON (id, name, arName, style, etc.).
  - [x] Implement `fromJson`/`toJson` (manual or `json_serializable`).
- [x] **Optional wrapper**
  - [x] Add a `RecitationsResponse` if the API wraps reciters in a `recitations` array.
- [x] **Quick parse check**
  - [x] Parse your saved reciters JSON and assert at least one reciter with expected fields.
- [x] **Commit**
  - [x] Commit message: `feat(qurancom): add reciter api model`.

### 2.3 – Chapter audio + timing models

- [x] **Add timing model**
  - [x] In `qurancom_chapter_audio.dart`, add a `QuranComVerseTiming` (or similar) with `verse_key`, `timestamp_from`, `timestamp_to`, and optional `segments`.
  - [x] unit test parsing this timing model from your saved chapter JSON.
- [x] **Add audio file model**
  - [x] Add `QuranComAudioFile` (chapter number, url, duration, list of `timestamps`).
  - [x] Add unit tests for parsing this model from your saved chapter JSON.
- [x] **Add wrapper `ChapterAudioResponse`**
  - [x] Matches the `audio_file` top-level field returned by the API.
  - [x] unit test parsing this wrapper as well.
- [x] **Quick parse check**
  - [x] Parse saved chapter JSON, check chapter number, URL, and timing count.
- [x] **Commit**
  - [x] Commit message: `feat(qurancom): add chapter audio and timing models`.

### 2.4 – QuranComApiClient

- [x] **Config object**
  - [x] Add `QuranComApiConfig` with `clientId`, `clientSecret`, and `environment`.
- [x] **OAuth2 Token Generation & Caching**
  - [x] Implement token retrieval using client credentials flow.
  - [x] Cache token in memory with expiry handling.
- [x] **Client implementation**
  - [x] Create `qurancom_api_client.dart`.
  - [x] Implement `fetchReciters`.
  - [x] Implement `fetchChapterAudio`.
  - [x] Add 401 Unauthorized retry logic.
- [x] **Client tests**
  - [x] Add unit tests for `QuranComApiClient`.
  - [x] Add integration tests for real-world functionality.
- [x] **Dev log**
  - [x] Add `## Phase 2.4 – API client details` and debugging logs.
- [x] **Commit**
  - [x] Commit message: `feat(qurancom): implement api client with oauth2 token management`.

---

## Phase 3 – Data Source Integration (MushafAudioDataSource)

### 3.1 – QuranComDataSource Implementation

- [ ] **Create data source class**
  - [ ] Create `qurancom_data_source.dart` implementing `MushafAudioDataSource`.
  - [ ] Inject `QuranComApiClient` into its constructor.
- [ ] **Implement `fetchAllReciters`**
- [ ] **Implement `fetchChapterAudioUrl`**
- [ ] **Implement `fetchChapterTiming`**
- [ ] **Recorded in dev log**
- [ ] **Implement `fetchAllReciters`**
  - [ ] Call `apiClient.fetchReciters()`.
  - [ ] Map `QuranComReciter` to domain `ReciterInfo`.
  - [ ] Memoize/cache the result to prevent duplicate calls.
- [ ] **Implement `fetchChapterAudioUrl`**
  - [ ] Call `apiClient.fetchChapterAudio(reciterId, chapterNumber)`.
  - [ ] Return the audio `url`.
  - [ ] *Crucial:* In-memory cache the `timestamps` returned by this call so they can be provided to the player.
- [x] **Address `fetchReciterTiming` architecture mismatch**
  - [x] Since Quran.com provides timings per-chapter and *not* per-reciter, discuss with maintainer (@ma9ni / @hassaanalansary).
  - [x] **Resolution:** Maintainer agreed to extend the interface for a "common denominator".
- [ ] **Modify `MushafAudioDataSource` Interface**
  - [ ] Add `Future<ChapterTiming?> fetchChapterTiming(int reciterId, int chapterNumber)` to the abstract class.
- [ ] **Refactor `AyahTimingService`**
  - [ ] Update `loadTimingData` to support lazily fetching from `fetchChapterTiming` if the bulk `fetchReciterTiming` returns null.
- [ ] **Implement `QuranComDataSource`**
  - [ ] Implement `fetchChapterTiming` by calling `apiClient.fetchChapterAudio`.
- [ ] **Tests**
  - [ ] Add `test/src/data/audio/quran_com/qurancom_data_source_test.dart`.
  - [ ] Test the mapping and caching logic.
- [ ] **Commit**
  - [ ] Commit message: `feat(qurancom): implement MushafAudioDataSource for qurancom`.

---

## Phase 4 – Configuration & UI Initialization

### 4.1 – Enums & Config

- [ ] **Update MushafAudioSource enum**
  - [ ] Add `quranCom` to the `MushafAudioSource` enum (if not added by PR #24).
- [ ] **QuranComAudioSourceConfig**
  - [ ] Build `QuranComAudioSourceConfig` (similar to `CmsAudioSourceConfig`) holding environment URLs and Client credentials.
- [ ] **Commit**
  - [ ] Commit message: `feat(qurancom): add config and enum support`.

### 4.2 – Initialization Wiring

- [ ] **Extend entrypoint**
  - [ ] Within the core initialization flow, intercept when `MushafAudioSource.quranCom` is chosen.
  - [ ] Instantiate `QuranComApiClient`.
  - [ ] Provide `QuranComDataSource` to whichever orchestrator/repository consumes `MushafAudioDataSource`.
- [ ] **Commit**
  - [ ] Commit message: `feat(audio): wire qurancom data source into library initialization`.

---

## Phase 6 – Example App & UI

### 6.1 – Example initialization

- [ ] **Update example main**
  - [ ] In `example/lib/main.dart`, show:
    - [ ] Initialization with local source.
    - [ ] Initialization with Quran.com source using placeholder credentials.
- [ ] **Reciter list + play**
  - [ ] Ensure example reads `AudioRepository` from DI.
  - [ ] Load and display reciters, allow selection, play a simple surah.

### 6.2 – (Optional) Source switcher UI

- [ ] **Toggle widget**
  - [ ] Add a minimal widget to toggle between `local` and `qurancom`.
  - [ ] Reinitialize the library on change and refresh UI.

- [ ] **Dev log**
  - [ ] Add `## Phase 6 – Example & UI`.
- [ ] **Commit**
  - [ ] Commit message: `feat(example): demonstrate qurancom audio source`.

---

## Phase 7 – Testing & Cleanup

### 7.1 – Tests and analyzer

- [ ] **Run tests**
  - [ ] `flutter test` passes.
- [ ] **Run analyzer**
  - [ ] `flutter analyze` passes (or remaining issues are known/acceptable to maintainer).

### 7.2 – Optional integration tests

- [ ] **Integration test**
  - [ ] Add a simple integration test under `example/integration_test/` (or similar) to:
    - [ ] Initialize with `AudioSource.qurancom`.
    - [ ] Assert that reciters can be loaded and a chapter can start playing (mock or real).

### 7.3 – Cleanup

- [ ] **Formatting**
  - [ ] Run `dart format` / `flutter format` on `lib/`, `test/`, `example/`.
- [ ] **Commit history**
  - [ ] Optionally clean noisy WIP commits (rebase/squash if allowed).
- [ ] **Dev log**
  - [ ] Add `## Phase 7 – Tests & cleanup`.
- [ ] **Commit**
  - [ ] Commit message: `test(qurancom): finalize tests and cleanup`.

---

## Phase 8 – Documentation & PR

### 8.1 – README and docs

- [ ] **README**
  - [ ] Add an “Audio Sources” section (local vs Quran.com, initialization examples, link to credentials docs).
- [ ] **Walkthrough / architecture**
  - [ ] Update `doc/WALKTHROUGH.md` (or similar) with:
    - [ ] Short explanation of dual-source design.
    - [ ] How to plug your own `AudioRepository`.

### 8.2 – Changelog and checks

- [ ] **CHANGELOG**
  - [ ] Add entry describing the new Quran.com audio source, enum, initialization, and examples.
- [ ] **Pre-PR checks**
  - [ ] `flutter test` passes.
  - [ ] `flutter analyze` passes (or known issues).
  - [ ] Example app runs with both sources.
  - [ ] No real API keys/tokens in the repo.

### 8.3 – Draft PR

- [ ] **Create/update draft PR**
  - [ ] Open a draft PR from `feature/qurancom-audio` to `main`.
  - [ ] In description, include:
    - [ ] Overview of the feature.
    - [ ] Main changes (client, providers, repo, init, example).
    - [ ] How to test.
    - [ ] Link to `doc/QURAN_COM_DEVELOPMENT_LOG.md` for the full story.
- [ ] **Dev log final entry**
  - [ ] Add `## Phase 8 – Documentation & PR` with notes and PR link.
- [ ] **Commit**
  - [ ] Commit message: `docs(qurancom): finalize docs and prepare pr`.

---

## Usage Notes

- [ ] Use this file as your **main checklist** and keep it in sync with your progress.
- [ ] After ticking items here, update `QURAN_COM_DEVELOPMENT_LOG.md` with a short narrative for learning and for reviewers.

