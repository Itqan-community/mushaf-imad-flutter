# 1421 Mushaf Support

This document describes the 1421 Mushaf support added to the mushaf-imad-flutter library.

## Overview

The 1421 Mushaf support adds a third Mushaf layout option alongside the existing 1441 (modern) and 1405 (traditional) layouts.

## Changes Made

### 1. Extended MushafType Enum (`lib/src/domain/models/mushaf_type.dart`)

Added `hafs1421` variant to the `MushafType` enum:

```dart
enum MushafType {
  hafs1441,  // Modern layout (1441 Hijri)
  hafs1405,  // Traditional layout (1405 Hijri)
  hafs1421,  // Madani Mushaf layout (1421 Hijri) - NEW
}
```

### 2. Font Assets Directory (`assets/fonts/1421/`)

Created the font assets directory for 1421-specific fonts:

```
assets/fonts/1421/
```

Place the `Hafs1421.ttf` font file in this directory to enable 1421 font rendering.

### 3. MushafFontService (`lib/src/data/fonts/mushaf_font_service.dart`)

Created a service for managing and loading Mushaf-specific fonts:

- Loads fonts dynamically based on Mushaf type
- Provides font family names for text rendering
- Handles font size and line height multipliers per Mushaf type

Usage:
```dart
final fontService = MushafFontService();
await fontService.initialize();

// Get font family for specific Mushaf type
String fontFamily = fontService.getFontFamily(MushafType.hafs1421);
```

### 4. Updated Verse Models

Extended the `Verse` model to include 1421 marker and highlight data:

```dart
class Verse {
  // ... existing fields ...
  final VerseMarker? marker1421;  // NEW
  final List<VerseHighlight> highlights1421;  // NEW
}
```

Updated `PageVerseData` in `verse_data_provider.dart` to support 1421:

```dart
class PageVerseData {
  // ... existing fields ...
  final VerseMarkerData? marker1421;  // NEW
  final List<VerseHighlightData> highlights1421;  // NEW
  
  // Helper methods for different Mushaf types
  VerseMarkerData? getMarkerForMushafType(String mushafType);
  List<VerseHighlightData> getHighlightsForMushafType(String mushafType);
}
```

### 5. MushafPageWidget (`lib/src/ui/mushaf/mushaf_page_widget.dart`)

Created a new widget that supports all three Mushaf layouts (1441, 1421, 1405):

```dart
MushafPageWidget(
  pageNumber: 1,
  mushafType: MushafType.hafs1421,
  selectedVerseKey: selectedVerse,
  onVerseTap: (chapter, verse) => handleVerseTap(chapter, verse),
)
```

### 6. Settings Integration

Updated `SettingsViewModel` to support changing Mushaf type:

```dart
await _viewModel.setMushafType(MushafType.hafs1421);
```

Updated `SettingsPage` with a dropdown selector for Mushaf type:

- Displays human-readable labels (Hafs 1441, Hafs 1405, Hafs 1421)
- Shows descriptions for each Mushaf type
- Persists selection via PreferencesRepository

### 7. pubspec.yaml Updates

Added 1421 font assets and font family configuration:

```yaml
flutter:
  assets:
    - assets/fonts/1421/
  
  fonts:
    - family: QuranNumbers
      fonts:
        - asset: assets/fonts/QuranNumbers.ttf
    - family: Hafs1421  # NEW
      fonts:
        - asset: assets/fonts/1421/Hafs1421.ttf
```

## Usage

### Selecting 1421 Mushaf Type

```dart
// Via Settings
await preferencesRepository.setMushafType(MushafType.hafs1421);

// Via MushafViewModel
await mushafViewModel.setMushafType(MushafType.hafs1421);
```

### Rendering 1421 Pages

```dart
MushafPageWidget(
  pageNumber: currentPage,
  mushafType: MushafType.hafs1421,
  onVerseTap: (chapter, verse) {
    // Handle verse selection
  },
)
```

### Loading 1421 Fonts

```dart
final fontService = MushafFontService();
await fontService.loadFontForMushafType(MushafType.hafs1421);

// Check if font is available
if (fontService.isFontAvailable(MushafType.hafs1421)) {
  // Use 1421 font
}
```

## Data Requirements

To fully utilize the 1421 Mushaf support, the verse data JSON (`assets/quran_verse_data.json`) should include:

```json
{
  "pages": {
    "1": [
      {
        "id": 1,
        "number": 1,
        "chapter": 1,
        "text": "...",
        "marker1421": {
          "line": 5,
          "centerX": 0.5,
          "centerY": 0.5,
          "numberCodePoint": "\u0661"
        },
        "highlights1421": [
          {"line": 5, "left": 0.1, "right": 0.9}
        ]
      }
    ]
  }
}
```

## Migration Notes

- Existing code using `QuranPageWidget` continues to work (defaults to 1441 layout)
- New code should use `MushafPageWidget` for multi-layout support
- The `hafs1421` Mushaf type is optional and gracefully degrades if font/data is unavailable

## Future Enhancements

- Add 1421 page images to `assets/quran-images/`
- Implement 1421-specific audio timing
- Add 1421 layout comparison tool
