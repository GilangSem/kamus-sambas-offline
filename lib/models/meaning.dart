/// Model untuk makna kata (meanings table)
class Meaning {
  final String id;
  final String wordId;
  final String? wordClassId;
  final String? inheritedFromMeaningId;
  final String definition;
  final int isHaveDefinition;
  final int isHaveTranslation;
  final String meaningSource;
  final int orderIndex;
  final String? notes;
  final String status;
  final int isVerified;
  final int isCorrected;

  Meaning({
    required this.id,
    required this.wordId,
    this.wordClassId,
    this.inheritedFromMeaningId,
    required this.definition,
    this.isHaveDefinition = 1,
    this.isHaveTranslation = 1,
    this.meaningSource = 'manual',
    this.orderIndex = 0,
    this.notes,
    required this.status,
    this.isVerified = 0,
    this.isCorrected = 0,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      wordClassId: json['word_class_id'] as String?,
      inheritedFromMeaningId: json['inherited_from_meaning_id'] as String?,
      definition: json['definition'] as String,
      isHaveDefinition: json['is_have_definition'] as int? ?? 1,
      isHaveTranslation: json['is_have_translation'] as int? ?? 1,
      meaningSource: json['meaning_source'] as String? ?? 'manual',
      orderIndex: json['order_index'] as int? ?? 0,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
      isCorrected: json['is_corrected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_id': wordId,
      'word_class_id': wordClassId,
      'inherited_from_meaning_id': inheritedFromMeaningId,
      'definition': definition,
      'is_have_definition': isHaveDefinition,
      'is_have_translation': isHaveTranslation,
      'meaning_source': meaningSource,
      'order_index': orderIndex,
      'notes': notes,
      'status': status,
      'is_verified': isVerified,
      'is_corrected': isCorrected,
    };
  }

  @override
  String toString() => 'Meaning(id: $id, definition: $definition)';
}
