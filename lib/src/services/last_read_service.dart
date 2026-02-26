import '../data/repository/default_preferences_repository.dart';
import '../../domain/models/mushaf_type.dart';
import '../../domain/repository/preferences_repository.dart';

/// Service for managing last read page functionality.
/// 
/// Provides methods to:
/// - Save the current page when user turns pages
/// - Load the last read page on app startup
/// - Get the last read page number
class LastReadService {
  final PreferencesRepository _preferencesRepository;

  LastReadService({required PreferencesRepository preferencesRepository})
      : _preferencesRepository = preferencesRepository;

  /// Save the current page number.
  /// Call this whenever the user turns a page.
  Future<void> saveCurrentPage(int pageNumber) async {
    await _preferencesRepository.setCurrentPage(pageNumber);
  }

  /// Get the last read page number.
  /// Returns 1 if no page has been saved yet.
  Future<int> getLastReadPage() async {
    // Try to get from current page stream last value or fetch directly
    final prefsRepo = _preferencesRepository;
    if (prefsRepo is DefaultPreferencesRepository) {
      return await prefsRepo.getCurrentPage();
    }
    // Fallback: return default page 1
    return 1;
  }

  /// Load the last read page on app startup.
  /// Returns the page number to navigate to (defaults to 1).
  Future<int> loadLastReadPage() async {
    return await getLastReadPage();
  }
}
