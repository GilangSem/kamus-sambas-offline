/// Model untuk varian kata (word_variants table)
class WordVariant {
  final String id;
  final String wordId;
  final String form;
  final String variantType;
  final String? affixType;
  final String? affixValue;
  final String? dialectId;
  final String? notes;

  WordVariant({
    required this.id,
    required this.wordId,
    required this.form,
    this.variantType = 'alternative',
    this.affixType,
    this.affixValue,
    this.dialectId,
    this.notes,
  });

  factory WordVariant.fromJson(Map<String, dynamic> json) {
    return WordVariant(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      form: json['form'] as String,
      variantType: json['variant_type'] as String? ?? 'alternative',
      affixType: json['affix_type'] as String?,
      affixValue: json['affix_value'] as String?,
      dialectId: json['dialect_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_id': wordId,
      'form': form,
      'variant_type': variantType,
      'affix_type': affixType,
      'affix_value': affixValue,
      'dialect_id': dialectId,
      'notes': notes,
    };
  }

  @override
  String toString() => 'WordVariant(id: $id, form: $form)';
}
