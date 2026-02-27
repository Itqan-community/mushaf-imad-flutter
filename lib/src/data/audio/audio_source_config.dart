import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';

/// Built-in audio data source options.
enum MushafAudioSource { bundledAssets, cmsItqanDev }

/// Configuration for the cms.itqan.dev audio source.
class CmsAudioSourceConfig {
  final String apiBaseUrl;
  final int pageSize;
  final Duration timeout;

  const CmsAudioSourceConfig({
    this.apiBaseUrl = 'https://api.cms.itqan.dev/cms-api',
    this.pageSize = 100,
    this.timeout = const Duration(seconds: 15),
  });
}

/// Contract for resolving reciters, chapter URLs, and timing data.
abstract class MushafAudioDataSource {
  Future<List<ReciterInfo>> fetchAllReciters();

  Future<ReciterTiming?> fetchReciterTiming(int reciterId);

  Future<String?> fetchChapterAudioUrl(int reciterId, int chapterNumber);
}
