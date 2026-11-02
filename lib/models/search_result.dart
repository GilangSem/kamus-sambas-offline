import 'word.dart';

/// Model untuk hasil pencarian
class SearchResult {
  final Word word;
  final String? matchedVariant;
  final String? matchedTranslation;
  final List<String> translations;

  SearchResult({
    required this.word,
    this.matchedVariant,
    this.matchedTranslation,
    this.translations = const [],
  });

  @override
  String toString() =>
      'SearchResult(lemma: ${word.lemma}, matched: ${matchedVariant ?? matchedTranslation ?? 'exact'})';
}
