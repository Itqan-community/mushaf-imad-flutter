/// A riwayah (transmission chain, e.g. "Hafs an Asim").
class Riwayah {
  final int id;
  final String nameArabic;
  final String nameEnglish;

  const Riwayah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
  });

  String getDisplayName({String languageCode = 'ar'}) =>
      languageCode == 'ar' ? nameArabic : nameEnglish;
}
