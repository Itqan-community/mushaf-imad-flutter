import 'audio_source.dart';

/// Information about a Quran reciter.
/// Public API - exposed to library consumers.
class ReciterInfo {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String folderUrl; // Base URL for audio files

  /// The audio backend that provides this reciter's data and audio files.
  ///
  /// Used by the composite repository to route playback requests to the
  /// correct [AudioPlaybackSource] implementation.
  final MushafAudioSource audioSource;

  const ReciterInfo({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.folderUrl,
    this.audioSource = MushafAudioSource.mp3quran,
  });

  /// Get reciter display name based on language.
  String getDisplayName({String languageCode = 'en'}) {
    return languageCode == 'ar' ? nameArabic : nameEnglish;
  }

  /// Get audio URL for a specific chapter (surah).
  String getAudioUrl(int chapterNumber) {
    final paddedChapter = chapterNumber.toString().padLeft(3, '0');
    return '$folderUrl$paddedChapter.mp3';
  }

}
