import 'audio_source.dart';
import 'reciter.dart';
import 'riwayah.dart';

/// A recitation -- the selectable unit in the audio picker.
///
/// Represents a specific audio recording (asset) by a [Reciter] in a given
/// [Riwayah]. This is what the user sees in the dropdown/bottom sheet.
/// Display format: "{reciter name} -- {riwayah name}".
class Recitation {
  /// Unique ID within the audio source (e.g., the asset ID from the API,
  /// or the recitation ID from mp3quran.net where each entry is a recitation).
  final int id;

  /// The reciter who performed this recitation.
  final Reciter reciter;

  /// The riwayah (transmission chain) used in this recitation.
  final Riwayah riwayah;

  /// Which audio source backend provides this recitation's data.
  final MushafAudioSource audioSource;

  /// Base URL for audio files (used by mp3quran.net source).
  /// For API-based sources this may be empty or constructed dynamically.
  final String folderUrl;

  const Recitation({
    required this.id,
    required this.reciter,
    required this.riwayah,
    this.audioSource = MushafAudioSource.mp3quran,
    this.folderUrl = '',
  });

  /// Composite key for persistence: "source:id".
  String get persistenceKey => '${audioSource.name}:$id';

  /// Display name for the UI.
  String getDisplayName({String languageCode = 'ar'}) {
    final reciterName = reciter.getDisplayName(languageCode: languageCode);
    return '$reciterName';
  }

  /// Get audio URL for a chapter (only meaningful for mp3quran.net source).
  String getAudioUrl(int chapterNumber) {
    if (folderUrl.isEmpty) return '';
    final paddedChapter = chapterNumber.toString().padLeft(3, '0');
    return '$folderUrl$paddedChapter.mp3';
  }
}
