import 'package:sqflite/sqflite.dart';
import '../../models/word.dart';
import '../../models/meaning.dart';
import '../../models/meaning_translation.dart';
import '../../models/example.dart';
import '../../models/word_variant.dart';
import '../../models/word_class.dart';
import '../../models/category.dart';
import '../../models/category_with_count.dart';
import '../../models/lexical_relation.dart';
import '../../models/word_detail.dart';
import '../../models/word_image.dart';
import '../../models/word_audio.dart';
import '../../models/pronunciation.dart';
import '../../models/search_result.dart';
import '../../utils/fts_query.dart';
import '../local/kamus_database_helper.dart';

/// Data source untuk kamus SQLite database (queries)
class KamusDatabaseSource {
  final KamusDatabaseHelper _dbHelper;

  KamusDatabaseSource({KamusDatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? KamusDatabaseHelper.instance;

  /// Search kata menggunakan FTS5
  /// [query] - term pencarian
  /// [limit] - jumlah hasil maksimal
  /// [offset] - offset untuk pagination
  Future<List<SearchResult>> searchByLemma({
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    final matchQuery = buildFtsPrefixQuery(query);
    if (matchQuery.isEmpty) return const [];

    try {
      final db = await _dbHelper.database;

      // FTS5 search pada lemma + variants
      const sql = '''
        SELECT DISTINCT
          w.id, w.language_id, w.lemma, w.notes, w.word_type, 
          w.usage_labels, w.status, w.is_verified, w.verified_at, 
          w.is_corrected, w.created_at, w.updated_at
        FROM words_fts wf
        JOIN words w ON w.id = wf.word_id
        WHERE words_fts MATCH ? AND w.status = 'published'
        LIMIT ? OFFSET ?
      ''';

      final results = await db.rawQuery(sql, [matchQuery, limit, offset]);

      final words = results.map((r) => Word.fromJson(r)).toList();

      // Untuk setiap word, ambil translations untuk display
      final searchResults = <SearchResult>[];
      for (final word in words) {
        final translations = await _getTranslationsForWord(db, word.id);
        searchResults.add(SearchResult(word: word, translations: translations));
      }

      return searchResults;
    } catch (e) {
      throw Exception('Search by lemma failed: $e');
    }
  }

  /// Search arti kata (translation) menggunakan FTS5
  /// [query] - term pencarian
  /// [limit] - jumlah hasil maksimal
  /// [offset] - offset untuk pagination
  Future<List<SearchResult>> searchByTranslation({
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    final matchQuery = buildFtsPrefixQuery(query);
    if (matchQuery.isEmpty) return const [];

    try {
      final db = await _dbHelper.database;

      // FTS5 search pada translations
      const sql = '''
        SELECT DISTINCT
          w.id, w.language_id, w.lemma, w.notes, w.word_type, 
          w.usage_labels, w.status, w.is_verified, w.verified_at, 
          w.is_corrected, w.created_at, w.updated_at
        FROM words_fts wf
        JOIN words w ON w.id = wf.word_id
        WHERE words_fts MATCH ? AND w.status = 'published'
        LIMIT ? OFFSET ?
      ''';

      final results = await db.rawQuery(sql, [matchQuery, limit, offset]);

      final words = results.map((r) => Word.fromJson(r)).toList();

      // Untuk setiap word, ambil translations untuk display
      final searchResults = <SearchResult>[];
      for (final word in words) {
        final translations = await _getTranslationsForWord(db, word.id);
        searchResults.add(
          SearchResult(
            word: word,
            matchedTranslation: query,
            translations: translations,
          ),
        );
      }

      return searchResults;
    } catch (e) {
      throw Exception('Search by translation failed: $e');
    }
  }

  /// Get detail kata lengkap
  Future<WordDetail> getWordDetail({required String wordId}) async {
    try {
      final db = await _dbHelper.database;

      // Ambil word
      final wordResults = await db.query(
        KamusDatabaseHelper.tableWords,
        where: 'id = ? AND status = ?',
        whereArgs: [wordId, 'published'],
        limit: 1,
      );

      if (wordResults.isEmpty) {
        throw Exception('Word not found: $wordId');
      }

      final word = Word.fromJson(wordResults.first);

      // Ambil meanings dengan translations dan examples
      final meanings = await _getMeaningsForWord(db, wordId);

      // Ambil variants
      final variants = await _getVariantsForWord(db, wordId);

      // Ambil categories
      final categories = await _getCategoriesForWord(db, wordId);

      // Ambil relations
      final relations = await _getRelationsForWord(db, wordId);

      // Ambil images
      final images = await _getImagesForWord(db, wordId);

      // Ambil audios
      final audios = await _getAudiosForWord(db, wordId);

      // Ambil pronunciations
      final pronunciations = await _getPronunciationsForWord(db, wordId);

      return WordDetail(
        word: word,
        meanings: meanings,
        variants: variants,
        categories: categories,
        relations: relations,
        images: images,
        audios: audios,
        pronunciations: pronunciations,
      );
    } catch (e) {
      throw Exception('Failed to get word detail: $e');
    }
  }

  /// Get word by lemma
  Future<Word?> getWordByLemma({required String lemma}) async {
    try {
      final db = await _dbHelper.database;

      final results = await db.query(
        KamusDatabaseHelper.tableWords,
        where: 'LOWER(lemma) = LOWER(?) AND status = ?',
        whereArgs: [lemma, 'published'],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return Word.fromJson(results.first);
    } catch (e) {
      throw Exception('Failed to get word by lemma: $e');
    }
  }

  /// Get random word
  Future<Word?> getRandomWord() async {
    try {
      final db = await _dbHelper.database;

      const sql =
          '''
        SELECT * FROM ${KamusDatabaseHelper.tableWords}
        WHERE status = 'published'
        ORDER BY RANDOM()
        LIMIT 1
      ''';

      final results = await db.rawQuery(sql);
      if (results.isEmpty) return null;

      return Word.fromJson(results.first);
    } catch (e) {
      throw Exception('Failed to get random word: $e');
    }
  }

  /// Get word count
  Future<int> getWordCount() async {
    try {
      final db = await _dbHelper.database;

      const sql =
          'SELECT COUNT(*) as count FROM ${KamusDatabaseHelper.tableWords} WHERE status = ?';
      final result = await db.rawQuery(sql, ['published']);

      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('Failed to get word count: $e');
    }
  }

  /// Kata harian: deterministik berdasarkan tanggal (tetap sama sepanjang
  /// hari, berubah esok hari) dan sepenuhnya offline.
  Future<Word?> getDailyWord({DateTime? date}) async {
    try {
      final db = await _dbHelper.database;
      final count = await getWordCount();
      if (count == 0) return null;

      final today = date ?? DateTime.now();
      final days = today.difference(DateTime.utc(1970, 1, 1)).inDays.abs();
      final offset = days % count;

      const sql =
          '''
        SELECT * FROM ${KamusDatabaseHelper.tableWords}
        WHERE status = 'published'
        ORDER BY lower(lemma), id
        LIMIT 1 OFFSET ?
      ''';

      final results = await db.rawQuery(sql, [offset]);
      if (results.isEmpty) return null;
      return Word.fromJson(results.first);
    } catch (e) {
      throw Exception('Failed to get daily word: $e');
    }
  }

  /// Daftar kategori beserta jumlah kata published di dalamnya.
  Future<List<CategoryWithCount>> getCategoriesWithCounts() async {
    try {
      final db = await _dbHelper.database;

      const sql =
          '''
        SELECT c.*, COUNT(w.id) AS word_count
        FROM ${KamusDatabaseHelper.tableCategories} c
        LEFT JOIN ${KamusDatabaseHelper.tableWordCategories} wc
          ON wc.category_id = c.id
        LEFT JOIN ${KamusDatabaseHelper.tableWords} w
          ON w.id = wc.word_id AND w.status = 'published'
        GROUP BY c.id
        ORDER BY c.name COLLATE NOCASE ASC
      ''';

      final results = await db.rawQuery(sql);
      return results.map((r) {
        final map = Map<String, dynamic>.from(r);
        final count = (map.remove('word_count') as int?) ?? 0;
        return CategoryWithCount(
          category: Category.fromJson(map),
          wordCount: count,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Kata-kata dalam satu kategori, urut abjad.
  Future<List<SearchResult>> getWordsByCategory({
    required String categoryId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;

      const sql =
          '''
        SELECT w.* FROM ${KamusDatabaseHelper.tableWords} w
        JOIN ${KamusDatabaseHelper.tableWordCategories} wc
          ON wc.word_id = w.id
        WHERE wc.category_id = ? AND w.status = 'published'
        ORDER BY lower(w.lemma), w.id
        LIMIT ? OFFSET ?
      ''';

      final results = await db.rawQuery(sql, [categoryId, limit, offset]);
      final words = results.map((r) => Word.fromJson(r)).toList();

      final searchResults = <SearchResult>[];
      for (final word in words) {
        final translations = await _getTranslationsForWord(db, word.id);
        searchResults.add(SearchResult(word: word, translations: translations));
      }
      return searchResults;
    } catch (e) {
      throw Exception('Failed to get words by category: $e');
    }
  }

  /// Ringkasan kata berdasarkan daftar id (untuk favorit).
  /// Urutan hasil mengikuti urutan [wordIds].
  Future<List<SearchResult>> getWordSummariesByIds(List<String> wordIds) async {
    if (wordIds.isEmpty) return const [];
    try {
      final db = await _dbHelper.database;
      final placeholders = List.filled(wordIds.length, '?').join(',');

      final results = await db.rawQuery('''
        SELECT * FROM ${KamusDatabaseHelper.tableWords}
        WHERE id IN ($placeholders) AND status = 'published'
        ''', wordIds);

      final byId = <String, Word>{};
      for (final row in results) {
        final word = Word.fromJson(row);
        byId[word.id] = word;
      }

      final summaries = <SearchResult>[];
      for (final id in wordIds) {
        final word = byId[id];
        if (word == null) continue;
        final translations = await _getTranslationsForWord(db, word.id);
        summaries.add(SearchResult(word: word, translations: translations));
      }
      return summaries;
    } catch (e) {
      throw Exception('Failed to get word summaries: $e');
    }
  }

  /// Metadata rilis dari tabel release_meta (release_version, schema_version,
  /// released_at, channel).
  Future<Map<String, String>> getReleaseMeta() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(KamusDatabaseHelper.tableReleaseMeta);
      return {
        for (final row in results)
          row['key'].toString(): row['value'].toString(),
      };
    } catch (e) {
      throw Exception('Failed to get release meta: $e');
    }
  }

  /// Helper: Get meanings untuk word dengan translations dan examples
  Future<List<MeaningWithTranslations>> _getMeaningsForWord(
    Database db,
    String wordId,
  ) async {
    final meaningResults = await db.query(
      KamusDatabaseHelper.tableMeanings,
      where: 'word_id = ? AND status = ?',
      whereArgs: [wordId, 'published'],
      orderBy: 'order_index ASC',
    );

    final meanings = <MeaningWithTranslations>[];

    for (final meaningRow in meaningResults) {
      final meaning = Meaning.fromJson(meaningRow);

      // Ambil word class jika ada
      WordClass? wordClass;
      if (meaning.wordClassId != null) {
        final wcResults = await db.query(
          KamusDatabaseHelper.tableWordClasses,
          where: 'id = ?',
          whereArgs: [meaning.wordClassId],
          limit: 1,
        );
        if (wcResults.isNotEmpty) {
          wordClass = WordClass.fromJson(wcResults.first);
        }
      }

      // Ambil translations
      final translationResults = await db.query(
        KamusDatabaseHelper.tableMeaningTranslations,
        where: 'meaning_id = ?',
        whereArgs: [meaning.id],
      );
      final translations = translationResults
          .map((r) => MeaningTranslation.fromJson(r))
          .toList();

      // Ambil examples
      final exampleResults = await db.query(
        KamusDatabaseHelper.tableExamples,
        where: 'meaning_id = ? AND status = ?',
        whereArgs: [meaning.id, 'published'],
      );
      final examples = exampleResults.map((r) => Example.fromJson(r)).toList();

      meanings.add(
        MeaningWithTranslations(
          meaning: meaning,
          wordClass: wordClass,
          translations: translations,
          examples: examples,
        ),
      );
    }

    return meanings;
  }

  /// Helper: Get variants untuk word
  Future<List<WordVariant>> _getVariantsForWord(
    Database db,
    String wordId,
  ) async {
    final results = await db.query(
      KamusDatabaseHelper.tableWordVariants,
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    return results.map((r) => WordVariant.fromJson(r)).toList();
  }

  /// Helper: Get categories untuk word
  Future<List<Category>> _getCategoriesForWord(
    Database db,
    String wordId,
  ) async {
    const sql =
        '''
      SELECT c.* FROM ${KamusDatabaseHelper.tableCategories} c
      JOIN ${KamusDatabaseHelper.tableWordCategories} wc ON c.id = wc.category_id
      WHERE wc.word_id = ?
    ''';

    final results = await db.rawQuery(sql, [wordId]);
    return results.map((r) => Category.fromJson(r)).toList();
  }

  /// Helper: Get lexical relations untuk word
  Future<List<LexicalRelationWithWord>> _getRelationsForWord(
    Database db,
    String wordId,
  ) async {
    const sql =
        '''
      SELECT
        lr.id AS relation_id,
        lr.source_word_id AS relation_source_word_id,
        lr.target_word_id AS relation_target_word_id,
        lr.relation_type,
        lr.notes AS relation_notes,
        lr.status AS relation_status,
        lr.is_verified AS relation_is_verified,
        w.id AS target_id,
        w.language_id AS target_language_id,
        w.lemma AS target_lemma,
        w.notes AS target_notes,
        w.word_type AS target_word_type,
        w.usage_labels AS target_usage_labels,
        w.status AS target_status,
        w.is_verified AS target_is_verified,
        w.verified_at AS target_verified_at,
        w.is_corrected AS target_is_corrected,
        w.created_at AS target_created_at,
        w.updated_at AS target_updated_at
      FROM ${KamusDatabaseHelper.tableLexicalRelations} lr
      JOIN ${KamusDatabaseHelper.tableWords} w ON w.id = lr.target_word_id
      WHERE lr.source_word_id = ? AND lr.status = 'published'
    ''';

    final results = await db.rawQuery(sql, [wordId]);

    return results.map((r) {
      final relationMap = <String, dynamic>{
        'id': r['relation_id'],
        'source_word_id': r['relation_source_word_id'],
        'target_word_id': r['relation_target_word_id'],
        'relation_type': r['relation_type'],
        'notes': r['relation_notes'],
        'status': r['relation_status'],
        'is_verified': r['relation_is_verified'],
      };

      final wordMap = <String, dynamic>{
        'id': r['target_id'],
        'language_id': r['target_language_id'],
        'lemma': r['target_lemma'],
        'notes': r['target_notes'],
        'word_type': r['target_word_type'],
        'usage_labels': r['target_usage_labels'],
        'status': r['target_status'],
        'is_verified': r['target_is_verified'],
        'verified_at': r['target_verified_at'],
        'is_corrected': r['target_is_corrected'],
        'created_at': r['target_created_at'],
        'updated_at': r['target_updated_at'],
      };

      return LexicalRelationWithWord(
        relation: LexicalRelation.fromJson(relationMap),
        targetWord: Word.fromJson(wordMap),
      );
    }).toList();
  }

  /// Helper: Get images untuk word
  Future<List<WordImage>> _getImagesForWord(Database db, String wordId) async {
    final results = await db.query(
      KamusDatabaseHelper.tableWordImages,
      where: 'word_id = ? AND status = ?',
      whereArgs: [wordId, 'published'],
      orderBy: 'is_primary DESC',
    );

    return results.map((r) => WordImage.fromJson(r)).toList();
  }

  /// Helper: Get audios untuk word
  Future<List<WordAudio>> _getAudiosForWord(Database db, String wordId) async {
    final results = await db.query(
      KamusDatabaseHelper.tableWordAudios,
      where: 'word_id = ? AND status = ?',
      whereArgs: [wordId, 'published'],
      orderBy: 'is_primary DESC',
    );

    return results.map((r) => WordAudio.fromJson(r)).toList();
  }

  /// Helper: Get pronunciations untuk word
  Future<List<Pronunciation>> _getPronunciationsForWord(
    Database db,
    String wordId,
  ) async {
    final results = await db.query(
      KamusDatabaseHelper.tablePronunciations,
      where: 'word_id = ? AND status = ?',
      whereArgs: [wordId, 'published'],
    );

    return results.map((r) => Pronunciation.fromJson(r)).toList();
  }

  /// Helper: Get translations untuk word (simple list)
  Future<List<String>> _getTranslationsForWord(
    Database db,
    String wordId,
  ) async {
    const sql =
        '''
      SELECT DISTINCT mt.translation_text
      FROM ${KamusDatabaseHelper.tableMeaningTranslations} mt
      JOIN ${KamusDatabaseHelper.tableMeanings} m ON m.id = mt.meaning_id
      WHERE m.word_id = ? AND m.status = 'published'
      LIMIT 5
    ''';

    final results = await db.rawQuery(sql, [wordId]);
    return results.map((r) => r['translation_text'].toString()).toList();
  }
}
