# Automated Publishing to pub.dev

This project uses Google Dart's official automated publishing workflow to publish `imad_flutter` to [pub.dev](https://pub.dev/packages/imad_flutter) via GitHub Actions using OpenID Connect (OIDC).

## How It Works

1. When a new version is ready, update the version in `pubspec.yaml` and add a corresponding entry in `CHANGELOG.md`.
2. When a release is published on GitHub (via GitHub Releases or by publishing the draft prepared by Release Drafter), GitHub creates and pushes the release tag (e.g., `v1.1.1`).
3. The `.github/workflows/publish.yml` workflow triggers automatically on version tag pushes matching `v*` (or numeric version tags).
4. The workflow authenticates with pub.dev using short-lived OIDC tokens (no long-lived credentials or secret tokens required).
5. The official reusable workflow (`dart-lang/setup-dart/.github/workflows/publish.yml@v1`) runs verification and publishes the package to pub.dev.

## One-Time Setup on pub.dev

To enable automated publishing for the first time, a package uploader or publisher admin must configure the repository on pub.dev:

1. Go to https://pub.dev/packages/imad_flutter/admin
2. Under **Automated publishing**, click **Enable publishing from GitHub Actions**.
3. Fill in the repository details:
   - **Repository**: `Itqan-community/mushaf-imad-flutter`
   - **Tag pattern**: `v{{version}}`
4. Save the configuration.

## Publishing a Release

### Option A: Via GitHub Releases UI (Recommended)

1. Open the repository on GitHub and navigate to **Releases**.
2. Click **Draft a new release** (or open the draft release created by Release Drafter).
3. Select or type the version tag (e.g., `v1.1.1`) matching the version in `pubspec.yaml`.
4. Enter the release title and release notes.
5. Click **Publish release**.
6. GitHub pushes the tag, which triggers the `Publish to pub.dev` action automatically.

### Option B: Via Git CLI

1. Ensure your working directory is clean on `main`.
2. Create and push the release tag:
   ```bash
   git tag v1.1.1
   git push origin v1.1.1
   ```
3. The GitHub Actions workflow will automatically validate and publish the package.
