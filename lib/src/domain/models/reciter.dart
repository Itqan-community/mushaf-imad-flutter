/// A Quran reciter (person).
class Reciter {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final String? bio;

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    this.bio,
  });

  String getDisplayName({String languageCode = 'ar'}) =>
      languageCode == 'ar' ? nameArabic : nameEnglish;
}
