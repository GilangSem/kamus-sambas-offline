import 'word.dart';
import 'meaning.dart';
import 'meaning_translation.dart';
import 'example.dart';
import 'word_variant.dart';
import 'word_class.dart';
import 'category.dart';
import 'lexical_relation.dart';
import 'word_image.dart';
import 'word_audio.dart';
import 'pronunciation.dart';

/// Model composite untuk detail kata lengkap
class WordDetail {
  final Word word;
  final List<MeaningWithTranslations> meanings;
  final List<WordVariant> variants;
  final List<Category> categories;
  final List<LexicalRelationWithWord> relations;
  final List<WordImage> images;
  final List<WordAudio> audios;
  final List<Pronunciation> pronunciations;

  WordDetail({
    required this.word,
    this.meanings = const [],
    this.variants = const [],
    this.categories = const [],
    this.relations = const [],
    this.images = const [],
    this.audios = const [],
    this.pronunciations = const [],
  });

  @override
  String toString() =>
      'WordDetail(word: ${word.lemma}, meanings: ${meanings.length}, variants: ${variants.length})';
}

/// Model composite untuk makna dengan terjemahan dan contoh
class MeaningWithTranslations {
  final Meaning meaning;
  final WordClass? wordClass;
  final List<MeaningTranslation> translations;
  final List<Example> examples;

  MeaningWithTranslations({
    required this.meaning,
    this.wordClass,
    this.translations = const [],
    this.examples = const [],
  });

  @override
  String toString() =>
      'MeaningWithTranslations(definition: ${meaning.definition}, translations: ${translations.length}, examples: ${examples.length})';
}

/// Model composite untuk relasi leksikal dengan target word
class LexicalRelationWithWord {
  final LexicalRelation relation;
  final Word targetWord;

  LexicalRelationWithWord({required this.relation, required this.targetWord});

  @override
  String toString() =>
      'LexicalRelationWithWord(type: ${relation.relationType}, target: ${targetWord.lemma})';
}
