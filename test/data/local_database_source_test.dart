import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/datasources/kamus_database_source.dart';
import 'package:kamus_app/data/datasources/local_database_source.dart';
import 'package:kamus_app/data/local/kamus_database_helper.dart';
import 'package:kamus_app/data/local/local_database_helper.dart';
import 'package:kamus_app/data/repositories/favorites_repository.dart';
import 'package:kamus_app/data/repositories/search_history_repository.dart';
import 'package:kamus_app/data/repositories/app_metadata_repository.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late LocalDatabaseHelper localHelper;
  late LocalDatabaseSource localSource;
  late FavoritesRepository favorites;
  late SearchHistoryRepository history;
  late AppMetadataRepository appMeta;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    tempDir = createTempDir('kamus_local');
    localHelper = LocalDatabaseHelper(
      customPath: p.join(tempDir.path, 'local_data.db'),
      databaseFactoryOverride: databaseFactoryFfi,
    );
    localSource = LocalDatabaseSource(dbHelper: localHelper);
    favorites = FavoritesRepository(dataSource: localSource);
    history = SearchHistoryRepository(dataSource: localSource);
    appMeta = AppMetadataRepository(dataSource: localSource);
  });

  tearDown(() async {
    await localHelper.close();
    tempDir.deleteSync(recursive: true);
  });

  group('Favorit', () {
    test('menambah dan mendeteksi favorit', () async {
      await favorites.addFavorite('w-alpha');
      expect(await favorites.isFavorite('w-alpha'), isTrue);
      expect(await favorites.isFavorite('w-beta'), isFalse);
    });

    test('mencegah duplikasi favorit', () async {
      await favorites.addFavorite('w-alpha');
      await favorites.addFavorite('w-alpha');
      expect(await favorites.getFavoriteCount(), 1);
    });

    test('menghapus favorit', () async {
      await favorites.addFavorite('w-alpha');
      await favorites.removeFavorite('w-alpha');
      expect(await favorites.isFavorite('w-alpha'), isFalse);
      expect(await favorites.getFavoriteCount(), 0);
    });

    test('mengembalikan daftar id favorit', () async {
      await favorites.addFavorite('w-alpha');
      await favorites.addFavorite('w-beta');
      final ids = await favorites.getAllFavoriteWordIds();
      expect(ids, containsAll(['w-alpha', 'w-beta']));
    });
  });

  group('Riwayat pencarian', () {
    test('menyimpan dan membaca riwayat terbaru lebih dulu', () async {
      await history.addSearchHistory(query: 'alpha', resultCount: 1);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await history.addSearchHistory(query: 'beta', resultCount: 1);

      final items = await history.getSearchHistory();
      expect(items.map((h) => h.query).toList(), ['beta', 'alpha']);
    });

    test('menghapus satu riwayat', () async {
      await history.addSearchHistory(query: 'alpha');
      final items = await history.getSearchHistory();
      await history.deleteSearchHistory(items.first.id!);
      expect(await history.getSearchHistory(), isEmpty);
    });

    test('menghapus seluruh riwayat', () async {
      await history.addSearchHistory(query: 'alpha');
      await history.addSearchHistory(query: 'beta');
      await history.clearAllSearchHistory();
      expect(await history.getSearchHistory(), isEmpty);
    });

    test('query yang sama tidak membuat entri duplikat', () async {
      await history.addSearchHistory(query: 'alpha', resultCount: 1);
      await history.addSearchHistory(query: 'alpha', resultCount: 2);

      final items = await history.getSearchHistory();
      final alphaItems = items.where((item) => item.query == 'alpha').toList();
      expect(alphaItems, hasLength(1));
      expect(alphaItems.first.resultCount, 2);
      expect(items, hasLength(1));
    });
  });

  group('Metadata aplikasi', () {
    test('menyimpan dan membaca versi database', () async {
      await appMeta.setDbVersion('3');
      expect(await appMeta.getDbVersion(), '3');
    });

    test('menyimpan waktu pemeriksaan update', () async {
      await appMeta.setLastUpdateCheck(1700000000);
      expect(await appMeta.getLastUpdateCheck(), 1700000000);
    });
  });

  group('Isolasi data pengguna dari pembaruan kamus', () {
    test('favorit tetap ada setelah database kamus diganti', () async {
      final kamusPath = await createSeededKamusDatabase(
        directoryPath: tempDir.path,
      );
      final kamusHelper = KamusDatabaseHelper(
        customPath: kamusPath,
        databaseFactoryOverride: databaseFactoryFfi,
      );
      final kamusSource = KamusDatabaseSource(dbHelper: kamusHelper);

      await favorites.addFavorite('w-alpha');
      expect(await kamusSource.searchByLemma(query: 'alpha'), hasLength(1));

      final newKamusPath = await createSeededKamusDatabase(
        directoryPath: tempDir.path,
        fileName: 'kamus_new.db',
      );

      await kamusHelper.atomicSwapDatabase(
        newDatabasePath: newKamusPath,
        backupPath: p.join(tempDir.path, 'kamus_backup.db'),
      );

      final afterSwap = await kamusSource.searchByLemma(query: 'alpha');
      expect(afterSwap, hasLength(1));
      expect(await favorites.isFavorite('w-alpha'), isTrue);
      expect(await favorites.getFavoriteCount(), 1);

      await kamusHelper.close();
    });

    test('database lama tetap aman jika database baru rusak', () async {
      final kamusPath = await createSeededKamusDatabase(
        directoryPath: tempDir.path,
      );
      final kamusHelper = KamusDatabaseHelper(
        customPath: kamusPath,
        databaseFactoryOverride: databaseFactoryFfi,
      );
      final kamusSource = KamusDatabaseSource(dbHelper: kamusHelper);

      final brokenPath = await createBrokenKamusDatabase(
        directoryPath: tempDir.path,
      );

      await expectLater(
        kamusHelper.atomicSwapDatabase(
          newDatabasePath: brokenPath,
          backupPath: p.join(tempDir.path, 'kamus_backup.db'),
        ),
        throwsA(isA<Exception>()),
      );

      final results = await kamusSource.searchByLemma(query: 'alpha');
      expect(results, hasLength(1));

      await kamusHelper.close();
    });
  });
}
