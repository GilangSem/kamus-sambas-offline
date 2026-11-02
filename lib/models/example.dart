/// Model untuk contoh kalimat (examples table)
class Example {
  final String id;
  final String meaningId;
  final String sourceLanguageId;
  final String sourceSentence;
  final String? targetLanguageId;
  final String? targetSentence;
  final String? sourceType;
  final String? sourceReference;
  final String? notes;
  final String status;
  final int isVerified;
  final int isCorrected;

  Example({
    required this.id,
    required this.meaningId,
    required this.sourceLanguageId,
    required this.sourceSentence,
    this.targetLanguageId,
    this.targetSentence,
    this.sourceType,
    this.sourceReference,
    this.notes,
    required this.status,
    this.isVerified = 0,
    this.isCorrected = 0,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      id: json['id'] as String,
      meaningId: json['meaning_id'] as String,
      sourceLanguageId: json['source_language_id'] as String,
      sourceSentence: json['source_sentence'] as String,
      targetLanguageId: json['target_language_id'] as String?,
      targetSentence: json['target_sentence'] as String?,
      sourceType: json['source_type'] as String?,
      sourceReference: json['source_reference'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
      isCorrected: json['is_corrected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meaning_id': meaningId,
      'source_language_id': sourceLanguageId,
      'source_sentence': sourceSentence,
      'target_language_id': targetLanguageId,
      'target_sentence': targetSentence,
      'source_type': sourceType,
      'source_reference': sourceReference,
      'notes': notes,
      'status': status,
      'is_verified': isVerified,
      'is_corrected': isCorrected,
    };
  }

  @override
  String toString() => 'Example(id: $id, source: $sourceSentence)';
}
