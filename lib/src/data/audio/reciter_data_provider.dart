import '../../domain/models/reciter_info.dart';

/// Provider for all available Quran reciters.
/// Data matches iOS/Android implementation for compatibility.
/// Internal implementation - not exposed in public API.
class ReciterDataProvider {
  ReciterDataProvider._();

  /// List of all available reciters with timing data.
  static const List<ReciterInfo> allReciters = [
    ReciterInfo(
      id: 1,
      nameArabic: 'عبد الباسط عبد الصمد',
      nameEnglish: 'Abdul Basit Abdul Samad',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server6.mp3quran.net/abas_64/',
    ),
    ReciterInfo(
      id: 5,
      nameArabic: 'محمد صديق المنشاوي',
      nameEnglish: 'Mohamed Siddiq Al-Minshawi',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server10.mp3quran.net/minsh/Rewayat-Hafs-A-n-Assem/',
    ),
    ReciterInfo(
      id: 9,
      nameArabic: 'محمود خليل الحصري',
      nameEnglish: 'Mahmoud Khalil Al-Hussary',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server13.mp3quran.net/husr/',
    ),
    ReciterInfo(
      id: 10,
      nameArabic: 'محمود خليل الحصري (مجود)',
      nameEnglish: 'Mahmoud Khalil Al-Hussary (Mujawwad)',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server13.mp3quran.net/husr/Mujawwad/',
    ),
    ReciterInfo(
      id: 31,
      nameArabic: 'مشاري راشد العفاسي',
      nameEnglish: 'Mishari Rashid Al-Afasy',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server8.mp3quran.net/afs/',
    ),
    ReciterInfo(
      id: 32,
      nameArabic: 'سعد الغامدي',
      nameEnglish: 'Saad Al-Ghamdi',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server7.mp3quran.net/s_gmd/',
    ),
    ReciterInfo(
      id: 51,
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al-Muaiqly',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server12.mp3quran.net/maher/',
    ),
    ReciterInfo(
      id: 53,
      nameArabic: 'عبد الرحمن السديس',
      nameEnglish: 'Abdul Rahman Al-Sudais',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server11.mp3quran.net/sds/',
    ),
    ReciterInfo(
      id: 60,
      nameArabic: 'سعود الشريم',
      nameEnglish: 'Saud Al-Shuraim',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server7.mp3quran.net/shur/',
    ),
    ReciterInfo(
      id: 62,
      nameArabic: 'أحمد بن علي العجمي',
      nameEnglish: 'Ahmed ibn Ali Al-Ajmi',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server10.mp3quran.net/ajm/',
    ),
    ReciterInfo(
      id: 67,
      nameArabic: 'ياسر الدوسري',
      nameEnglish: 'Yasser Al-Dosari',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server11.mp3quran.net/yasser/',
    ),
    ReciterInfo(
      id: 74,
      nameArabic: 'عبد الله بصفر',
      nameEnglish: 'Abdullah Basfar',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server11.mp3quran.net/bsfr/',
    ),
    ReciterInfo(
      id: 78,
      nameArabic: 'خليفة الطنيجي',
      nameEnglish: 'Khalifa Al-Tunaiji',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server11.mp3quran.net/taniji/',
    ),
    ReciterInfo(
      id: 106,
      nameArabic: 'ناصر القطامي',
      nameEnglish: 'Nasser Al-Qatami',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server6.mp3quran.net/qtm/',
    ),
    ReciterInfo(
      id: 112,
      nameArabic: 'عبد الله الجهني',
      nameEnglish: 'Abdullah Al-Juhani',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server11.mp3quran.net/jhn/',
    ),
    ReciterInfo(
      id: 118,
      nameArabic: 'بندر بليلة',
      nameEnglish: 'Bandar Baleela',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server10.mp3quran.net/bnd/',
    ),
    ReciterInfo(
      id: 159,
      nameArabic: 'محمد أيوب',
      nameEnglish: 'Muhammad Ayyub',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server8.mp3quran.net/ayyub/',
    ),
    ReciterInfo(
      id: 256,
      nameArabic: 'عبد الله المطرود',
      nameEnglish: 'Abdullah Al-Matroud',
      rewaya: 'حفص عن عاصم',
      folderUrl: 'https://server10.mp3quran.net/mat/',
    ),
  ];

  /// Get reciter by ID.
  static ReciterInfo? getReciterById(int reciterId) {
    try {
      return allReciters.firstWhere((r) => r.id == reciterId);
    } catch (_) {
      return null;
    }
  }

  /// Get all reciter IDs.
  static List<int> getAllReciterIds() {
    return allReciters.map((r) => r.id).toList();
  }

  /// Search reciters by name (Arabic or English).
  static List<ReciterInfo> searchReciters(
    String query, {
    String languageCode = 'en',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return allReciters.where((reciter) {
      if (languageCode == 'ar') {
        return reciter.nameArabic.contains(normalizedQuery);
      }
      return reciter.nameEnglish.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Get reciters by rewaya (recitation style).
  static List<ReciterInfo> getRecitersByRewaya(String rewaya) {
    final normalizedRewaya = rewaya.trim().toLowerCase();
    return allReciters
        .where((r) => r.rewaya.toLowerCase().contains(normalizedRewaya))
        .toList();
  }

  /// Get all Hafs reciters.
  static List<ReciterInfo> getHafsReciters() {
    return allReciters.where((r) => r.isHafs).toList();
  }

  /// Get default reciter (Abdul Basit).
  static ReciterInfo getDefaultReciter() {
    return allReciters.first;
  }
}
