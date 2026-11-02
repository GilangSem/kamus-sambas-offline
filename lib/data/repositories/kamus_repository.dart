import '../datasources/kamus_database_source.dart';
import '../../models/category_with_count.dart';
import '../../models/word_detail.dart';
import '../../models/search_result.dart';
import '../../models/word.dart';

/// Repository untuk operasi database kamus.
class KamusRepository {
  final KamusDatabaseSource _dataSource;

  KamusRepository({KamusDatabaseSource? dataSource})
    : _dataSource = dataSource ?? KamusDatabaseSource();

  Future<List<SearchResult>> searchByLemma({
    required String query,
    int limit = 50,
    int offset = 0,
  }) => _dataSource.searchByLemma(query: query, limit: limit, offset: offset);

  Future<List<SearchResult>> searchByTranslation({
    required String query,
    int limit = 50,
    int offset = 0,
  }) => _dataSource.searchByTranslation(
    query: query,
    limit: limit,
    offset: offset,
  );

  Future<WordDetail> getWordDetail({required String wordId}) =>
      _dataSource.getWordDetail(wordId: wordId);

  Future<Word?> getWordByLemma({required String lemma}) =>
      _dataSource.getWordByLemma(lemma: lemma);

  Future<Word?> getRandomWord() => _dataSource.getRandomWord();

  Future<Word?> getDailyWord({DateTime? date}) =>
      _dataSource.getDailyWord(date: date);

  Future<int> getWordCount() => _dataSource.getWordCount();

  Future<List<CategoryWithCount>> getCategoriesWithCounts() =>
      _dataSource.getCategoriesWithCounts();

  Future<List<SearchResult>> getWordsByCategory({
    required String categoryId,
    int limit = 100,
    int offset = 0,
  }) => _dataSource.getWordsByCategory(
    categoryId: categoryId,
    limit: limit,
    offset: offset,
  );

  Future<List<SearchResult>> getWordSummariesByIds(List<String> wordIds) =>
      _dataSource.getWordSummariesByIds(wordIds);

  Future<Map<String, String>> getReleaseMeta() => _dataSource.getReleaseMeta();
}
