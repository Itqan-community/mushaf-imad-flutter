import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/audio_player_state.dart';
import '../../domain/models/recitation.dart';
import '../../domain/repository/audio_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for the Quran audio player.
class QuranPlayerViewModel extends ChangeNotifier {
  final AudioRepository _audioRepository;
  final PreferencesRepository _preferencesRepository;
  StreamSubscription<AudioPlayerState>? _playerStateSub;
  StreamSubscription<Recitation?>? _recitationSub;

  QuranPlayerViewModel({
    required AudioRepository audioRepository,
    required PreferencesRepository preferencesRepository,
  }) : _audioRepository = audioRepository,
       _preferencesRepository = preferencesRepository;

  // State
  AudioPlayerState _playerState = const AudioPlayerState();
  List<Recitation> _recitations = [];
  Recitation? _selectedRecitation;
  double _playbackSpeed = 1.0;
  bool _isLoading = false;
  String? _errorMessage;

  int? _lastKnownVerseChapter;
  int? _lastKnownVerse;

  // Getters
  AudioPlayerState get playerState => _playerState;
  List<Recitation> get recitations => _recitations;
  Recitation? get selectedRecitation => _selectedRecitation;
  double get playbackSpeed => _playbackSpeed;
  bool get isLoading => _isLoading;
  bool get isPlaying => _playerState.isPlaying;
  String? get errorMessage => _errorMessage;

  /// Initialize the player ViewModel.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _recitations = await _audioRepository.getAllRecitations();
      final recitationId = await _preferencesRepository
          .getSelectedRecitationId();
      _selectedRecitation = await _audioRepository.getRecitationById(
        recitationId,
      );
      _selectedRecitation ??= await _audioRepository.getDefaultRecitation();
      _playbackSpeed = await _preferencesRepository.getPlaybackSpeed();

      // Observe player state
      _playerStateSub = _audioRepository.getPlayerStateStream().listen((state) {
        _playerState = state;
        if (state.currentChapter != null && state.currentVerse != null) {
          _lastKnownVerseChapter = state.currentChapter;
          _lastKnownVerse = state.currentVerse;
        }
        notifyListeners();
      });

      // Observe selected recitation
      _recitationSub = _audioRepository.getSelectedRecitationStream().listen((
        recitation,
      ) {
        _selectedRecitation = recitation;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[QuranPlayerViewModel] Error initializing audio player: $e');
      _errorMessage = 'Failed to load audio player.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play a chapter with the selected recitation.
  ///
  /// [startVerseNumber] controls where playback begins within the chapter.
  /// Defaults to 1 (start of chapter) when not specified.
  void playChapter(int chapterNumber, {int startVerseNumber = 1}) {
    if (_selectedRecitation == null) return;
    _audioRepository.loadChapter(
      chapterNumber,
      _selectedRecitation!,
      autoPlay: true,
      startVerseNumber: startVerseNumber,
    );
  }

  /// Toggle play/pause.
  void togglePlayPause() {
    if (_playerState.isPlaying) {
      _audioRepository.pause();
    } else {
      _audioRepository.play();
    }
  }

  /// Stop playback.
  void stop() => _audioRepository.stop();

  /// Seek to position.
  void seekTo(int positionMs) => _audioRepository.seekTo(positionMs);

  /// Select a recitation.
  ///
  /// If audio is playing or paused, the new reciter is loaded immediately at
  /// the current verse.
  Future<void> selectRecitation(Recitation recitation) async {
    // Snapshot playback state before any await so later stream ticks
    // (e.g. a stop triggered by the switch) cannot change the decision.
    final state = _playerState;
    final chapter = state.currentChapter;
    final wasPlaying = state.isPlaying;
    final isActive =
        chapter != null &&
        (wasPlaying || state.playbackState == PlaybackState.paused);
    final startVerse =
        state.currentVerse ??
        (_lastKnownVerseChapter == chapter ? _lastKnownVerse : null) ??
        1;

    _selectedRecitation = recitation;
    _audioRepository.saveSelectedRecitation(recitation);
    notifyListeners();
    await _preferencesRepository.setSelectedRecitationId(recitation.id);

    if (isActive) {
      try {
        await _audioRepository.loadChapter(
          chapter,
          recitation,
          autoPlay: wasPlaying,
          startVerseNumber: startVerse,
        );
      } catch (e) {
        debugPrint('[QuranPlayerViewModel] Error switching recitation: $e');
        _errorMessage = 'Failed to switch reciter.';
        notifyListeners();
      }
    }
  }

  /// Set playback speed.
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    _audioRepository.setPlaybackSpeed(speed);
    await _preferencesRepository.setPlaybackSpeed(speed);
    notifyListeners();
  }

  /// Toggle repeat mode.
  void toggleRepeat() {
    final enabled = !_audioRepository.isRepeatEnabled();
    _audioRepository.setRepeatMode(enabled);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _recitationSub?.cancel();
    super.dispose();
  }
}
