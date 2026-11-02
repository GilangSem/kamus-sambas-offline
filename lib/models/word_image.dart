import 'dart:convert';

/// Model untuk gambar kata (word_images table)
class WordImage {
  final String id;
  final String wordId;
  final String url;
  final String? altText;
  final int isPrimary;
  final List<String> contentWarnings;
  final Map<String, dynamic>? attribution;
  final String status;
  final int isVerified;
  final int isCorrected;

  WordImage({
    required this.id,
    required this.wordId,
    required this.url,
    this.altText,
    this.isPrimary = 0,
    this.contentWarnings = const [],
    this.attribution,
    required this.status,
    this.isVerified = 0,
    this.isCorrected = 0,
  });

  factory WordImage.fromJson(Map<String, dynamic> json) {
    List<String> parsedContentWarnings = [];
    final contentWarningsRaw = json['content_warnings'];
    if (contentWarningsRaw is String) {
      try {
        final decoded = jsonDecode(contentWarningsRaw);
        if (decoded is List) {
          parsedContentWarnings = decoded.cast<String>();
        }
      } catch (e) {
        parsedContentWarnings = [];
      }
    } else if (contentWarningsRaw is List) {
      parsedContentWarnings = contentWarningsRaw.cast<String>();
    }

    Map<String, dynamic>? parsedAttribution;
    final attributionRaw = json['attribution'];
    if (attributionRaw is String && attributionRaw.isNotEmpty) {
      try {
        parsedAttribution = jsonDecode(attributionRaw) as Map<String, dynamic>;
      } catch (e) {
        parsedAttribution = null;
      }
    } else if (attributionRaw is Map) {
      parsedAttribution = attributionRaw.cast<String, dynamic>();
    }

    return WordImage(
      id: json['id'] as String,
      wordId: json['word_id'] as String,
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as int? ?? 0,
      contentWarnings: parsedContentWarnings,
      attribution: parsedAttribution,
      status: json['status'] as String,
      isVerified: json['is_verified'] as int? ?? 0,
      isCorrected: json['is_corrected'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_id': wordId,
      'url': url,
      'alt_text': altText,
      'is_primary': isPrimary,
      'content_warnings': jsonEncode(contentWarnings),
      'attribution': attribution != null ? jsonEncode(attribution) : null,
      'status': status,
      'is_verified': isVerified,
      'is_corrected': isCorrected,
    };
  }

  @override
  String toString() => 'WordImage(id: $id, url: $url, isPrimary: $isPrimary)';
}
