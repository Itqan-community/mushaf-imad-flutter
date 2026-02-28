# Quran.com Audio Feature – Development Log

This log documents the journey of implementing **Quran.com API as an audio source** for the `mushaf-imad-flutter` package (issue `#8`).  
It is meant for both **reviewers** and **future contributors** to understand the reasoning and steps taken.

## Table of Contents

- [Overview](#overview)
- [Phase 0 – Setup & Baseline](#phase-0--setup--baseline)
  - [0.1 – Repository setup and remotes](#01--repository-setup-and-remotes)
  - [0.2 – Syncing main and creating the feature branch](#02--syncing-main-and-creating-the-feature-branch)
  - [0.3 – Dependency resolution and static analysis](#03--dependency-resolution-and-static-analysis)
  - [0.4 – Checklists and logging setup](#04--checklists-and-logging-setup)
- [Next Phase – Phase 1: API Research & Credential Strategy](#next-phase--phase-1-api-research--credential-strategy)
- [Phase 1 – API research & decisions](#phase-1--api-research--decisions)
  - [Steps performed](#steps-performed)
  - [Observations & answers](#observations--answers)
  - [Next](#next)


---

## Overview

- **Repository (fork)**: `Mamdouh-Attia/mushaf-imad-flutter`
- **Upstream (original)**: `Itqan-community/mushaf-imad-flutter`
- **Feature branch**: `feature/qurancom-audio`
- **Goal**: Add Quran.com (Quran Foundation) API as an optional audio source alongside the existing local audio implementation, with clean architecture, tests, and documentation.
- **Companion docs**:
  - Task checklist: `doc/QURAN_COM_CHECKLIST.md`

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
  - `doc/QURAN_COM_CHECKLIST.md`
  - The checklist mirrors the main phases from `QURAN_COM_ROADMAP.md`, but breaks them into small, commit-sized tasks with Markdown checkboxes.
- Established this development log (`doc/QURAN_COM_DEVELOPMENT_LOG.md`) to:
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



