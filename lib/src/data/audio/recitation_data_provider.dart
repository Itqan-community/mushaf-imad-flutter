import '../../domain/models/audio_source.dart';
import '../../domain/models/recitation.dart';
import '../../domain/models/reciter.dart';
import '../../domain/models/riwayah.dart';

/// Provider for all available Quran recitations from mp3quran.net.
/// Data matches iOS/Android implementation for compatibility.
/// Internal implementation - not exposed in public API.
class RecitationDataProvider {
  RecitationDataProvider._();

  static const _defaultRiwayah = Riwayah(
    id: 1,
    nameArabic: 'حفص عن عاصم',
    nameEnglish: 'Hafs an Asim',
  );

  static const _mujawwadRiwayah = Riwayah(
    id: 2,
    nameArabic: 'حفص عن عاصم (مجود)',
    nameEnglish: 'Hafs an Asim (Mujawwad)',
  );

  /// List of all available recitations with timing data.
  static const List<Recitation> allRecitations = [
    Recitation(
      id: 1,
      reciter: Reciter(
        id: 1,
        nameArabic: 'عبد الباسط عبد الصمد',
        nameEnglish: 'Abdul Basit Abdul Samad',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 5,
      reciter: Reciter(
        id: 5,
        nameArabic: 'محمد صديق المنشاوي',
        nameEnglish: 'Mohamed Siddiq Al-Minshawi',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server10.mp3quran.net/minsh/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 9,
      reciter: Reciter(
        id: 9,
        nameArabic: 'محمود خليل الحصري',
        nameEnglish: 'Mahmoud Khalil Al-Hussary',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server13.mp3quran.net/husr/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 10,
      reciter: Reciter(
        id: 9,
        nameArabic: 'محمود خليل الحصري',
        nameEnglish: 'Mahmoud Khalil Al-Hussary',
      ),
      riwayah: _mujawwadRiwayah,
      folderUrl: 'https://server13.mp3quran.net/husr/Mujawwad/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 31,
      reciter: Reciter(
        id: 31,
        nameArabic: 'مشاري راشد العفاسي',
        nameEnglish: 'Mishari Rashid Al-Afasy',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server8.mp3quran.net/afs/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 32,
      reciter: Reciter(
        id: 32,
        nameArabic: 'سعد الغامدي',
        nameEnglish: 'Saad Al-Ghamdi',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server7.mp3quran.net/s_gmd/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 51,
      reciter: Reciter(
        id: 51,
        nameArabic: 'ماهر المعيقلي',
        nameEnglish: 'Maher Al-Muaiqly',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server12.mp3quran.net/maher/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 53,
      reciter: Reciter(
        id: 53,
        nameArabic: 'عبد الرحمن السديس',
        nameEnglish: 'Abdul Rahman Al-Sudais',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server11.mp3quran.net/sds/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 60,
      reciter: Reciter(
        id: 60,
        nameArabic: 'سعود الشريم',
        nameEnglish: 'Saud Al-Shuraim',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server7.mp3quran.net/shur/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 62,
      reciter: Reciter(
        id: 62,
        nameArabic: 'أحمد بن علي العجمي',
        nameEnglish: 'Ahmed ibn Ali Al-Ajmi',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server10.mp3quran.net/ajm/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 67,
      reciter: Reciter(
        id: 67,
        nameArabic: 'ياسر الدوسري',
        nameEnglish: 'Yasser Al-Dosari',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server11.mp3quran.net/yasser/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 74,
      reciter: Reciter(
        id: 74,
        nameArabic: 'عبد الله بصفر',
        nameEnglish: 'Abdullah Basfar',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server11.mp3quran.net/bsfr/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 78,
      reciter: Reciter(
        id: 78,
        nameArabic: 'خليفة الطنيجي',
        nameEnglish: 'Khalifa Al-Tunaiji',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server11.mp3quran.net/taniji/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 106,
      reciter: Reciter(
        id: 106,
        nameArabic: 'ناصر القطامي',
        nameEnglish: 'Nasser Al-Qatami',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server6.mp3quran.net/qtm/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 112,
      reciter: Reciter(
        id: 112,
        nameArabic: 'عبد الله الجهني',
        nameEnglish: 'Abdullah Al-Juhani',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server11.mp3quran.net/jhn/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 118,
      reciter: Reciter(
        id: 118,
        nameArabic: 'بندر بليلة',
        nameEnglish: 'Bandar Baleela',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server10.mp3quran.net/bnd/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 159,
      reciter: Reciter(
        id: 159,
        nameArabic: 'محمد أيوب',
        nameEnglish: 'Muhammad Ayyub',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server8.mp3quran.net/ayyub/',
      audioSource: MushafAudioSource.mp3quran,
    ),
    Recitation(
      id: 256,
      reciter: Reciter(
        id: 256,
        nameArabic: 'عبد الله المطرود',
        nameEnglish: 'Abdullah Al-Matroud',
      ),
      riwayah: _defaultRiwayah,
      folderUrl: 'https://server10.mp3quran.net/mat/',
      audioSource: MushafAudioSource.mp3quran,
    ),
  ];

  /// Get recitation by ID.
  static Recitation? getRecitationById(int recitationId) {
    try {
      return allRecitations.firstWhere((r) => r.id == recitationId);
    } catch (_) {
      return null;
    }
  }

  /// Get all recitation IDs.
  static List<int> getAllRecitationIds() {
    return allRecitations.map((r) => r.id).toList();
  }

  /// Search recitations by name (Arabic or English).
  static List<Recitation> searchRecitations(
    String query, {
    String languageCode = 'ar',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return allRecitations.where((recitation) {
      if (languageCode == 'ar') {
        return recitation.reciter.nameArabic.contains(normalizedQuery) ||
               recitation.riwayah.nameArabic.contains(normalizedQuery);
      }
      return recitation.reciter.nameEnglish.toLowerCase().contains(normalizedQuery) ||
             (recitation.riwayah.nameEnglish.toLowerCase().contains(normalizedQuery));
    }).toList();
  }

  /// Get default recitation (Abdul Basit).
  static Recitation getDefaultRecitation() {
    return allRecitations.first;
  }
}
