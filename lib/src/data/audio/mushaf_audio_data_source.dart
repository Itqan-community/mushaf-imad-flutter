import 'package:imad_flutter/src/domain/models/recitation.dart';
import 'package:imad_flutter/src/domain/models/reciter_timing.dart';

/// Abstract contract for retrieving audio metadata and timings
abstract class MushafAudioDataSource {
  /// Fetches a list of all available recitations from the source.
  Future<List<Recitation>> fetchAllRecitations();

  /// Fetches the base audio URL or specific URL for a chapter and recitation.
  Future<String> fetchChapterAudioUrl(int recitationId, int chapterNumber);

  /// Fetches bulk timing sequence (verse level timestamps) for a chapter.
  /// If [null] is returned, it implies the source cannot provide dynamic local timings.
  Future<List<AyahTiming>?> fetchChapterTiming(
    int recitationId,
    int chapterNumber,
  );
}
