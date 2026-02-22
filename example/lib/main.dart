import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupMushafWithHive();
  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MushafImad Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const LibraryHomePage(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Home Page — Main menu showing Core Library and UI Library sections
// ──────────────────────────────────────────────────────────────────────────────

class LibraryHomePage extends StatelessWidget {
  const LibraryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MushafImad Library'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Core Library Section ───
          _SectionHeader(
            title: 'Core Library',
            subtitle: 'mushaf-core: Data layer & repositories',
          ),
          _MenuCard(
            icon: Icons.list_alt,
            title: 'Chapters',
            subtitle: 'ChapterRepository - All 114 surahs',
            onTap: () => _push(context, const ChaptersPage()),
          ),
          _MenuCard(
            icon: Icons.text_snippet,
            title: 'Verses',
            subtitle: 'VerseRepository - Ayat data & search',
            onTap: () => _push(context, const VersesPage()),
          ),
          _MenuCard(
            icon: Icons.mic,
            title: 'Reciters',
            subtitle:
                'AudioRepository - ${ReciterDataProvider.allReciters.length} available reciters',
            onTap: () => _push(context, const RecitersPage()),
          ),
          _MenuCard(
            icon: Icons.favorite,
            title: 'Bookmarks',
            subtitle: 'BookmarkRepository - Save & manage',
            onTap: () => _push(context, const BookmarksPage()),
          ),
          _MenuCard(
            icon: Icons.history,
            title: 'Reading History',
            subtitle: 'ReadingHistoryRepository - Stats & tracking',
            onTap: () => _push(context, const ReadingHistoryPage()),
          ),
          _MenuCard(
            icon: Icons.settings,
            title: 'Preferences',
            subtitle: 'PreferencesRepository - User settings',
            onTap: () => _push(context, const PreferencesPage()),
          ),

          const SizedBox(height: 24),

          // ─── UI Library Section ───
          _SectionHeader(
            title: 'UI Library',
            subtitle: 'mushaf-ui: Flutter UI components',
          ),
          _MenuCard(
            icon: Icons.menu_book,
            title: 'MushafView',
            subtitle: 'Basic Quran page reader',
            onTap: () => _push(context, const MushafViewPage()),
          ),
          _MenuCard(
            icon: Icons.search,
            title: 'Search',
            subtitle: 'Search verses and chapters',
            onTap: () => _push(context, const SearchDemoPage()),
          ),
          _MenuCard(
            icon: Icons.palette,
            title: 'Theme Preview',
            subtitle: 'Reading theme color schemes',
            onTap: () => _push(context, const ThemePreviewPage()),
          ),
          _MenuCard(
            icon: Icons.book,
            title: 'Mushaf Type',
            subtitle: 'Switch between Hafs layouts',
            onTap: () => _push(context, const MushafTypePage()),
          ),
          _MenuCard(
            icon: Icons.code,
            title: 'Domain Models',
            subtitle: 'View all Quran data models',
            onTap: () => _push(context, const DomainModelsPage()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Menu Card
// ──────────────────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MushafView Page — Full Quran reader with chapter drawer
// ──────────────────────────────────────────────────────────────────────────────

class MushafViewPage extends StatefulWidget {
  const MushafViewPage({super.key});

  @override
  State<MushafViewPage> createState() => _MushafViewPageState();
}

class _MushafViewPageState extends State<MushafViewPage> {
  int _currentPage = 1;
  final GlobalKey<MushafPageViewState> _mushafKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChapterIndexDrawer(
        currentPage: _currentPage,
        onChapterSelected: (page) {
          _mushafKey.currentState?.goToPage(page);
        },
      ),
      body: MushafPageView(
        key: _mushafKey,
        initialPage: 1,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        onOpenChapterIndex: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Reciters Page
// ──────────────────────────────────────────────────────────────────────────────

class RecitersPage extends StatelessWidget {
  const RecitersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reciters = ReciterDataProvider.allReciters;
    return Scaffold(
      appBar: AppBar(title: const Text('Reciters')),
      body: ListView.builder(
        itemCount: reciters.length,
        itemBuilder: (context, index) {
          final r = reciters[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${r.id}'),
            ),
            title: Text(r.nameArabic, textDirection: TextDirection.rtl),
            subtitle: Text('${r.nameEnglish} · ${r.rewaya}'),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Chapters Page
// ──────────────────────────────────────────────────────────────────────────────

class ChaptersPage extends StatelessWidget {
  const ChaptersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chapters = QuranDataProvider.instance.getAllChapters();
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters (114 Surahs)')),
      body: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final c = chapters[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${c.number}', style: const TextStyle(fontSize: 12)),
            ),
            title: Text(c.arabicTitle, textDirection: TextDirection.rtl),
            subtitle: Text(
              '${c.englishTitle} · ${c.versesCount} ayat · Page ${c.startPage} · ${c.isMeccan ? "Meccan" : "Medinan"}',
            ),
            trailing: TextButton(
              child: const Text('Read'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        _MushafAtPage(page: c.startPage, title: c.arabicTitle),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MushafAtPage extends StatefulWidget {
  final int page;
  final String title;
  const _MushafAtPage({required this.page, required this.title});

  @override
  State<_MushafAtPage> createState() => _MushafAtPageState();
}

class _MushafAtPageState extends State<_MushafAtPage> {
  int _currentPage = 1;
  final GlobalKey<MushafPageViewState> _mushafKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChapterIndexDrawer(
        currentPage: _currentPage,
        onChapterSelected: (page) {
          _mushafKey.currentState?.goToPage(page);
        },
      ),
      body: MushafPageView(
        key: _mushafKey,
        initialPage: widget.page,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        onOpenChapterIndex: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Verses Page
// ──────────────────────────────────────────────────────────────────────────────

class VersesPage extends StatelessWidget {
  const VersesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verses')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_snippet, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Verse Repository',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Verse data will be available after Hive database integration.\n'
                'The VerseRepository provides access to all 6,236 verses with:\n'
                '• Full text with and without tashkil\n'
                '• Uthmanic Hafs text\n'
                '• Searchable text\n'
                '• Page, chapter, part, hizb mappings',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bookmarks Page
// ──────────────────────────────────────────────────────────────────────────────

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bookmark Repository',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Bookmarks will be available after Hive DAO integration.\n'
                'Features: Save verse bookmarks, organize by chapter, search bookmarks.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Reading History Page
// ──────────────────────────────────────────────────────────────────────────────

class ReadingHistoryPage extends StatelessWidget {
  const ReadingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading History')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Reading History Repository',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Reading history will be available after Hive DAO integration.\n'
                'Features: Track reading progress, streaks, last-read position.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Preferences Page
// ──────────────────────────────────────────────────────────────────────────────

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoTile('Mushaf Type', 'HAFS_1441 (default)'),
          _infoTile('Current Page', '1'),
          _infoTile('Font Size Multiplier', '1.0x'),
          _infoTile('Show Translation', 'Off'),
          _infoTile('Selected Reciter', 'Reciter #1'),
          _infoTile('Playback Speed', '1.0x'),
          _infoTile('Repeat Mode', 'Off'),
          _infoTile('Theme Mode', 'System'),
          _infoTile('Color Scheme', 'Default'),
          _infoTile('AMOLED Mode', 'Off'),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Currently using in-memory preferences.\n'
              'Will be persisted with Hive/SharedPreferences.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Search Demo
// ──────────────────────────────────────────────────────────────────────────────

class SearchDemoPage extends StatelessWidget {
  const SearchDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Search',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Search will be available after database integration.\n'
                'Features: Search verses by text, search chapters by name.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Theme Preview Page
// ──────────────────────────────────────────────────────────────────────────────

class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _themeCard('Light', const Color(0xFFFDF8F0), const Color(0xFF2D1B0E)),
          _themeCard('Sepia', const Color(0xFFF5E6CA), const Color(0xFF3E2723)),
          _themeCard('Dark', const Color(0xFF1A1A2E), const Color(0xFFE0D6C2)),
          _themeCard(
            'AMOLED',
            const Color(0xFF000000),
            const Color(0xFFE0E0E0),
          ),
          _themeCard('Olive', const Color(0xFFF0EDE0), const Color(0xFF33402E)),
          _themeCard('Blue', const Color(0xFFECF0F6), const Color(0xFF1A2744)),
        ],
      ),
    );
  }

  Widget _themeCard(String name, Color bg, Color text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              style: TextStyle(fontSize: 22, color: text, fontFamily: 'serif'),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Text(
              'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
              style: TextStyle(fontSize: 22, color: text, fontFamily: 'serif'),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Mushaf Type Page
// ──────────────────────────────────────────────────────────────────────────────

class MushafTypePage extends StatefulWidget {
  const MushafTypePage({super.key});

  @override
  State<MushafTypePage> createState() => _MushafTypePageState();
}

class _MushafTypePageState extends State<MushafTypePage> {
  MushafType _selected = MushafType.hafs1441;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mushaf Type')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final type in MushafType.values)
            ListTile(
              title: Text(type.name),
              subtitle: Text(_description(type)),
              leading: Radio<MushafType>(
                value: type,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
              ),
              onTap: () => setState(() => _selected = type),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The Mushaf type determines which page layout is used.\n'
              'Each type has different verse highlight and marker coordinates.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _description(MushafType type) {
    switch (type) {
      case MushafType.hafs1441:
        return 'Madina Mushaf, 1441H Edition, 604 pages';
      case MushafType.hafs1405:
        return 'Madina Mushaf, 1405H Edition, 604 pages';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Domain Models Page
// ──────────────────────────────────────────────────────────────────────────────

class DomainModelsPage extends StatelessWidget {
  const DomainModelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final models = [
      ('Chapter', 'Surah metadata: number, title, verse count, page'),
      ('Verse', 'Ayah: text, tashkil, page, markers, highlights'),
      ('QuranPage', 'Page: number, chapter refs, part, quarter'),
      ('Part', 'Juz: number, name, starting page'),
      ('Quarter', 'Hizb quarter: part, chapter, verse'),
      ('Bookmark', 'User bookmark: verse, chapter, timestamp, note'),
      ('ReadingHistory', 'Reading session: page, duration, timestamp'),
      ('SearchHistory', 'Search query: text, timestamp, results count'),
      ('ReciterInfo', 'Reciter: name, rewaya, audio folder URL'),
      ('AudioPlayerState', 'Player: playing, paused, position, duration'),
      ('ThemeConfig', 'Theme: mode, colorScheme, amoled'),
      ('VerseHighlight', 'Highlight rect: line, left, right (normalized)'),
      ('VerseMarker', 'Verse number marker: line, centerX, centerY'),
      ('CacheStats', 'Cache: hits, misses, size, lastRefresh'),
      ('UserDataBackup', 'Export: bookmarks, history, preferences'),
      ('MushafType', 'Enum: hafs1441, hafs1405'),
      ('LastReadPosition', 'Page, chapter, verse, timestamp'),
      ('ReciterTiming', 'Audio timing: verse start/end timestamps'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Domain Models')),
      body: ListView.separated(
        itemCount: models.length,
        separatorBuilder: (_, _a) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (name, desc) = models[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(desc),
          );
        },
      ),
    );
  }
}
