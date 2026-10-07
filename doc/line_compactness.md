# Line Compactness and Spacing

This document describes how line compactness, spacing, and image overlapping are configured and customized in the `imad_flutter` package.

---

## Overview

In the printed Mushaf, the 15 lines on each page are laid out with balanced vertical density. The line image assets in the package are sized at 1440 x 232 pixels, with roughly 35 pixels of transparent padding at the top and 45 pixels at the bottom (about 35% total padding) to accommodate Arabic ascenders and descenders.

Previously, `QuranPageWidget` expanded all 15 lines evenly using `Expanded` widgets inside a `Column`. On modern tall mobile displays, this introduced large vertical gaps between lines.

With `LineCompactness`, developers can adjust the vertical density using presets, continuous numerical scales, or direct picture overlap percentages, providing authentic Mushaf layouts across any aspect ratio.

---

## The `LineCompactness` Model

The `LineCompactness` class (`package:imad_flutter/src/domain/models/line_compactness.dart`) controls line spacing and overlap between adjacent lines.

### Presets

| Preset | Spacing Factor | Overlap | Description |
|---|---|---|---|
| `LineCompactness.ultraCompact` | `0.55` | 45% | Maximum compactness with heavy picture overlap. Minimal margins between calligraphy lines. |
| `LineCompactness.tight` | `0.65` | 35% | Tight spacing with 35% picture overlap. Excellent for tall phone screens. |
| `LineCompactness.compact` | `0.75` | 25% | Compact layout with 25% picture overlap. Authentic printed Mushaf feel. |
| `LineCompactness.normal` | `0.85` | 15% | Balanced default setting for mobile and tablet readers. |
| `LineCompactness.loose` | `1.00` | 0% | Lines placed edge-to-edge with no picture overlap. |
| `LineCompactness.expanded` | `null` | 0% | Legacy mode where lines stretch equally to fill the full viewport height. |

### Continuous Numerical Scale

Developers can specify any numerical factor directly to fine-tune spacing:

```dart
// Custom spacing factor (e.g., 0.60 for 40% overlap)
final custom = LineCompactness(0.60);

// Or via custom named constructor:
final custom = LineCompactness.custom(0.60);
```

### Overlap-Based Construction

When thinking in terms of how much adjacent pictures should overlap:

```dart
// Explicit overlap fraction (e.g., 0.35 = 35% picture overlap)
final overlap = LineCompactness.withOverlap(0.35);
```

### Normalized Compactness Scale

Using a normalized scale from 0.0 (loose) to 2.0 (ultra-compact):

```dart
// 0.0 = loose (1.0 factor), 1.0 = compact (0.70 factor), 1.5 = tight (0.55 factor)
final scaled = LineCompactness.fromScale(1.2);
```

---

## Picture Overlapping and Gesture Dispatch

When lines overlap (`factor < 1.0`), adjacent line images interleave their transparent padding. This eliminates empty vertical space without clipping Arabic letterforms.

### Hit-Testing Architecture

In a Flutter `Stack`, later children are rendered higher in the Z-order. If line images overlap, a naive stack would cause line N+1's transparent upper border to intercept tap events meant for line N.

The library resolves this using `_LineHitTestScope`. Each line only intercepts touches within its own geometric half of the overlap:
- For line 0, all touches inside its box are accepted.
- For line N > 0, touches in the top half of the overlap (`y < (lineHeight - step) / 2`) fall through to line N-1.

This guarantees:
1. Verse tap accuracy is 100% exact regardless of overlap depth.
2. No touch overlay is needed on top of the Stack, allowing line widgets to receive hits directly.
3. Accessibility and semantics trees remain directly attached to each line.

---

## Usage Examples

### 1. In `MushafPageView`

Pass `lineCompactness` with either a numerical scale, preset, or overlap configuration:

```dart
// Continuous numerical scale:
MushafPageView(
  initialPage: 1,
  lineCompactness: LineCompactness(0.65), // 65% spacing, 35% picture overlap
)

// Presets:
MushafPageView(
  initialPage: 1,
  lineCompactness: LineCompactness.tight,
  pagePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
)

// Overlap-based:
MushafPageView(
  initialPage: 1,
  lineCompactness: LineCompactness.withOverlap(0.40),
)
```

### 2. In `QuranPageWidget`

```dart
// Using numerical factor:
QuranPageWidget(
  pageNumber: 1,
  lineCompactness: LineCompactness(0.60),
)

// Using overlap constructor:
QuranPageWidget(
  pageNumber: 1,
  lineCompactness: LineCompactness.withOverlap(0.40),
)
```

### 3. Application-Wide via `MushafThemeScope`

Compactness can be configured globally and reactively updated throughout the application:

```dart
final themeNotifier = MushafThemeNotifier(
  initialTheme: ReadingTheme.light,
  initialCompactness: LineCompactness.compact,
);

// In your root widget:
MushafThemeScope(
  notifier: themeNotifier,
  child: MyApp(),
)

// Update anywhere in the widget tree:
MushafThemeScope.of(context).setCompactness(LineCompactness.ultraCompact);
```

### 4. Settings UI with Interactive Slider

The library's `SettingsPage` includes a line compactness dialog featuring an interactive slider (range 30% to 110%) with live spacing and overlap percentage readouts, along with quick preset chips.

### 5. Persistence via `PreferencesRepository`

`PreferencesRepository` provides storage and a stream for user-selected line compactness:

```dart
final prefs = mushafGetIt<PreferencesRepository>();

// Read current preference
final current = await prefs.getLineCompactness();

// Observe changes
prefs.getLineCompactnessStream().listen((compactness) {
  print('Line compactness changed: ${compactness.displayName}');
});

// Save updated preference
await prefs.setLineCompactness(LineCompactness(0.70));
```

---

## String Parsing

The `LineCompactness.fromName` method parses preset identifiers, decimal numbers, and percentages:

```dart
LineCompactness.fromName('tight');        // LineCompactness.tight
LineCompactness.fromName('ultraCompact'); // LineCompactness.ultraCompact
LineCompactness.fromName('0.65');         // LineCompactness(0.65)
LineCompactness.fromName('65%');          // LineCompactness(0.65)
LineCompactness.fromName('65');           // LineCompactness(0.65)
```
