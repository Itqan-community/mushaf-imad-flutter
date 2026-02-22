import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/audio_player_state.dart';
import '../../domain/models/reciter_info.dart';
import '../../domain/repository/audio_repository.dart';
import '../../domain/repository/preferences_repository.dart';

/// ViewModel for the Quran audio player.
class QuranPlayerViewModel extends ChangeNotifier {
  final AudioRepository _audioRepository;
  final PreferencesRepository _preferencesRepository;

  StreamSubscription<AudioPlayerState>? _playerStateSub;
  StreamSubscription<ReciterInfo?>? _reciterSub;

  QuranPlayerViewModel({
    required AudioRepository audioRepository,
    required PreferencesRepository preferencesRepository,
  }) : _audioRepository = audioRepository,
       _preferencesRepository = preferencesRepository;

  // State
  AudioPlayerState _playerState = const AudioPlayerState();
  List<ReciterInfo> _reciters = [];
  ReciterInfo? _selectedReciter;
  double _playbackSpeed = 1.0;
  bool _isLoading = false;

  // Getters
  AudioPlayerState get playerState => _playerState;
  List<ReciterInfo> get reciters => _reciters;
  ReciterInfo? get selectedReciter => _selectedReciter;
  double get playbackSpeed => _playbackSpeed;
  bool get isLoading => _isLoading;
  bool get isPlaying => _playerState.isPlaying;

  /// Initialize the player ViewModel.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reciters = await _audioRepository.getAllReciters();

      final reciterId = await _preferencesRepository.getSelectedReciterId();
      _selectedReciter = await _audioRepository.getReciterById(reciterId);
      _selectedReciter ??= await _audioRepository.getDefaultReciter();

      _playbackSpeed = await _preferencesRepository.getPlaybackSpeed();

      // Observe player state
      _playerStateSub = _audioRepository.getPlayerStateStream().listen((state) {
        _playerState = state;
        notifyListeners();
      });

      // Observe selected reciter
      _reciterSub = _audioRepository.getSelectedReciterStream().listen((
        reciter,
      ) {
        _selectedReciter = reciter;
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Play a chapter with the selected reciter.
  void playChapter(int chapterNumber) {
    if (_selectedReciter == null) return;
    _audioRepository.loadChapter(
      chapterNumber,
      _selectedReciter!.id,
      autoPlay: true,
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

  /// Select a reciter.
  Future<void> selectReciter(ReciterInfo reciter) async {
    _selectedReciter = reciter;
    _audioRepository.saveSelectedReciter(reciter);
    await _preferencesRepository.setSelectedReciterId(reciter.id);
    notifyListeners();
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
    _reciterSub?.cancel();
    super.dispose();
  }
}
