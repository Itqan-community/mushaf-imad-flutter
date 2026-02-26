import 'dart:async';
import 'package:flutter/material.dart';

import '../../di/core_module.dart';
import '../../domain/repository/audio_repository.dart';
import '../../domain/models/audio_player_state.dart' as domain;
import '../../data/quran/quran_data_provider.dart';
import '../../data/quran/verse_data_provider.dart';
import '../player/audio_player_bar.dart';
import '../theme/reading_theme.dart';
import '../theme/mushaf_theme_scope.dart';
import 'quran_page_widget.dart';

/// MushafPageView — the main Mushaf reader screen.
class MushafPageView extends StatefulWidget {
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool showNavigationControls;
  final bool showPageInfo;
  final bool showAudioPlayer;
  final VoidCallback? onOpenChapterIndex;
  final ReadingTheme readingTheme;

  const MushafPageView({
    super.key,
    this.initialPage = 1,
    this.onPageChanged,
    this.showNavigationControls = true,
    this.showPageInfo = true,
    this.showAudioPlayer = true,
    this.onOpenChapterIndex,
    this.readingTheme = ReadingTheme.light,
  });

  @override
  State<MushafPageView> createState() => MushafPageViewState();
}

class MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  int _currentPage = 1;
  int? _selectedVerseKey; // chapter * 1000 + verse
  bool _showControls = true;

  StreamSubscription<domain.AudioPlayerState>? _audioSubscription;
  int? _currentReciterId;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, QuranDataProvider.totalPages);
    _pageController = PageController(
      initialPage: QuranDataProvider.totalPages - _currentPage,
    );
    _initAudioListener();
  }

  Future<void> _initAudioListener() async {
    await VerseDataProvider.instance.initialize();
    if (!mounted) return;

    final stream = mushafGetIt<AudioRepository>().getPlayerStateStream();
    _audioSubscription = stream.listen((state) {
      if (!mounted) return;
      _currentReciterId = state.currentReciterId;

      if (state.currentChapter != null && state.currentVerse != null) {
        final key = state.currentChapter! * 1000 + state.currentVerse!;
        if (_selectedVerseKey != key) {
          setState(() => _selectedVerseKey = key);
        }
      } else if (state.playbackState == domain.PlaybackState.playing) {
        if (_selectedVerseKey != null) {
          setState(() => _selectedVerseKey = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void goToPage(int page) {
    final clamped = page.clamp(1, QuranDataProvider.totalPages);
    setState(() {
      _currentPage = clamped;
      _selectedVerseKey = null;
    });
    _pageController.jumpToPage(QuranDataProvider.totalPages - clamped);
  }

  void _onPageChanged(int index) {
    final page = QuranDataProvider.totalPages - index;
    setState(() {
      _currentPage = page;
      _selectedVerseKey = null;
    });
    widget.onPageChanged?.call(page);
  }

  void _goNext() {
    if (_currentPage < QuranDataProvider.totalPages) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goPrevious() {
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
    final data = QuranDataProvider.instance;
    final chapters = data.getChaptersForPage(_currentPage);
    final juz = data.getJuzForPage(_currentPage);
    final chapterName = chapters.isNotEmpty ? chapters.first.arabicTitle : '';

    final scope = MushafThemeScope.maybeOf(context);
    final theme = scope?.readingTheme ?? widget.readingTheme;
    final themeData = ReadingThemeData.fromTheme(theme);

    return Scaffold(
      backgroundColor: themeData.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: QuranDataProvider.totalPages,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final pageNumber =
                          QuranDataProvider.totalPages - index;
                      return QuranPageWidget(
                        pageNumber: pageNumber,
                        themeData: themeData,
                        selectedVerseKey:
                            pageNumber == _currentPage ? _selectedVerseKey : null,
                        onVerseTap: (chapter, verse) {
                          final key = chapter * 1000 + verse;
                          setState(() {
                            _selectedVerseKey =
                                _selectedVerseKey == key ? null : key;
                          });
                        },
                        onVerseLongPress: (chapter, verse) {
                          final reciterId = _currentReciterId;
                          if (reciterId == null) return;

                          // ✅ تم الإصلاح: تمرير startAyahNumber لتبدأ التلاوة من الآية المحددة
                          mushafGetIt<AudioRepository>().loadChapter(
                            chapter,
                            reciterId,
                            autoPlay: true,
                            startAyahNumber: verse,
                          );
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
                        themeData: themeData,
                        currentPage: _currentPage,
                        totalPages: QuranDataProvider.totalPages,
                        canGoPrevious: _currentPage > 1,
                        canGoNext:
                            _currentPage < QuranDataProvider.totalPages,
                        onPrevious: _goPrevious,
                        onNext: _goNext,
                        onOpenChapterIndex: widget.onOpenChapterIndex,
                      ),
                    ),

                    if (widget.showPageInfo)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: _PageInfoBadge(
                          themeData: themeData,
                          pageNumber: _currentPage,
                          chapterName: chapterName,
                          juzNumber: juz,
                        ),
                      ),

                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: themeData.textColor,
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
              chapterNumber: chapters.isNotEmpty ? chapters.first.number : 1,
              chapterName: chapterName,
            ),
        ],
      ),
    );
  }
}


class _NavigationBar extends StatelessWidget {
  final ReadingThemeData themeData;
  final int currentPage;
  final int totalPages;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onOpenChapterIndex;

  const _NavigationBar({
    required this.themeData,
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
      color: themeData.backgroundColor.withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            themeData: themeData,
            icon: Icons.arrow_back_rounded,
            enabled: canGoNext,
            onTap: onNext,
          ),
          if (onOpenChapterIndex != null)
            _NavButton(
              themeData: themeData,
              icon: Icons.menu_book_rounded,
              enabled: true,
              onTap: onOpenChapterIndex!,
              isAccent: true,
            ),
          _NavButton(
            themeData: themeData,
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
  final ReadingThemeData themeData;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isAccent;

  const _NavButton({
    required this.themeData,
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
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 26,
            color: enabled
                ? (isAccent ? Colors.blueAccent : themeData.textColor)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _PageInfoBadge extends StatelessWidget {
  final ReadingThemeData themeData;
  final int pageNumber;
  final String chapterName;
  final int juzNumber;

  const _PageInfoBadge({
    required this.themeData,
    required this.pageNumber,
    required this.chapterName,
    required this.juzNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: themeData.textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        // ✅ تم الإصلاح: استخدام إجمالي الصفحات ديناميكياً مع الأرقام العربية
        '${QuranDataProvider.toArabicNumerals(pageNumber)} / ${QuranDataProvider.toArabicNumerals(QuranDataProvider.totalPages)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: themeData.textColor,
        ),
      ),
    );
  }
}
