import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/reciter_info.dart';
import '../../domain/models/reciter_timing.dart';
import 'audio_source_config.dart';
import 'reciter_data_provider.dart';

/// Default source backed by package assets and static reciter list.
class BundledAudioDataSource implements MushafAudioDataSource {
  const BundledAudioDataSource();

  @override
  Future<List<ReciterInfo>> fetchAllReciters() async =>
      ReciterDataProvider.allReciters;

  @override
  Future<ReciterTiming?> fetchReciterTiming(int reciterId) async {
    try {
      final jsonString = await rootBundle.loadString(
        'packages/imad_flutter/assets/ayah_timing/read_$reciterId.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ReciterTiming.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> fetchChapterAudioUrl(
    int reciterId,
    int chapterNumber,
  ) async => null;
}
