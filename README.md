# IMAD Flutter - Mushaf Package

Add mushaf to your Flutter application easily! A fully functional, modular Quran reader library with display, bookmarks, search, offline data storage, and more.

[![Flutter](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-0.0.2-blue.svg)]()

---

## ✨ Features

- 📖 **Full Quran Text Display** (604 pages) leveraging beautifully rendered images.
- 🎨 **Multiple Reading Themes** (Comfortable, Calm, Night, White) for optimal accessibility.
- 💾 **Offline-first Architecture** powered by [Hive](https://pub.dev/packages/hive) for user data and static Quran metadata.
- 🔍 **Unified Search Functionality** (Search Verses, Chapters, and Bookmarks).
- 🔖 **Bookmarks and Reading History** system mapping natively to UI components.
- 🏗️ **Clean Modular Architecture** with a strict separation of domain, data, and UI layers.
- 🧩 **Ready-to-use UI Components:** (`MushafPageView`, `QuranPageWidget`, `SearchPage`, `SettingsPage`, `ChapterIndexDrawer`, etc.)
- 🎵 **Audio Playback** (Under development). 

---

## ⚙️ Requirements

- **Dart SDK**: `>= 3.11.0`
- **Flutter**: `>= 1.17.0`

---

## 🚀 Quick Start

### 1. Add Dependency

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  imad_flutter: ^0.0.1
```

### 2. Download Quran Images

> ⚠️ **Important:** The `quran-images/` directory (~9,000+ PNG files) is **not included** in the pub.dev package due to size limitations. You must download it separately from the [GitHub repository](https://github.com/Itqan-community/mushaf-imad-flutter).

```bash
# Clone or download the quran-images directory from the repo
git clone https://github.com/Itqan-community/mushaf-imad-flutter.git
# Copy quran-images into your project's package cache or use a path dependency
```

If you're using a **path dependency** (recommended during development):
```yaml
dependencies:
  imad_flutter:
    path: ../mushaf-imad-flutter  # already includes quran-images/
```

### 3. Initialization & Setup

The library uses `Hive` for its local database and requires initialization before the app runs.

```dart
import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // One-line setup! Initializes Hive, provisions Quran metadata, 
  // and injects dependencies via get_it.
  await setupMushafWithHive();
  
  runApp(const MyApp());
}
```

### 4. Basic Usage (Displaying the Mushaf)

Once initialized, simply instantiate the `MushafPageView`.

```dart
import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

class MushafScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mushaf')),
      // Providing a bare-minimum Theme Scope
      body: MushafThemeScope(
        notifier: ThemeViewModel()..setTheme(ReadingTheme.comfortable),
        child: MushafPageView(
          initialPage: 1, // Start at Al-Fatihah
        ),
      ),
    );
  }
}
```

---

## 🛠️ Exploring UI Components

The `imad_flutter` library provides ready-made screens and widgets for immediate integration.

### Search Functionality

The built-in unified search queries Verses, Chapters, and Bookmarks all at once:

```dart
import 'package:imad_flutter/imad_flutter.dart';

// Just navigate to the built in SearchPage!
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SearchPage()),
);
```

### Table of Contents / IndexDrawer

Easily access any Surah or Juz:

```dart
Scaffold(
  drawer: const ChapterIndexDrawer(), // Surah / Juz selection drawer
  body: MushafPageView(initialPage: 1),
);
```

### Theming 

You can update themes dynamically. Wrap your Mushaf pages with `MushafThemeScope`.

```dart
enum ReadingTheme {
  comfortable,  // Light green
  calm,         // Light blue
  night,        // Dark theme 
  white,        // Pure white 
}
```

---

## 🏗️ Architecture Setup & Customization

The library is strictly modular:
- **Domain Layer:** Encompasses models (e.g., `Verse`, `Chapter`, `Bookmark`) and repository abstractions.
- **Data Layer:** Utilizes `Hive` for DAOs (`HiveBookmarkDao`, `HiveReadingHistoryDao`, etc.)
- **UI Layer:** Views and ViewModels employing native `ChangeNotifier`.

All core dependencies are registered centrally via `get_it`. If you wish to use your own database engine, simply implement the abstract repository protocols and pass them manually.

```dart
setupMushafDependencies(
  databaseService: MyCustomDatabaseService(),
  bookmarkDao: MyCustomBookmarkDao(),
  // ...
);
```

---

## 📝 Demo App

Navigate to the internal `example` directory to run the full presentation sample that demonstrates everything the library offers:

```bash
cd example
flutter run
```

---

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
