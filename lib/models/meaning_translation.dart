/// Model untuk terjemahan makna (meaning_translations table)
class MeaningTranslation {
  final String id;
  final String meaningId;
  final String languageId;
  final String translationText;
  final String translationType;
  final String? notes;

  MeaningTranslation({
    required this.id,
    required this.meaningId,
    required this.languageId,
    required this.translationText,
    this.translationType = 'direct',
    this.notes,
  });

  factory MeaningTranslation.fromJson(Map<String, dynamic> json) {
    return MeaningTranslation(
      id: json['id'] as String,
      meaningId: json['meaning_id'] as String,
      languageId: json['language_id'] as String,
      translationText: json['translation_text'] as String,
      translationType: json['translation_type'] as String? ?? 'direct',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meaning_id': meaningId,
      'language_id': languageId,
      'translation_text': translationText,
      'translation_type': translationType,
      'notes': notes,
    };
  }

  @override
  String toString() =>
      'MeaningTranslation(id: $id, translation: $translationText)';
}
