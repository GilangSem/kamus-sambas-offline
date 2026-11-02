/// Model untuk pelafalan (pronunciations table).
class Pronunciation {
  final String id;
  final String wordId;
  final String? dialectId;
  final String notation;
  final String value;
  final String? audioUrl;
  final String? speakerName;
  final String? notes;
  final String status;
  final int isVerified;
  final int isCorrected;

  Pronunciation({
    required this.id,
    required this.wordId,
    this.dialectId,
    this.notation = 'ipa',
    required this.value,
    this.audioUrl,
    this.speakerName,
    this.notes,
    required this.status,
    this.isVerified = 0,
    this.isCorrected = 0,
  });

  factory Pronunciation.fromJson(Map<String, dynamic> json) {
    return Pronunciation(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      dialectId: json['dialect_id'] as String?,
      notation: json['notation'] as String? ?? 'ipa',
      value: json['value'] as String,
      audioUrl: json['audio_url'] as String?,
      speakerName: json['speaker_name'] as String?,
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
      'dialect_id': dialectId,
      'notation': notation,
      'value': value,
      'audio_url': audioUrl,
      'speaker_name': speakerName,
      'notes': notes,
      'status': status,
      'is_verified': isVerified,
      'is_corrected': isCorrected,
    };
  }

  @override
  String toString() => 'Pronunciation(value: $value)';
}
