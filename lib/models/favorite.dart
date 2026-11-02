/// Model untuk data favorit (local database)
class Favorite {
  final String wordId;
  final int createdAt;

  Favorite({required this.wordId, required this.createdAt});

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      wordId: json['word_id'] as String,
      createdAt: json['created_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'word_id': wordId, 'created_at': createdAt};
  }

  @override
  String toString() => 'Favorite(wordId: $wordId, createdAt: $createdAt)';
}
