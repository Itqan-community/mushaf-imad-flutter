import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/repository/audio_repository.dart';
import '../../domain/models/audio_player_state.dart';
import '../../core/di/service_locator.dart';
import 'quran_page_widget.dart';

class MushafPageView extends StatefulWidget {
  const MushafPageView({super.key});

  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  late PageController _pageController;
  StreamSubscription<AudioPlayerState>? _audioSubscription;
  int? _selectedVerseKey;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initAudioListener();
  }

  void _initAudioListener() {
    final audioRepo = mushafGetIt<AudioRepository>();
    _audioSubscription = audioRepo.getPlayerStateStream().listen((state) {
      if (!mounted) return;
      if (state.currentVerse != null && state.currentChapter != null) {
        setState(() {
          _selectedVerseKey =
              (state.currentChapter! * 1000) + state.currentVerse!;
        });
      }
    });
  }

  void _playFromVerse(int chapter, int verse) async {
    final audioRepo = mushafGetIt<AudioRepository>();
    final reciter = await audioRepo.getSelectedReciterStream().first;
    if (reciter == null) return;

    audioRepo.loadChapter(
      chapter,
      reciter.id,
      autoPlay: true,
      startAyahNumber: verse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      backgroundColor: themeData.scaffoldBackgroundColor,
      body: PageView.builder(
        controller: _pageController,
        reverse: true,
        itemCount: 604,
        onPageChanged: (page) {
          setState(() => _currentPage = page + 1);
        },
        itemBuilder: (context, index) {
          return QuranPageWidget(
            pageNumber: index + 1,
            verses: const [],
            markers: const [],
            highlightedVerseKey: _selectedVerseKey,
            themeData: themeData,
            onVerseTap: (chapter, verse) {
              setState(() {
                _selectedVerseKey = (chapter * 1000) + verse;
              });
            },
            onVerseLongPress: (chapter, verse) {
              _playFromVerse(chapter, verse);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
