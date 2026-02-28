/// A reciter as returned by the Quran.com “recitations” endpoint.
class QuranComReciter {
  /// The numeric ID used by the API.
  final int id;

  /// The default (usually English) name of the reciter.
  final String reciterName;

  /// A human‑readable description of the recitation style, if any.
  /// Examples include “Mujawwad” and “Murattal”.
  final String? style;

  /// Any translations available for the name.
  final QuranComTranslatedName? translatedName;

  const QuranComReciter({
    required this.id,
    required this.reciterName,
    this.style,
    this.translatedName,
  });

  factory QuranComReciter.fromJson(Map<String, dynamic> json) {
    return QuranComReciter(
      id: json['id'] as int,
      reciterName: json['reciter_name'] as String,
      style: json['style'] as String?, // might be null
      translatedName: json['translated_name'] != null
          ? QuranComTranslatedName.fromJson(
              json['translated_name'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reciter_name': reciterName,
    'style': style,
    'translated_name': translatedName?.toJson(),
  };
}

/// Structure of the `translated_name` sub‑object.
class QuranComTranslatedName {
  final String name;
  final String languageName;

  const QuranComTranslatedName({
    required this.name,
    required this.languageName,
  });

  factory QuranComTranslatedName.fromJson(Map<String, dynamic> json) {
    return QuranComTranslatedName(
      name: json['name'] as String,
      languageName: json['language_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'language_name': languageName,
  };
}

/// Wrapper for the list of reciters returned by the API.
class QuranComRecitationsResponse {
  final List<QuranComReciter> recitations;

  const QuranComRecitationsResponse({required this.recitations});

  factory QuranComRecitationsResponse.fromJson(Map<String, dynamic> json) {
    return QuranComRecitationsResponse(
      recitations: (json['recitations'] as List<dynamic>)
          .map((e) => QuranComReciter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'recitations': recitations.map((e) => e.toJson()).toList(),
  };
}
