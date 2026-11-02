import 'dart:convert';

/// Model untuk kata (words table)
class Word {
  final String id;
  final String languageId;
  final String lemma;
  final String? notes;
  final String wordType;
  final List<String> usageLabels;
  final String status;
  final int isVerified;
  final int? verifiedAt;
  final int isCorrected;
  final int createdAt;
  final int? updatedAt;

  Word({
    required this.id,
    required this.languageId,
    required this.lemma,
    this.notes,
    this.wordType = 'word',
    this.usageLabels = const [],
    required this.status,
    this.isVerified = 0,
    this.verifiedAt,
    this.isCorrected = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    List<String> parsedUsageLabels = [];
    final usageLabelsRaw = json['usage_labels'];
    if (usageLabelsRaw is String) {
      try {
        final decoded = jsonDecode(usageLabelsRaw);
        if (decoded is List) {
          parsedUsageLabels = decoded.cast<String>();
        }
      } catch (e) {
        parsedUsageLabels = [];
      }
    } else if (usageLabelsRaw is List) {
      parsedUsageLabels = usageLabelsRaw.cast<String>();
    }

    return Word(
      id: json['id'] as String,
      languageId: json['language_id'] as String,
      lemma: json['lemma'] as String,
      notes: json['notes'] as String?,
      wordType: json['word_type'] as String? ?? 'word',
      usageLabels: parsedUsageLabels,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
      verifiedAt: json['verified_at'] as int?,
      isCorrected: json['is_corrected'] as int? ?? 0,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_id': languageId,
      'lemma': lemma,
      'notes': notes,
      'word_type': wordType,
      'usage_labels': jsonEncode(usageLabels),
      'status': status,
      'is_verified': isVerified,
      'verified_at': verifiedAt,
      'is_corrected': isCorrected,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() => 'Word(id: $id, lemma: $lemma, status: $status)';
}
