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

  /// ✅ تحسين المشترك (Listener) لضمان عدم حدوث Memory Leak
  void _initAudioListener() {
    final audioRepo = mushafGetIt<AudioRepository>();
    _audioSubscription = audioRepo.getPlayerStateStream().listen((state) {
      if (mounted && state.currentVerse != null && state.currentChapter != null) {
        setState(() {
          // حساب الـ Key لتمييز الآية (مثلاً: سورة 1 آية 2 تصبح 1002)
          _selectedVerseKey = (state.currentChapter! * 1000) + state.currentVerse!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      backgroundColor: themeData.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            reverse: true, // للمصحف من اليمين لليسار
            itemCount: 604,
            onPageChanged: (page) {
              setState(() => _currentPage = page + 1);
            },
            itemBuilder: (context, index) {
              return QuranPageWidget(
                pageNumber: index + 1,
                verses: const [], // يجب تمرير قائمة الآيات من الـ Data Provider هنا
                markers: const [], // يجب تمرير علامات الأجزاء هنا
                highlightedVerseKey: _selectedVerseKey,
                themeData: themeData, // ✅ تم حل مشكلة الـ Named Parameter هنا
                onVerseTap: (chapter, verse) {
                  setState(() {
                    _selectedVerseKey = (chapter * 1000) + verse;
                  });
                },
                onVerseLongPress: (chapter, verse) {
                  // ✅ تشغيل الصوت عند الضغط المطول من الآية المحددة
                  mushafGetIt<AudioRepository>().loadChapter(
                    chapter,
                    1, // معرف القارئ (يمكنك تغييره حسب المختار)
                    autoPlay: true,
                    startAyahNumber: verse,
                  );
                },
              );
            },
          ),
          _buildBottomNavigation(themeData),
        ],
      ),
    );
  }

  /// ✅ بناء بار التنقل السفلي مع تحسينات CodeRabbit
  Widget _buildBottomNavigation(ThemeData theme) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              theme: theme,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "صفحة",
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor),
                ),
                Text(
                  "$_currentPage",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            _buildNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ تحسين الزر بمساحة لمس 48dp وحواف دائرية وألوان من الثيم
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0), // لضمان مساحة ضغط مريحة
          child: Icon(
            icon,
            size: 22,
            color: theme.colorScheme.primary,
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
