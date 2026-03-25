import 'dart:async';
import 'package:flutter/material.dart';
import '../../../imad_flutter.dart';
import '../player/audio_player_bar.dart';

/// MushafPageView — the main Mushaf reader screen.
class MushafPageView extends StatefulWidget {
  final int? initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool showNavigationControls;
  final bool showPageInfo;
  final bool showAudioPlayer;
  final VoidCallback? onOpenChapterIndex;
  final ReadingTheme readingTheme;
  final Color? audioHighlightsColor;

  final void Function(PageVerseData verse)? onSelectVerse;

  const MushafPageView({
    super.key,
    this.initialPage,
    this.onPageChanged,
    this.showNavigationControls = true,
    this.showPageInfo = true,
    this.showAudioPlayer = true,
    this.onOpenChapterIndex,
    this.readingTheme = ReadingTheme.light,
    this.audioHighlightsColor,
    this.onSelectVerse,
  });

  @override
  State<MushafPageView> createState() => MushafPageViewState();
}

class MushafPageViewState extends State<MushafPageView> {
  PageController? _pageController;
  int _currentPage = 0;
  int? _selectedVerseKey; // chapterNumber * 1000 + verseNumber

  /// The verse the user explicitly tapped — passed directly to AudioPlayerBar.
  /// Cleared when the page changes (user is no longer on that verse context).
  int? _tappedVerseNumber;
  int? _tappedChapterNumber;

  int? _currentAudioVerseKey;
  bool _showControls = true;
  StreamSubscription? _audioSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.initialPage != null) {
      _currentPage = widget.initialPage!.clamp(1, QuranDataProvider.totalPages);
      _initController();
      mushafGetIt<PreferencesRepository>().setCurrentPage(_currentPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onPageChanged?.call(_currentPage);
        }
      });
    } else {
      _initSavedPage();
    }
    _loadVerseData();
  }

  Future<void> _initSavedPage() async {
    try {
      final prefs = mushafGetIt<PreferencesRepository>();
      final savedPage = await prefs.getCurrentPage();

      if (mounted) {
        setState(() {
          _currentPage = savedPage.clamp(1, QuranDataProvider.totalPages);
          _initController();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged?.call(_currentPage);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _initController();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged?.call(_currentPage);
          }
        });
      }
    }
  }

  void _initController() {
    _pageController = PageController(
      initialPage: QuranDataProvider.totalPages - _currentPage,
    );
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
              setState(() => _currentAudioVerseKey = key);
            }
          } else if (!state.isPlaying && _currentAudioVerseKey != null) {
            setState(() => _currentAudioVerseKey = null);
          }
        });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void goToPage(int page) {
    final clampedPage = page.clamp(1, QuranDataProvider.totalPages);
    setState(() {
      _currentPage = clampedPage;
      _selectedVerseKey = null;
      // Clear tapped verse — user navigated to a new page
      _tappedVerseNumber = null;
      _tappedChapterNumber = null;
    });
    _pageController?.jumpToPage(QuranDataProvider.totalPages - clampedPage);
    mushafGetIt<PreferencesRepository>().setCurrentPage(clampedPage);

    widget.onPageChanged?.call(clampedPage);
  }

  void _onPageChanged(int pageIndex) {
    final newPage = QuranDataProvider.totalPages - pageIndex;
    setState(() {
      _currentPage = newPage;
      _selectedVerseKey = null;
      // Clear tapped verse — user swiped to a new page
      _tappedVerseNumber = null;
      _tappedChapterNumber = null;
    });
    widget.onPageChanged?.call(newPage);

    mushafGetIt<PreferencesRepository>().setCurrentPage(newPage);
  }

  void _goToNextPage() {
    if (_currentPage < QuranDataProvider.totalPages) {
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pageController?.nextPage(
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
    if (_currentPage == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final dataProvider = QuranDataProvider.instance;
    final chapters = dataProvider.getChaptersForPage(_currentPage);
    final juz = dataProvider.getJuzForPage(_currentPage);

    // Use tapped chapter if available, otherwise fall back to first chapter on page
    final audioChapterNumber =
        _tappedChapterNumber ??
        (chapters.isNotEmpty ? chapters.first.number : 1);
    final audioChapterName = _tappedChapterNumber != null
        ? chapters
              .firstWhere(
                (c) => c.number == _tappedChapterNumber,
                orElse: () => chapters.first,
              )
              .arabicTitle
        : (chapters.isNotEmpty ? chapters.first.arabicTitle : '');

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
                        // Pass audioVerseKey to every rendered page.
                        // QuranPageWidget will only highlight it if the verse
                        // actually lives on that page — so pages that don't
                        // own the verse simply show nothing. This fixes the
                        // case where a verse starts on the previous page.
                        audioVerseKey: _currentAudioVerseKey,
                        audioHighlightsColor: widget.audioHighlightsColor,
                        onVerseTap: (verse) {
                          final key = verse.chapter * 1000 + verse.number;
                          setState(() {
                            // Toggle selection
                            _selectedVerseKey = _selectedVerseKey == key
                                ? null
                                : key;

                            // Track which verse was tapped for AudioPlayerBar.
                            // If user de-selects, clear so page-level context is used.
                            if (_selectedVerseKey != null) {
                              _tappedVerseNumber = verse.verseID;
                              _tappedChapterNumber = verse.chapter;
                            } else {
                              _tappedVerseNumber = null;
                              _tappedChapterNumber = null;
                            }
                          });
                          widget.onSelectVerse?.call(verse);
                        },
                      );
                    },
                  ),

                  if (widget.showNavigationControls && _showControls) ...[
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

                    if (widget.showPageInfo)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: _PageInfoBadge(
                          pageNumber: _currentPage,
                          chapterName: audioChapterName,
                          juzNumber: juz,
                        ),
                      ),

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
                ],
              ),
            ),
          ),

          if (widget.showAudioPlayer)
            AudioPlayerBar(
              chapterNumber: audioChapterNumber,
              chapterName: audioChapterName,
              // ✅ Pass current page so AudioPlayerBar can resolve the first
              //    verse on the page when no explicit verse is tapped.
              currentPage: _currentPage,
              // ✅ Pass explicit tapped verse — null means "use page context".
              startVerseNumber: _tappedVerseNumber,
            ),
        ],
      ),
    );
  }
}

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
          _NavButton(
            icon: Icons.arrow_back_rounded,
            enabled: canGoNext,
            onTap: onNext,
          ),
          if (onOpenChapterIndex != null)
            _NavButton(
              icon: Icons.menu_book_rounded,
              enabled: true,
              onTap: onOpenChapterIndex!,
              isAccent: true,
            ),
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
