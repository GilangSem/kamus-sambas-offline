/// Model untuk relasi leksikal (lexical_relations table)
class LexicalRelation {
  final String id;
  final String sourceWordId;
  final String targetWordId;
  final String relationType;
  final String? notes;
  final String status;
  final int isVerified;

  LexicalRelation({
    required this.id,
    required this.sourceWordId,
    required this.targetWordId,
    required this.relationType,
    this.notes,
    required this.status,
    this.isVerified = 0,
  });

  factory LexicalRelation.fromJson(Map<String, dynamic> json) {
    return LexicalRelation(
      id: json['id'] as String,
      sourceWordId: json['source_word_id'] as String,
      targetWordId: json['target_word_id'] as String,
      relationType: json['relation_type'] as String,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_word_id': sourceWordId,
      'target_word_id': targetWordId,
      'relation_type': relationType,
      'notes': notes,
      'status': status,
      'is_verified': isVerified,
    };
  }

  @override
  String toString() =>
      'LexicalRelation(id: $id, type: $relationType, source: $sourceWordId -> target: $targetWordId)';
}
