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
  int? _audioVerseKey;
  bool _showControls = true;
  StreamSubscription? _audioSubscription;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, QuranDataProvider.totalPages);
    _pageController = PageController(
      initialPage: QuranDataProvider.totalPages - _currentPage,
    );
    _loadVerseData();
  }

  Future<void> _loadVerseData() async {
    await VerseDataProvider.instance.initialize();

    _audioSubscription = mushafGetIt<AudioRepository>()
        .getPlayerStateStream()
        .listen((state) {
          if (!mounted) return;
          if (state.currentChapter != null && state.currentVerse != null) {
            final key = state.currentChapter! * 1000 + state.currentVerse!;
            if (_audioVerseKey != key) {
              setState(() {
                _audioVerseKey = key;
              });
            }
          } else if (state.isPlaying && _audioVerseKey != null) {
            setState(() {
              _audioVerseKey = null;
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
    _pageController.dispose();
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
    widget.onPageChanged?.call(newPage);
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
                            ? _audioVerseKey
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
                      ),
                    ),

                    // Page info badge (top right)
                    if (widget.showPageInfo)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: _PageInfoBadge(
                          pageNumber: _currentPage,
                          chapterName: chapterName,
                          juzNumber: juz,
                        ),
                      ),

                    // Back button (top left)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
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
                              Icons.arrow_back,
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
          if (widget.showAudioPlayer)
            AudioPlayerBar(
              chapterNumber: chapters.isNotEmpty ? chapters.first.number : 1,
              chapterName: chapterName,
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

  const _NavigationBar({
    required this.currentPage,
    required this.totalPages,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
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
            const Color(0xFFFDF8F0).withValues(alpha: 0.95),
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
          ),

          // Chapter index button
          if (onOpenChapterIndex != null)
            _NavButton(
              icon: Icons.menu_book_rounded,
              enabled: true,
              onTap: onOpenChapterIndex!,
              isAccent: true,
            ),

          // Next page (right arrow — goes forward in Arabic/RTL context)
          _NavButton(
            icon: Icons.arrow_forward_rounded,
            enabled: canGoPrevious,
            onTap: onPrevious,
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

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
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
                ? const Color(0xFF8B7355)
                : const Color(0xFFF5ECD7).withValues(alpha: 0.95),
            boxShadow: [
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
                ? Colors.grey.shade400
                : isAccent
                ? Colors.white
                : const Color(0xFF5C4033),
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Page info badge showing current page, chapter, and juz.
class _PageInfoBadge extends StatelessWidget {
  final int pageNumber;
  final String chapterName;
  final int juzNumber;

  const _PageInfoBadge({
    required this.pageNumber,
    required this.chapterName,
    required this.juzNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5ECD7).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${QuranDataProvider.toArabicNumerals(pageNumber)} / ٦٠٤',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C4033),
            ),
          ),
          if (chapterName.isNotEmpty)
            Text(
              chapterName,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8B7355)),
            ),
        ],
      ),
    );
  }
}
