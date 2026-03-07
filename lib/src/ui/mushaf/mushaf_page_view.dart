import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/verse_data_provider.dart';
import '../../di/core_module.dart';
import '../../domain/repository/audio_repository.dart';
import '../player/audio_player_bar.dart';
import '../theme/mushaf_theme_scope.dart';
import '../theme/reading_theme.dart';
import 'quran_page_widget.dart';

/// MushafPageView — the main Mushaf reader screen.
///
/// A full-screen PageView with 604 Quran pages, swipe navigation,
/// and navigation controls. This is the primary UI entry point
/// for reading the Quran.
///
/// Port of the Android MushafView composable.
class MushafPageView extends StatefulWidget {
  /// Initial page to display (1-604).
  final int initialPage;

  /// Callback when page changes.
  final ValueChanged<int>? onPageChanged;

  /// Whether to show navigation arrows.
  final bool showNavigationControls;

  /// Whether to show the page info badge.
  final bool showPageInfo;

  /// Whether to show the audio player controls.
  final bool showAudioPlayer;

  /// Whether to show the adaptive toolbar button.
  final bool showAdaptiveToolbar;

  /// Callback for opening chapter index.
  final VoidCallback? onOpenChapterIndex;

  /// Reading theme for the Mushaf pages. Defaults to light.
  final ReadingTheme readingTheme;

  /// Color used to highlight the currently playing verse during audio playback.
  final Color? audioHighlightsColor;

  const MushafPageView({
    super.key,
    this.initialPage = 1,
    this.onPageChanged,
    this.showNavigationControls = true,
    this.showPageInfo = true,
    this.showAudioPlayer = true,
    this.showAdaptiveToolbar = true,
    this.onOpenChapterIndex,
    this.readingTheme = ReadingTheme.light,
    this.audioHighlightsColor,
  });

  @override
  State<MushafPageView> createState() => MushafPageViewState();
}

class MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  int _currentPage = 1;
  int? _selectedVerseKey; // chapterNumber * 1000 + verseNumber
  int? _currentAudioVerseKey;
  bool _showControls = true;
  StreamSubscription? _audioSubscription;
  late final Stream<bool> _showAudioPlayerStream;
  final ValueNotifier<double> _toolbarOpacity = ValueNotifier(0.2);
  Timer? _toolbarTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, QuranDataProvider.totalPages);
    _pageController = PageController(
      initialPage: QuranDataProvider.totalPages - _currentPage,
    );
    _showAudioPlayerStream = mushafGetIt<PreferencesRepository>()
        .getShowAudioPlayerStream();
    _loadVerseData();
    _pageController.addListener(_onScroll);
    
    // Initial pre-caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheNearbyPages();
    });
  }

  void _onScroll() {
    _makeToolbarOpaque();
  }

  void _makeToolbarOpaque() {
    _toolbarOpacity.value = 1.0;
    _toolbarTimer?.cancel();
    _toolbarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _toolbarOpacity.value = 0.2;
      }
    });
  }

  Future<void> _loadVerseData() async {
    await VerseDataProvider.instance.initialize();

    _audioSubscription = mushafGetIt<AudioRepository>()
        .getPlayerStateStream()
        .listen((state) {
          if (!mounted) return;
          if (state.currentChapter != null && state.currentVerse != null) {
            final key = state.currentChapter! * 1000 + state.currentVerse!;
            if (_currentAudioVerseKey != key) {
              setState(() {
                _currentAudioVerseKey = key;
              });
            }
          } else if (!state.isPlaying && _currentAudioVerseKey != null) {
            setState(() {
              _currentAudioVerseKey = null;
            });
          }
        });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _toolbarTimer?.cancel();
    _toolbarOpacity.dispose();
    super.dispose();
  }

  /// Navigate to a specific page (1-604).
  void goToPage(int page) {
    final clampedPage = page.clamp(1, QuranDataProvider.totalPages);
    setState(() {
      _currentPage = clampedPage;
      _selectedVerseKey = null;
    });
    _pageController.jumpToPage(QuranDataProvider.totalPages - clampedPage);
  }

  void _onPageChanged(int pageIndex) {
    final newPage = QuranDataProvider.totalPages - pageIndex;
    setState(() {
      _currentPage = newPage;
      _selectedVerseKey = null;
    });
    _precacheNearbyPages();
    widget.onPageChanged?.call(newPage);
  }

  void _precacheNearbyPages() {
    // Precache current page (just in case) and neighbors
    QuranDataProvider.precachePageImages(context, _currentPage);
    QuranDataProvider.precachePageImages(context, _currentPage + 1);
    QuranDataProvider.precachePageImages(context, _currentPage - 1);
  }

  void _goToNextPage() {
    if (_currentPage < QuranDataProvider.totalPages) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _makeToolbarOpaque();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = QuranDataProvider.instance;
    final chapters = dataProvider.getChaptersForPage(_currentPage);
    final juz = dataProvider.getJuzForPage(_currentPage);
    final chapterName = chapters.isNotEmpty ? chapters.first.arabicTitle : '';

    // Read theme from scope if available, otherwise use the explicit parameter
    final scopeNotifier = MushafThemeScope.maybeOf(context);
    final effectiveTheme = scopeNotifier?.readingTheme ?? widget.readingTheme;
    final effectiveThemeData = ReadingThemeData.fromTheme(effectiveTheme);

    return Scaffold(
      backgroundColor: effectiveThemeData.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Main page view (RTL page order)
                  PageView.builder(
                    controller: _pageController,
                    reverse: false,
                    itemCount: QuranDataProvider.totalPages,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final pageNumber = QuranDataProvider.totalPages - index;
                      return QuranPageWidget(
                        pageNumber: pageNumber,
                        themeData: effectiveThemeData,

                        selectedVerseKey: pageNumber == _currentPage
                            ? _selectedVerseKey
                            : null,
                        audioVerseKey: pageNumber == _currentPage
                            ? _currentAudioVerseKey
                            : null,
                        audioHighlightsColor: widget.audioHighlightsColor,
                        onVerseTap: (chapter, verse) {
                          final key = chapter * 1000 + verse;
                          setState(() {
                            _selectedVerseKey = _selectedVerseKey == key
                                ? null
                                : key;
                          });
                        },
                      );
                    },
                  ),

                  // Navigation controls overlay
                  if (widget.showNavigationControls && _showControls) ...[
                    // Bottom navigation bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _NavigationBar(
                        currentPage: _currentPage,
                        totalPages: QuranDataProvider.totalPages,
                        canGoPrevious: _currentPage > 1,
                        canGoNext: _currentPage < QuranDataProvider.totalPages,
                        onPrevious: _goToPreviousPage,
                        onNext: _goToNextPage,
                        onOpenChapterIndex: widget.onOpenChapterIndex,
                        themeData: effectiveThemeData,
                      ),
                    ),

                    // Page info badge (top right) - Upgraded to Premium Header (Issue #51)
                    if (widget.showPageInfo)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _PageHeader(
                          pageNumber: _currentPage,
                          chapterName: chapterName,
                          juzNumber: juz,
                          themeData: effectiveThemeData,
                        ),
                      ),

                    // Adaptive Toolbar Button (top left) - Issue #50
                    if (widget.showAdaptiveToolbar)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 12,
                        child: _AdaptiveToolbarButton(
                          opacity: _toolbarOpacity,
                          themeData: effectiveThemeData,
                          onTap: () {
                            _makeToolbarOpaque();
                            widget.onOpenChapterIndex?.call();
                          },
                        ),
                      ),

                    // Back button (top left - below adaptive toolbar if needed, or integrated)
                    if (_showControls)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 72,
                        left: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: effectiveThemeData.surfaceColor.withValues(
                                  alpha: 0.95,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: effectiveThemeData.textColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ], // Closes Stack children
              ), // Closes Stack
            ), // Closes GestureDetector
          ), // Closes Expanded
          StreamBuilder<bool>(
            stream: _showAudioPlayerStream,
            initialData: widget.showAudioPlayer,
            builder: (context, snapshot) {
              final show = snapshot.data ?? widget.showAudioPlayer;
              if (!show) return const SizedBox.shrink();
              return AudioPlayerBar(
                chapterNumber: chapters.isNotEmpty ? chapters.first.number : 1,
                chapterName: chapterName,
                themeData: effectiveThemeData,
              );
            },
          ),
        ], // Closes Column children
      ), // Closes Column
    ); // Closes Scaffold
  }
}

/// Bottom navigation bar with page arrows and chapter index button.
class _NavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onOpenChapterIndex;
  final ReadingThemeData themeData;

  const _NavigationBar({
    required this.currentPage,
    required this.totalPages,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.themeData,
    this.onOpenChapterIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            themeData.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page (left arrow — goes back in Arabic/RTL context)
          _NavButton(
            icon: Icons.arrow_back_rounded,
            enabled: canGoNext,
            onTap: onNext,
            themeData: themeData,
          ),
 
          // Chapter index button
          if (onOpenChapterIndex != null)
            _NavButton(
              icon: Icons.menu_book_rounded,
              enabled: true,
              onTap: onOpenChapterIndex!,
              isAccent: true,
              themeData: themeData,
            ),
 
          // Next page (right arrow — goes forward in Arabic/RTL context)
          _NavButton(
            icon: Icons.arrow_forward_rounded,
            enabled: canGoPrevious,
            onTap: onPrevious,
            themeData: themeData,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isAccent;
  final ReadingThemeData themeData;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.themeData,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAccent
                ? themeData.accentColor
                : themeData.secondaryTextColor.withValues(alpha: 0.15),
            boxShadow: [
              if (themeData.backgroundColor != Colors.black)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            icon,
            color: !enabled
                ? themeData.secondaryTextColor.withValues(alpha: 0.4)
                : isAccent
                ? Colors.white
                : themeData.textColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Adaptive Toolbar Button (Issue #50).
/// Remains semi-transparent when idle, becomes opaque on interaction.
class _AdaptiveToolbarButton extends StatelessWidget {
  final ValueNotifier<double> opacity;
  final ReadingThemeData themeData;
  final VoidCallback onTap;

  const _AdaptiveToolbarButton({
    required this.opacity,
    required this.themeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: opacity,
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: const Duration(milliseconds: 300),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeData.surfaceColor.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (value > 0.5)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: themeData.textColor,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium Page Header (Issue #51).
class _PageHeader extends StatelessWidget {
  final int pageNumber;
  final String chapterName;
  final int juzNumber;
  final ReadingThemeData themeData;

  const _PageHeader({
    required this.pageNumber,
    required this.chapterName,
    required this.juzNumber,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeData.backgroundColor.withValues(alpha: 0.9),
            themeData.backgroundColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Juz info (Left)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الجزء',
                style: TextStyle(
                  fontSize: 10,
                  color: themeData.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                QuranDataProvider.toArabicNumerals(juzNumber),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeData.textColor,
                ),
              ),
            ],
          ),

          // Chapter name (Center)
          if (chapterName.isNotEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  chapterName,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.bold,
                    color: themeData.accentColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Page number (Right)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الصفحة',
                style: TextStyle(
                  fontSize: 10,
                  color: themeData.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                QuranDataProvider.toArabicNumerals(pageNumber),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeData.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
