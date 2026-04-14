import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:collection/collection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure AlKetab API service
  const apiKey = String.fromEnvironment('ALKETAB_API_KEY');
  AlKetabApiService.configure(apiKey);

  // For testing Quran.com API in the example app:
  // Use MushafAudioSource.quranCom and provide credentials via dart-define:
  // flutter run --dart-define=QF_ID=xxx --dart-define=QF_SECRET=yyy
  const qfId = String.fromEnvironment('QF_ID');
  const qfSecret = String.fromEnvironment('QF_SECRET');
  const qfEnv = String.fromEnvironment('QF_ENV', defaultValue: 'production');
  final environment = qfEnv == 'prelive'
      ? QuranComEnvironment.prelive
      : QuranComEnvironment.production;

  final useQuranCom = qfId != '' && qfSecret != '';

  if (useQuranCom) {
    // Initialize with live Quran.com API in one shot
    await MushafLibrary.initialize(
      audioSources: {
        // MushafAudioSource.quranCom, MushafAudioSource.mp3quran,
        MushafAudioSource.itqan},
      quranComConfig: QuranComAudioSourceConfig(
        clientId: qfId,
        clientSecret: qfSecret,
        environment: environment,
      ),
      itqanAudioConfig: ItqanAudioConfig(),
    );
  } else {
    // Default: local assets
    await MushafLibrary.initialize();
  }

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
          const SizedBox(height: 24),

          // ─── New Features Section ───
          _SectionHeader(
            title: 'Quran.com API',
            subtitle: 'Testing new streaming audio provider',
          ),
          _MenuCard(
            icon: Icons.cloud_download,
            title: 'Quran.com Demo',
            subtitle: 'Live API streaming & dynamic reciters',
            onTap: () => _push(context, const QuranComDemoPage()),
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
        onSelectVerse: (verse) {
          showVerseOptionsBottomSheet(context, verse: verse);
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
            subtitle: Text(r.nameEnglish),
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
        onSelectVerse: (verse) {
          showVerseOptionsBottomSheet(context, verse: verse);
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
              leading: RadioGroup(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                child: Radio<MushafType>(value: type),
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
        separatorBuilder: (_, dummy) => const Divider(height: 1),
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

// use case example of the above component, can be used in multiple places in the app with different content.
Future<T?> showVerseOptionsBottomSheet<T>(
  BuildContext context, {
  required PageVerseData verse,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: MushafModalBottomSheet(
          title: Text('الآية ${verse.chapter}:${verse.number} - ${verse.text}'),
          body: Column(
            children: [
              BottomSheetOption(
                icon: Icons.play_arrow,
                label: 'الاستماع من هذه الآية',
                onTap: () {},
              ),
              BottomSheetOption(
                icon: Icons.share,
                label: 'مشاركة الآية',
                onTap: () {},
              ),
              BottomSheetOption(
                icon: Icons.bookmark_add,
                label: 'إضافة إلى المفضلة',
                onTap: () {},
              ),
              BottomSheetOption(
                icon: Icons.info_outline,
                label: 'معلومات الآية',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Quran.com Demo Page — Demonstrates Phase 4 & 5 integration
// ──────────────────────────────────────────────────────────────────────────────

class QuranComDemoPage extends StatefulWidget {
  const QuranComDemoPage({super.key});

  @override
  State<QuranComDemoPage> createState() => _QuranComDemoPageState();
}

class _QuranComDemoPageState extends State<QuranComDemoPage> {
  // Use a nullable reference or a check to prevent DI crash if not in quranCom mode
  QuranComReciterProvider? get _reciterProvider =>
      mushafGetIt.isRegistered<QuranComReciterProvider>()
      ? mushafGetIt<QuranComReciterProvider>()
      : null;

  final _audioRepo = mushafGetIt<AudioRepository>();

  List<ReciterInfo> _reciters = [];
  ReciterInfo? _selectedReciter;
  int _selectedChapter = 1;
  bool _useArabic = false;
  double _playbackSpeed = 1.0;
  bool _isLoading = true;
  String? _error;
  String? _playerError;

  AudioPlayerState? _playerState;
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _loadReciters();
    _playerSub = _audioRepo.getPlayerStateStream().listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state.errorMessage != null) {
            _playerError = state.errorMessage;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
  }

  Future<void> _loadReciters() async {
    final provider = _reciterProvider;
    if (provider == null) {
      if (mounted) {
        setState(() {
          _error =
              'QuranComReciterProvider not registered in DI.\nMake sure you run with API credentials provided.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final list = await provider.getAllReciters();
      if (list.isEmpty) throw Exception('No reciters found');
      if (mounted) {
        setState(() {
          _reciters = list;
          _selectedReciter = list.isNotEmpty ? list.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reciters. Confirm your credentials.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    _audioRepo.stop();
    if (mounted) {
      setState(() {
        _playerError = null;
      });
    }
  }

  Future<void> _onChapterChanged(int chapter) async {
    _stopAudio();
    if (mounted) {
      setState(() {
        _selectedChapter = chapter;
      });
    }
  }

  Future<void> _onReciterChanged(ReciterInfo? reciter) async {
    _stopAudio();
    if (mounted) {
      setState(() {
        _selectedReciter = reciter;
      });
    }
  }

  Future<void> _onTogglePlay() async {
    if (_selectedReciter == null) return;
    setState(() => _playerError = null);

    try {
      final isPlaying = _playerState?.isPlaying ?? false;
      final isCompleted =
          _playerState?.playbackState == PlaybackState.stopped &&
          (_playerState?.currentPositionMs ?? 0) > 0;

      if (isPlaying) {
        _audioRepo.pause();
      } else {
        // If it's a different chapter/reciter, or it was completed, load it
        final needsLoad =
            _playerState?.currentChapter != _selectedChapter ||
            _playerState?.currentReciterId != _selectedReciter?.id ||
            isCompleted;

        if (needsLoad) {
          _audioRepo.loadChapter(
            _selectedChapter,
            _selectedReciter!.id,
            autoPlay: true,
          );
        } else {
          _audioRepo.play();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quran.com Demo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quran.com Demo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Make sure you run with:\n--dart-define=QF_ID=xxx --dart-define=QF_SECRET=yyy',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran.com Demo'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _useArabic = !_useArabic),
            icon: Icon(
              _useArabic ? Icons.language : Icons.translate,
              color: Colors.white,
            ),
            label: Text(
              _useArabic ? 'EN' : 'AR',
              style: const TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(backgroundColor: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              _useArabic
                  ? '١. اختر القارئ'
                  : '1. Choose Reciter (Live from API)',
            ),
            _ReciterDropdown(
              items: _reciters,
              value: _selectedReciter,
              useArabic: _useArabic,
              onChanged: _onReciterChanged,
            ),
            const SizedBox(height: 24),
            _SectionLabel(_useArabic ? '٢. اختر السورة' : '2. Select Chapter'),
            _ChapterDropdown(
              value: _selectedChapter,
              useArabic: _useArabic,
              onChanged: (v) => _onChapterChanged(v!),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (_playerState != null && _playerState!.durationMs > 0) ...[
              _SectionLabel(_useArabic ? 'التقدم' : 'Seek'),
              Slider(
                value: _playerState!.currentPositionMs.toDouble().clamp(
                  0,
                  _playerState!.durationMs.toDouble(),
                ),
                max: _playerState!.durationMs.toDouble(),
                onChanged: (v) => _audioRepo.seekTo(v.toInt()),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        Duration(milliseconds: _playerState!.currentPositionMs),
                      ),
                    ),
                    Text(
                      _formatDuration(
                        Duration(milliseconds: _playerState!.durationMs),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(_useArabic ? 'السرعة' : 'Speed'),
                DropdownButton<double>(
                  value: _playbackSpeed,
                  items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                    return DropdownMenuItem(value: s, child: Text('${s}x'));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _playbackSpeed = v);
                      _audioRepo.setPlaybackSpeed(v);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        (_selectedReciter == null ||
                            (_playerState?.isBuffering ?? false))
                        ? null
                        : _onTogglePlay,
                    icon: (_playerState?.isBuffering ?? false)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _playerState?.isPlaying ?? false
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                    label: Text(
                      (_playerState?.isBuffering ?? false)
                          ? (_useArabic ? 'جاري التحميل...' : 'Loading...')
                          : (_playerState?.isPlaying ?? false
                                ? (_useArabic ? 'إيقاف' : 'Pause')
                                : (_useArabic ? 'تشغيل' : 'Fetch & Play')),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  ),
                  if (_playerError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_useArabic ? "خطأ" : "Error"}: $_playerError',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            _PlayerSyncCard(state: _playerState, useArabic: _useArabic),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _ReciterDropdown extends StatelessWidget {
  final List<ReciterInfo> items;
  final ReciterInfo? value;
  final bool useArabic;
  final ValueChanged<ReciterInfo?> onChanged;

  const _ReciterDropdown({
    required this.items,
    required this.value,
    required this.useArabic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReciterInfo>(
          isExpanded: true,
          value: value,
          items: items.map((r) {
            final name = useArabic ? r.nameArabic : r.nameEnglish;
            return DropdownMenuItem(
              value: r,
              child: Text(
                '$name)',
                textDirection: useArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChapterDropdown extends StatelessWidget {
  final int value;
  final bool useArabic;
  final ValueChanged<int?> onChanged;

  const _ChapterDropdown({
    required this.value,
    required this.useArabic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          items: List.generate(114, (i) => i + 1).map((n) {
            final chapter = QuranDataProvider.instance.getChapter(n);
            final name = useArabic ? chapter.arabicTitle : chapter.englishTitle;
            return DropdownMenuItem(
              value: n,
              child: Text(
                useArabic ? 'سورة $name' : 'Surah $n: $name',
                textDirection: useArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Removed _VerseDropdown class

class _PlayerSyncCard extends StatelessWidget {
  final AudioPlayerState? state;
  final bool useArabic;
  const _PlayerSyncCard({this.state, required this.useArabic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = state?.isPlaying ?? false;
    final verse = state?.currentVerse;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isPlaying ? Icons.volume_up : Icons.volume_mute,
                  color: isPlaying ? theme.colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  isPlaying
                      ? (useArabic
                            ? 'البث المباشر حالياً'
                            : 'Currently Streaming')
                      : (useArabic ? 'المشغل متوقف' : 'Player Idle'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: useArabic ? 'السورة' : 'Surah',
                  value: state?.currentChapter?.toString() ?? '-',
                ),
                _StatItem(
                  label: useArabic ? 'الآية' : 'Verse',
                  value: verse?.toString() ?? '-',
                  highlight: true,
                ),
                _StatItem(
                  label: useArabic ? 'الوقت' : 'Progress',
                  value: _formatDuration(
                    state != null
                        ? Duration(milliseconds: state!.currentPositionMs)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
