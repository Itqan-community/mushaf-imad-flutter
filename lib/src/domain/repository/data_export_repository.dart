import '../models/result.dart';
import '../models/user_data_backup.dart';

/// Result of data import operation.
/// Public API - exposed to library consumers.
class ImportResult {
  final int bookmarksImported;
  final int lastReadPositionsImported;
  final int searchHistoryImported;
  final bool preferencesImported;
  final List<String> errors;

  const ImportResult({
    required this.bookmarksImported,
    required this.lastReadPositionsImported,
    required this.searchHistoryImported,
    required this.preferencesImported,
    this.errors = const [],
  });

  int get totalItemsImported =>
      bookmarksImported + lastReadPositionsImported + searchHistoryImported;

  bool get hasErrors => errors.isNotEmpty;
}

/// Repository for exporting and importing user data.
/// Public API - exposed to library consumers.
abstract class DataExportRepository {
  /// Export all user data to a backup object.
  Future<Result<UserDataBackup>> exportUserData({bool includeHistory = true});

  /// Export user data to JSON string.
  Future<Result<String>> exportToJson({bool includeHistory = true});

  /// Import user data from a backup object.
  Future<Result<ImportResult>> importUserData(
    UserDataBackup backup, {
    bool mergeWithExisting = true,
  });

  /// Import user data from JSON string.
  Future<Result<ImportResult>> importFromJson(
    String json, {
    bool mergeWithExisting = true,
  });

  /// Clear all user data (bookmarks, history, etc.).
  Future<Result<void>> clearAllUserData();
}
