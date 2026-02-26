import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupMushafWithHive();

  // Initialize MushafLibrary with actual DAO instances
  await MushafLibrary.initialize(
    databaseService: mushafGetIt<DatabaseService>(),
    bookmarkDao: mushafGetIt<BookmarkDao>(),
    readingHistoryDao: mushafGetIt<ReadingHistoryDao>(),
    searchHistoryDao: mushafGetIt<SearchHistoryDao>(),
  );
  runApp(const MushafApp());
}

class MushafApp extends StatefulWidget {
  const MushafApp({super.key});

  @override
  State<MushafApp> createState() => _MushafAppState();
}

class _MushafAppState extends State<MushafApp> {
  final _themeNotifier = MushafThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MushafThemeScope(
      notifier: _themeNotifier,
      child: MaterialApp(
        title: 'MushafImad Library',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF6750A4),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const LibraryHomePage(),
      ),
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
            title: 'Chapters & Bookmarks',
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
            onTap: () => _push(context, const BookmarksPageWrapper()),
          ),
          _MenuCard(
            icon: Icons.history,
            title: 'Reading History',
            subtitle: 'ReadingHistoryRepository - Stats & tracking',
            onTap: () => _push(context, const ReadingHistoryPage()),
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
            onTap: () => _push(context, const SearchPageWrapper()),
          ),
          _MenuCard(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Theme, preferences & data management',
            onTap: () => _push(context, const SettingsPage()),
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

  late final BookmarkRepository _bookmarkRepository;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page;
    _bookmarkRepository = MushafLibrary.getBookmarkRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: _buildBookmarkIcon(),
            onPressed: _toggleBookmarkForCurrentPage,
          ),
        ],
      ),
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

  /// Builds a bookmark icon that updates dynamically based on bookmark state
  Widget _buildBookmarkIcon() {
    return FutureBuilder<bool>(
      future: _isCurrentPageBookmarked(),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        return Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border);
      },
    );
  }

  /// Checks if the current page is already bookmarked
  Future<bool> _isCurrentPageBookmarked() async {
    final allBookmarks = await _bookmarkRepository.getAllBookmarks();
    return allBookmarks.any((b) => b.pageNumber == _currentPage);
  }

  /// Adds or removes a bookmark for the current page

  Future<void> _toggleBookmarkForCurrentPage() async {
    final allBookmarks = await _bookmarkRepository.getAllBookmarks();

    // Returns null if no bookmark found
    final existing = allBookmarks.firstWhereOrNull(
      (b) => b.pageNumber == _currentPage,
    );

    if (existing != null) {
      await _bookmarkRepository.deleteBookmark(existing.id);
      _showSnackBar('Bookmark removed from page $_currentPage');
    } else {
      await _bookmarkRepository.addBookmark(
        chapterNumber: 0,
        verseNumber: 0,
        pageNumber: _currentPage,
        note: '',
      );
      _showSnackBar('Bookmark added for page $_currentPage');
    }

    setState(() {});
  }

  /// Shows a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
// Bookmarks Page — Using BookmarkListWidget
// ──────────────────────────────────────────────────────────────────────────────

class BookmarksPageWrapper extends StatefulWidget {
  const BookmarksPageWrapper({super.key});

  @override
  State<BookmarksPageWrapper> createState() => _BookmarksPageWrapperState();
}

class _BookmarksPageWrapperState extends State<BookmarksPageWrapper> {
  late final BookmarkRepository _bookmarkRepository;
  late Future<List<Bookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarkRepository = MushafLibrary.getBookmarkRepository();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    _bookmarksFuture = _bookmarkRepository.getAllBookmarks();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: FutureBuilder<List<Bookmark>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookmarks = snapshot.data ?? [];

          if (bookmarks.isEmpty) {
            return const Center(child: Text('No bookmarks yet'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final b = bookmarks[index];

                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text('Page ${b.pageNumber}'),
                  subtitle: Text(
                    'Chapter ${b.chapterNumber} · Verse ${b.verseNumber}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _bookmarkRepository.deleteBookmark(b.id);
                      _refresh();
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _MushafAtPage(
                          page: b.pageNumber,
                          title: 'Bookmark',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
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
// Search Page — Using SearchPage widget
// ──────────────────────────────────────────────────────────────────────────────

class SearchPageWrapper extends StatelessWidget {
  const SearchPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SearchPage(
        onVerseSelected: (page) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _MushafAtPage(page: page, title: 'Search Result'),
            ),
          );
        },
        onChapterSelected: (page) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _MushafAtPage(page: page, title: 'Chapter'),
            ),
          );
        },
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
