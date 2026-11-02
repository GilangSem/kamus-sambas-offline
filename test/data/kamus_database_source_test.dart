import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/datasources/kamus_database_source.dart';
import 'package:kamus_app/data/local/kamus_database_helper.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late String kamusPath;
  late KamusDatabaseHelper helper;
  late KamusDatabaseSource source;

  setUpAll(() {
    initTestDatabaseFactory();
  });

  setUp(() async {
    tempDir = createTempDir('kamus_source');
    kamusPath = await createSeededKamusDatabase(directoryPath: tempDir.path);
    helper = KamusDatabaseHelper(
      customPath: kamusPath,
      databaseFactoryOverride: databaseFactoryFfi,
    );
    source = KamusDatabaseSource(dbHelper: helper);
  });

  tearDown(() async {
    await helper.close();
    tempDir.deleteSync(recursive: true);
  });

  group('Pencarian offline', () {
    test('mencari lemma secara persis', () async {
      final results = await source.searchByLemma(query: 'alpha');
      expect(results, hasLength(1));
      expect(results.first.word.lemma, 'alpha');
      expect(results.first.translations, contains('glosalpha'));
    });

    test('mencari berdasarkan sebagian karakter (prefix)', () async {
      final results = await source.searchByLemma(query: 'alp');
      expect(results.any((r) => r.word.lemma == 'alpha'), isTrue);
    });

    test('mencari melalui varian kata', () async {
      final results = await source.searchByLemma(query: 'alfabet');
      expect(results.any((r) => r.word.lemma == 'alpha'), isTrue);
    });

    test('mencari arti Bahasa Indonesia', () async {
      final results = await source.searchByTranslation(query: 'glosalpha');
      expect(results, hasLength(1));
      expect(results.first.word.lemma, 'alpha');
    });

    test('tidak mengembalikan kata yang belum published', () async {
      final results = await source.searchByLemma(query: 'gamma');
      expect(results, isEmpty);
    });

    test('mengembalikan kosong untuk kata tidak ditemukan', () async {
      final results = await source.searchByLemma(query: 'tidakada');
      expect(results, isEmpty);
    });

    test('mendukung pagination limit', () async {
      final all = await source.searchByTranslation(query: 'glos');
      expect(all, hasLength(2));

      final limited = await source.searchByTranslation(query: 'glos', limit: 1);
      expect(limited, hasLength(1));
    });

    test('karakter kutip pada query tetap aman', () async {
      final results = await source.searchByLemma(query: '"alp"');
      expect(results.any((r) => r.word.lemma == 'alpha'), isTrue);
    });
  });

  group('Detail kata', () {
    test('mengambil detail lengkap sesuai data yang ada', () async {
      final detail = await source.getWordDetail(wordId: 'w-alpha');

      expect(detail.word.lemma, 'alpha');
      expect(detail.meanings, hasLength(1));
      expect(detail.meanings.first.wordClass?.name, 'Nomina');
      expect(detail.meanings.first.translations, hasLength(1));
      expect(detail.meanings.first.examples, hasLength(1));
      expect(
        detail.meanings.first.examples.first.targetSentence,
        'kalimat terjemahan alpha',
      );
      expect(detail.variants.single.form, 'alfabet');
      expect(detail.categories.single.name, 'Kategori Uji');
      expect(detail.relations, hasLength(1));
      expect(detail.relations.first.relation.relationType, 'synonym');
      expect(detail.relations.first.targetWord.id, 'w-beta');
      expect(detail.relations.first.targetWord.lemma, 'beta');
      expect(detail.images, hasLength(1));
      expect(detail.audios, hasLength(1));
    });

    test('detail kata draft tidak dapat diakses', () async {
      expect(
        () => source.getWordDetail(wordId: 'w-draft'),
        throwsA(isA<Exception>()),
      );
    });

    test('melempar error untuk id tidak dikenal', () async {
      expect(
        () => source.getWordDetail(wordId: 'tidak-ada'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Statistik & kata acak', () {
    test('menghitung hanya kata published', () async {
      expect(await source.getWordCount(), 2);
    });

    test('kata acak berasal dari database lokal', () async {
      final word = await source.getRandomWord();
      expect(word, isNotNull);
      expect(['alpha', 'beta'], contains(word!.lemma));
    });

    test('kata harian deterministik untuk tanggal yang sama', () async {
      final date = DateTime.utc(2026, 2, 1, 12);
      final first = await source.getDailyWord(date: date);
      final second = await source.getDailyWord(date: date);

      expect(first, isNotNull);
      expect(first!.id, second!.id);
      expect(['alpha', 'beta'], contains(first.lemma));
    });
  });

  group('Katalog & metadata', () {
    test('kategori dihitung hanya dari kata published', () async {
      final categories = await source.getCategoriesWithCounts();
      expect(categories, hasLength(1));
      expect(categories.first.category.name, 'Kategori Uji');
      expect(categories.first.wordCount, 1);
    });

    test('kata per kategori hanya kata published', () async {
      final results = await source.getWordsByCategory(categoryId: 'cat-uji');
      expect(results, hasLength(1));
      expect(results.first.word.lemma, 'alpha');
    });

    test('ringkasan kata mengikuti urutan id yang diminta', () async {
      final results = await source.getWordSummariesByIds([
        'w-beta',
        'w-draft',
        'w-alpha',
      ]);
      expect(results.map((r) => r.word.id).toList(), ['w-beta', 'w-alpha']);
    });

    test('metadata rilis terbaca', () async {
      final meta = await source.getReleaseMeta();
      expect(meta['release_version'], '1');
      expect(meta['schema_version'], '1');
      expect(meta['released_at'], isNotNull);
    });
  });

  group('Validasi database kamus', () {
    test('database valid lolos validasi', () async {
      final result = await helper.validateSchema();
      expect(result.isValid, isTrue);
      expect(result.schemaVersion, 1);
      expect(result.errorMessage, isNull);
    });

    test('database rusak gagal validasi', () async {
      final brokenPath = await createBrokenKamusDatabase(
        directoryPath: tempDir.path,
      );
      final brokenHelper = KamusDatabaseHelper(
        customPath: brokenPath,
        databaseFactoryOverride: databaseFactoryFfi,
      );
      final result = await brokenHelper.validateSchema();
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
      await brokenHelper.close();
    });
  });
}
