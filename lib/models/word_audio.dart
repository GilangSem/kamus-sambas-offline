/// Model untuk audio kata (word_audios table)
class WordAudio {
  final String id;
  final String wordId;
  final String? exampleId;
  final String? dialectId;
  final String url;
  final String mimeType;
  final int fileSize;
  final int? durationMs;
  final String? speakerName;
  final int isPrimary;
  final String status;
  final int isVerified;
  final int isCorrected;

  WordAudio({
    required this.id,
    required this.wordId,
    this.exampleId,
    this.dialectId,
    required this.url,
    required this.mimeType,
    required this.fileSize,
    this.durationMs,
    this.speakerName,
    this.isPrimary = 0,
    required this.status,
    this.isVerified = 0,
    this.isCorrected = 0,
  });

  factory WordAudio.fromJson(Map<String, dynamic> json) {
    return WordAudio(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      exampleId: json['example_id'] as String?,
      dialectId: json['dialect_id'] as String?,
      url: json['url'] as String,
      mimeType: json['mime_type'] as String,
      fileSize: json['file_size'] as int,
      durationMs: json['duration_ms'] as int?,
      speakerName: json['speaker_name'] as String?,
      isPrimary: json['is_primary'] as int? ?? 0,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
      isCorrected: json['is_corrected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_id': wordId,
      'example_id': exampleId,
      'dialect_id': dialectId,
      'url': url,
      'mime_type': mimeType,
      'file_size': fileSize,
      'duration_ms': durationMs,
      'speaker_name': speakerName,
      'is_primary': isPrimary,
      'status': status,
      'is_verified': isVerified,
      'is_corrected': isCorrected,
    };
  }

  @override
  String toString() => 'WordAudio(id: $id, url: $url)';
}
