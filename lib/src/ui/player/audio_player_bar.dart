import 'package:flutter/material.dart';
import 'package:imad_flutter/imad_flutter.dart';

/// A bottom bar widget that provides audio playback controls for the Mujawwad/Quran recitations.
class AudioPlayerBar extends StatefulWidget {
  final int chapterNumber;
  final String chapterName;
  final bool autoPlay;
  final int?
  startVerseNumber; // Explicit verse to start from (e.g. tapped verse)
  final int?
  currentPage; // Current page, used to derive start verse if no explicit verse

  const AudioPlayerBar({
    super.key,
    required this.chapterNumber,
    required this.chapterName,
    this.autoPlay = false,
    this.currentPage,
    this.startVerseNumber,
  });

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  late final QuranPlayerViewModel _viewModel;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = QuranPlayerViewModel(
      audioRepository: mushafGetIt<AudioRepository>(),
      preferencesRepository: mushafGetIt<PreferencesRepository>(),
    );
    _initViewModel();
  }

  /// Resolves which verse to start playback from.
  ///
  /// Priority:
  ///   1. Explicit [startVerseNumber] — user tapped a specific verse
  ///   2. First verse on [currentPage] — derived from QuranDataProvider
  ///   3. Fallback: verse 1
  int _resolveStartVerse() {
    if (widget.startVerseNumber != null) {
      MushafLibrary.logger.debug(
        '[AudioPlayerBar] _resolveStartVerse → explicit startVerseNumber=${widget.startVerseNumber}',
      );
      return widget.startVerseNumber!;
    }

    if (widget.currentPage != null) {
      final verses = VerseDataProvider.instance.getVersesForPage(
        widget.currentPage!,
      );
      MushafLibrary.logger.debug(
        '[AudioPlayerBar] _resolveStartVerse → page=${widget.currentPage}, versesOnPage=${verses.length}, first=${verses.isNotEmpty ? verses.first.number : "NONE"}',
      );
      if (verses.isNotEmpty) return verses.first.number;
    }

    MushafLibrary.logger.debug(
      '[AudioPlayerBar] _resolveStartVerse → fallback verse=1',
    );
    return 1;
  }

  Future<void> _initViewModel() async {
    await _viewModel.initialize();

    if (mounted) {
      setState(() => _initialized = true);

      if (widget.chapterNumber > 0 && _viewModel.selectedReciter != null) {
        final startVerse = _resolveStartVerse();
        MushafLibrary.logger.debug(
          '[AudioPlayerBar] _initViewModel → chapter=${widget.chapterNumber}, reciter=${_viewModel.selectedReciter!.id}, startVerse=$startVerse, autoPlay=${widget.autoPlay}',
        );
        await mushafGetIt<AudioRepository>().loadChapter(
          widget.chapterNumber,
          _viewModel.selectedReciter!.id,
          autoPlay: widget.autoPlay,
          startVerseNumber: startVerse,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_initialized) return;

    final chapterChanged = widget.chapterNumber != oldWidget.chapterNumber;
    final pageChanged = widget.currentPage != oldWidget.currentPage;
    final verseChanged = widget.startVerseNumber != oldWidget.startVerseNumber;

    // Re-load whenever chapter, page, or explicit verse changes.
    // NOTE: removed the `currentChapter != widget.chapterNumber` guard —
    // that condition was preventing seeks within the same chapter when the
    // user scrolled to a new page or tapped a different verse.
    if (!chapterChanged && !pageChanged && !verseChanged) return;

    if (_viewModel.selectedReciter == null) return;

    final startVerse = _resolveStartVerse();
    MushafLibrary.logger.debug(
      '[AudioPlayerBar] didUpdateWidget → chapter=${widget.chapterNumber} (chapterChanged=$chapterChanged), page=${widget.currentPage} (pageChanged=$pageChanged), startVerse=$startVerse (verseChanged=$verseChanged)',
    );

    mushafGetIt<AudioRepository>().loadChapter(
      widget.chapterNumber,
      _viewModel.selectedReciter!.id,
      autoPlay: widget.autoPlay,
      startVerseNumber: startVerse,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).truncate();
    final minutes = (seconds / 60).truncate();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (!_initialized || _viewModel.isLoading) {
          return const Material(
            elevation: 8.0,
            child: SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final state = _viewModel.playerState;
        final reciter = _viewModel.selectedReciter;
        final duration = state.durationMs;
        final position = state.currentPositionMs;
        final progress = duration > 0
            ? (position / duration).clamp(0.0, 1.0)
            : 0.0;
        final isPlaying = state.isPlaying;
        final isRepeatEnabled = state.isRepeatEnabled;

        final accentColor = const Color(0xFF2D7F6E);

        return Material(
          elevation: 8.0,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reciter Picker Button
                      InkWell(
                        onTap: () => _showReciterPicker(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reciter?.getDisplayName() ?? 'Select Reciter',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ),
                      ),

                      // Surah Info
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.chapterName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (state.currentVerse != null) ...[
                            Text(
                              ":",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${state.currentVerse}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: accentColor,
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                      thumbColor: accentColor,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (val) {
                        final newPos = (val * duration).toInt();
                        _viewModel.seekTo(newPos);
                      },
                    ),
                  ),

                  // Time Labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(position),
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '-${_formatTime(duration - position)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Controls Layer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Repeat Mode
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: isRepeatEnabled
                              ? accentColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _viewModel.toggleRepeat,
                        tooltip: 'Toggle Repeat',
                      ),

                      // Previous Chapter (Stub)
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () {},
                        tooltip: 'Previous',
                      ),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          iconSize: 36,
                          icon: state.playbackState == PlaybackState.loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: accentColor,
                                ),
                          onPressed:
                              state.playbackState == PlaybackState.loading
                              ? null
                              : _viewModel.togglePlayPause,
                        ),
                      ),

                      // Next Chapter (Stub)
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: () {},
                        tooltip: 'Next',
                      ),

                      // Speed Controller
                      TextButton(
                        onPressed: () {
                          final newSpeed = _viewModel.playbackSpeed == 1.0
                              ? 1.5
                              : 1.0;
                          _viewModel.setPlaybackSpeed(newSpeed);
                        },
                        child: Text(
                          '${_viewModel.playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReciterPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Reciter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _viewModel.reciters.length,
                  itemBuilder: (context, index) {
                    final isSelected =
                        _viewModel.selectedReciter?.id ==
                        _viewModel.reciters[index].id;
                    return ListTile(
                      title: Text(_viewModel.reciters[index].getDisplayName()),
                      subtitle: Text(_viewModel.reciters[index].rewaya),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2D7F6E))
                          : null,
                      onTap: () {
                        _viewModel.selectReciter(_viewModel.reciters[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
