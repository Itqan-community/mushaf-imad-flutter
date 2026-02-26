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
  StreamSubscription? _audioSubscription;
  int? _selectedVerseKey;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initAudioListener();
  }

  void _initAudioListener() {
    _audioSubscription = mushafGetIt<AudioRepository>()
        .getPlayerStateStream()
        .listen((state) {
      if (mounted && state.currentVerse != null) {
        setState(() {
          _selectedVerseKey = state.currentChapter! * 1000 + state.currentVerse!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            reverse: true,
            itemCount: 604,
            onPageChanged: (page) => setState(() => _currentPage = page + 1),
            itemBuilder: (context, index) {
              return QuranPageWidget(
                pageNumber: index + 1,
                verses: [], // مرر بيانات الآيات هنا
                markers: [], // مرر بيانات العلامات هنا
                highlightedVerseKey: _selectedVerseKey,
                onVerseTap: (chapter, verse) {
                  setState(() => _selectedVerseKey = chapter * 1000 + verse);
                },
                onVerseLongPress: (chapter, verse) {
                  mushafGetIt<AudioRepository>().loadChapter(
                    chapter,
                    1, // معرف القارئ الافتراضي كمثال
                    autoPlay: true,
                    startAyahNumber: verse,
                  );
                },
              );
            },
          ),
          _buildBottomNavigation(theme),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavButton(icon: Icons.arrow_back_ios, onTap: () {}),
            Text("Page $_currentPage", style: theme.textTheme.titleMedium),
            _buildNavButton(icon: Icons.arrow_forward_ios, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? theme.colorScheme.primary : theme.disabledColor,
          ),
        ),
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
